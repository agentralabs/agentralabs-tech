use std::env;
use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use clap::{Parser, Subcommand, ValueEnum};
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use crossterm::ExecutableCommand;
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::widgets::{Block, Borders, Cell, Clear, Paragraph, Row, Table, Wrap};
use ratatui::Terminal;
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

#[derive(Parser)]
#[command(name = "agentra")]
#[command(about = "Unified UX for agentic-codebase, agentic-memory, and agentic-vision")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Clone, Copy)]
enum Commands {
    /// Launch interactive terminal dashboard.
    Ui,
    /// Print non-interactive status of sister tools.
    Status {
        /// Print compact notification-style status block.
        #[arg(long)]
        session: bool,
    },
    /// Toggle sister usage in persistent config.
    Toggle {
        #[arg(value_enum)]
        sister: Sister,
        #[arg(value_enum)]
        state: ToggleState,
    },
    /// Set whether Agentra can auto-take control from detected artifacts.
    Control {
        #[arg(value_enum)]
        state: ToggleState,
    },
    /// Diagnose MCP wiring and optionally auto-repair it.
    Doctor {
        /// Apply automatic fixes for detected issues.
        #[arg(long)]
        fix: bool,
    },
}

#[derive(Clone, Copy, Debug, Serialize, Deserialize, ValueEnum, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
enum Sister {
    Codebase,
    Memory,
    Vision,
}

impl Sister {
    fn as_label(self) -> &'static str {
        match self {
            Sister::Codebase => "codebase",
            Sister::Memory => "memory",
            Sister::Vision => "vision",
        }
    }
}

#[derive(Clone, Copy, Debug, ValueEnum)]
enum ToggleState {
    On,
    Off,
}

impl ToggleState {
    fn is_enabled(self) -> bool {
        matches!(self, ToggleState::On)
    }

    fn as_label(self) -> &'static str {
        if self.is_enabled() {
            "on"
        } else {
            "off"
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct AgentraConfig {
    use_codebase: bool,
    use_memory: bool,
    use_vision: bool,
    agentra_full_control: bool,
}

impl Default for AgentraConfig {
    fn default() -> Self {
        Self {
            use_codebase: true,
            use_memory: true,
            use_vision: true,
            agentra_full_control: true,
        }
    }
}

impl AgentraConfig {
    fn is_enabled(&self, sister: Sister) -> bool {
        match sister {
            Sister::Codebase => self.use_codebase,
            Sister::Memory => self.use_memory,
            Sister::Vision => self.use_vision,
        }
    }

    fn set_enabled(&mut self, sister: Sister, enabled: bool) {
        match sister {
            Sister::Codebase => self.use_codebase = enabled,
            Sister::Memory => self.use_memory = enabled,
            Sister::Vision => self.use_vision = enabled,
        }
    }

    fn summary(&self) -> String {
        format!(
            "codebase={} memory={} vision={} full_control={}",
            bool_label(self.use_codebase),
            bool_label(self.use_memory),
            bool_label(self.use_vision),
            bool_label(self.agentra_full_control)
        )
    }
}

#[derive(Clone, Copy)]
struct ToolSpec {
    label: &'static str,
    command: &'static str,
    local_rel: &'static str,
    start_hint: &'static str,
    sister: Option<Sister>,
}

#[derive(Clone, Copy)]
enum ToolStatus {
    Ok,
    Missing,
    Disabled,
}

impl ToolStatus {
    fn as_label(self) -> &'static str {
        match self {
            ToolStatus::Ok => "OK",
            ToolStatus::Missing => "MISSING",
            ToolStatus::Disabled => "DISABLED",
        }
    }
}

#[derive(Clone)]
struct ToolState {
    label: &'static str,
    status: ToolStatus,
    source: String,
    start_hint: &'static str,
}

struct App {
    tools: Vec<ToolState>,
    config: AgentraConfig,
    last_refresh: String,
    last_action_log: String,
    message: String,
    show_help_popup: bool,
}

const AUTO_REFRESH_INTERVAL: Duration = Duration::from_secs(5);

const TOOL_SPECS: [ToolSpec; 6] = [
    ToolSpec {
        label: "Codebase CLI",
        command: "acb",
        local_rel: "agentic-codebase/target/release/acb",
        start_hint: "acb --help",
        sister: Some(Sister::Codebase),
    },
    ToolSpec {
        label: "Codebase MCP",
        command: "acb-mcp",
        local_rel: "agentic-codebase/target/release/acb-mcp",
        start_hint: "acb-mcp --help",
        sister: Some(Sister::Codebase),
    },
    ToolSpec {
        label: "Memory CLI",
        command: "amem",
        local_rel: "agentic-memory/target/release/amem",
        start_hint: "amem --help",
        sister: Some(Sister::Memory),
    },
    ToolSpec {
        label: "Memory MCP",
        command: "agentic-memory-mcp",
        local_rel: "agentic-memory/target/release/agentic-memory-mcp",
        start_hint: "agentic-memory-mcp --help",
        sister: Some(Sister::Memory),
    },
    ToolSpec {
        label: "Vision MCP",
        command: "agentic-vision-mcp",
        local_rel: "agentic-vision/target/release/agentic-vision-mcp",
        start_hint: "agentic-vision-mcp --help",
        sister: Some(Sister::Vision),
    },
    ToolSpec {
        label: "Ollama",
        command: "ollama",
        local_rel: "",
        start_hint: "ollama serve",
        sister: None,
    },
];

#[derive(Clone, Copy)]
struct SisterMcpSpec {
    key: &'static str,
    binary: &'static str,
    local_rel: &'static str,
    args: &'static [&'static str],
}

const MCP_SISTERS: [SisterMcpSpec; 3] = [
    SisterMcpSpec {
        key: "agentic-codebase",
        binary: "acb-mcp",
        local_rel: "agentic-codebase/target/release/acb-mcp",
        args: &[],
    },
    SisterMcpSpec {
        key: "agentic-memory",
        binary: "agentic-memory-mcp",
        local_rel: "agentic-memory/target/release/agentic-memory-mcp",
        args: &["serve"],
    },
    SisterMcpSpec {
        key: "agentic-vision",
        binary: "agentic-vision-mcp",
        local_rel: "agentic-vision/target/release/agentic-vision-mcp",
        args: &["serve"],
    },
];

#[derive(Clone, Copy)]
enum McpTargetKind {
    Json,
    CodexToml,
}

#[derive(Clone)]
struct McpTarget {
    name: String,
    path: PathBuf,
    kind: McpTargetKind,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum DoctorStatus {
    Pass,
    Fixed,
    Fail,
    Skip,
}

impl DoctorStatus {
    fn as_label(self) -> &'static str {
        match self {
            DoctorStatus::Pass => "PASS",
            DoctorStatus::Fixed => "FIXED",
            DoctorStatus::Fail => "FAIL",
            DoctorStatus::Skip => "SKIP",
        }
    }
}

struct DoctorRow {
    target: String,
    status: DoctorStatus,
    detail: String,
}

#[derive(Default, Clone, Copy)]
struct ArtifactPresence {
    codebase: usize,
    memory: usize,
    vision: usize,
}

fn workspace_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map(Path::to_path_buf)
        .unwrap_or_else(|| PathBuf::from("."))
}

fn config_path() -> PathBuf {
    workspace_root().join("agentra-config.json")
}

fn load_config() -> AgentraConfig {
    let path = config_path();
    let content = match fs::read_to_string(path) {
        Ok(v) => v,
        Err(_) => return AgentraConfig::default(),
    };

    serde_json::from_str(&content).unwrap_or_else(|_| AgentraConfig::default())
}

fn save_config(config: &AgentraConfig) -> io::Result<()> {
    let path = config_path();
    let json = serde_json::to_string_pretty(config)
        .map_err(|e| io::Error::other(format!("failed to serialize config: {e}")))?;
    fs::write(path, format!("{json}\n"))
}

fn find_on_path(cmd: &str) -> Option<PathBuf> {
    let path_var = env::var_os("PATH")?;
    for dir in env::split_paths(&path_var) {
        let candidate = dir.join(cmd);
        if candidate.is_file() {
            return Some(candidate);
        }
    }
    None
}

fn detect_tools(config: &AgentraConfig) -> Vec<ToolState> {
    let root = workspace_root();

    TOOL_SPECS
        .iter()
        .map(|spec| {
            if let Some(sister) = spec.sister {
                if !config.is_enabled(sister) {
                    return ToolState {
                        label: spec.label,
                        status: ToolStatus::Disabled,
                        source: format!(
                            "disabled in {} (agentra toggle {} on)",
                            config_path().display(),
                            sister.as_label()
                        ),
                        start_hint: spec.start_hint,
                    };
                }
            }

            if let Some(path_hit) = find_on_path(spec.command) {
                return ToolState {
                    label: spec.label,
                    status: ToolStatus::Ok,
                    source: format!("PATH: {}", path_hit.display()),
                    start_hint: spec.start_hint,
                };
            }

            if !spec.local_rel.is_empty() {
                let local = root.join(spec.local_rel);
                if local.is_file() {
                    return ToolState {
                        label: spec.label,
                        status: ToolStatus::Ok,
                        source: format!("local build: {}", local.display()),
                        start_hint: spec.start_hint,
                    };
                }
            }

            ToolState {
                label: spec.label,
                status: ToolStatus::Missing,
                source: "not found".to_string(),
                start_hint: spec.start_hint,
            }
        })
        .collect()
}

fn now_string() -> String {
    format!("{:?}", SystemTime::now())
}

fn hhmm_string() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        % 86_400;
    let h = secs / 3_600;
    let m = (secs % 3_600) / 60;
    format!("{h:02}:{m:02}")
}

fn counts(tools: &[ToolState]) -> (usize, usize, usize) {
    let ok = tools
        .iter()
        .filter(|t| matches!(t.status, ToolStatus::Ok))
        .count();
    let disabled = tools
        .iter()
        .filter(|t| matches!(t.status, ToolStatus::Disabled))
        .count();
    (ok, disabled, tools.len())
}

fn bool_label(value: bool) -> &'static str {
    if value {
        "on"
    } else {
        "off"
    }
}

fn home_dir() -> Option<PathBuf> {
    env::var_os("HOME").map(PathBuf::from)
}

fn resolve_sister_binary(spec: SisterMcpSpec) -> Option<PathBuf> {
    if let Some(path_hit) = find_on_path(spec.binary) {
        return Some(path_hit);
    }
    let local = workspace_root().join(spec.local_rel);
    if local.is_file() {
        return Some(local);
    }
    None
}

fn command_resolves(command: &str) -> bool {
    if command.is_empty() {
        return false;
    }
    if command.contains('/') {
        return Path::new(command).is_file();
    }
    find_on_path(command).is_some()
}

fn backup_file(path: &Path) -> io::Result<PathBuf> {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let base = path
        .file_name()
        .map(|v| v.to_string_lossy().to_string())
        .unwrap_or_else(|| "config".to_string());
    let backup = path.with_file_name(format!("{base}.agentra.bak.{ts}"));
    fs::copy(path, &backup)?;
    Ok(backup)
}

fn target_names() -> [&'static str; 4] {
    [
        "mcp.json",
        "mcp_config.json",
        "claude_desktop_config.json",
        "cline_mcp_settings.json",
    ]
}

fn scan_mcp_files_recursive(
    root: &Path,
    depth: usize,
    names: &[&str],
    out: &mut Vec<PathBuf>,
) -> io::Result<()> {
    if depth == 0 || !root.is_dir() {
        return Ok(());
    }
    for entry in fs::read_dir(root)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            scan_mcp_files_recursive(&path, depth - 1, names, out)?;
            continue;
        }
        if !path.is_file() {
            continue;
        }
        if let Some(name) = path.file_name().and_then(|v| v.to_str()) {
            if names.contains(&name) {
                out.push(path);
            }
        }
    }
    Ok(())
}

fn push_json_target(
    targets: &mut Vec<McpTarget>,
    seen_paths: &mut BTreeSet<PathBuf>,
    name: &str,
    path: PathBuf,
) {
    if seen_paths.insert(path.clone()) {
        targets.push(McpTarget {
            name: name.to_string(),
            path,
            kind: McpTargetKind::Json,
        });
    }
}

fn add_json_target_if_detected(
    targets: &mut Vec<McpTarget>,
    seen_paths: &mut BTreeSet<PathBuf>,
    name: &str,
    path: PathBuf,
    detect_path: PathBuf,
) {
    if path.exists() || detect_path.exists() {
        push_json_target(targets, seen_paths, name, path);
    }
}

fn collect_mcp_targets() -> Vec<McpTarget> {
    let mut targets = Vec::new();
    let mut seen_paths = BTreeSet::new();
    let Some(home) = home_dir() else {
        return targets;
    };

    let is_darwin = cfg!(target_os = "macos");
    let xdg_config = env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home.join(".config"));

    let claude_desktop = if is_darwin {
        home.join("Library/Application Support/Claude/claude_desktop_config.json")
    } else {
        xdg_config.join("Claude/claude_desktop_config.json")
    };
    let claude_desktop_detect = claude_desktop
        .parent()
        .map(Path::to_path_buf)
        .unwrap_or_else(|| home.clone());
    add_json_target_if_detected(
        &mut targets,
        &mut seen_paths,
        "Claude Desktop",
        claude_desktop,
        claude_desktop_detect,
    );

    add_json_target_if_detected(
        &mut targets,
        &mut seen_paths,
        "Claude Code",
        home.join(".claude/mcp.json"),
        home.join(".claude"),
    );
    add_json_target_if_detected(
        &mut targets,
        &mut seen_paths,
        "Cursor",
        home.join(".cursor/mcp.json"),
        home.join(".cursor"),
    );
    add_json_target_if_detected(
        &mut targets,
        &mut seen_paths,
        "Windsurf",
        home.join(".windsurf/mcp.json"),
        home.join(".windsurf"),
    );
    add_json_target_if_detected(
        &mut targets,
        &mut seen_paths,
        "Windsurf (Codeium)",
        home.join(".codeium/windsurf/mcp_config.json"),
        home.join(".codeium/windsurf"),
    );

    if is_darwin {
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VS Code",
            home.join("Library/Application Support/Code/User/mcp.json"),
            home.join("Library/Application Support/Code/User"),
        );
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VS Code + Cline",
            home.join(
                "Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json",
            ),
            home.join("Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev"),
        );
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VSCodium",
            home.join("Library/Application Support/VSCodium/User/mcp.json"),
            home.join("Library/Application Support/VSCodium/User"),
        );
    } else {
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VS Code",
            xdg_config.join("Code/User/mcp.json"),
            xdg_config.join("Code/User"),
        );
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VS Code + Cline",
            xdg_config.join(
                "Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json",
            ),
            xdg_config.join("Code/User/globalStorage/saoudrizwan.claude-dev"),
        );
        add_json_target_if_detected(
            &mut targets,
            &mut seen_paths,
            "VSCodium",
            xdg_config.join("VSCodium/User/mcp.json"),
            xdg_config.join("VSCodium/User"),
        );
    }

    let mut discovered = Vec::new();
    let roots = [
        home.join(".config"),
        home.join("Library/Application Support"),
        home.join(".cursor"),
        home.join(".windsurf"),
        home.join(".codeium"),
        home.join(".claude"),
    ];
    for root in roots {
        let _ = scan_mcp_files_recursive(&root, 6, &target_names(), &mut discovered);
    }
    discovered.sort();
    discovered.dedup();
    for path in discovered {
        if path.exists() {
            push_json_target(
                &mut targets,
                &mut seen_paths,
                "Generic MCP JSON",
                path,
            );
        }
    }

    let codex_home = env::var_os("CODEX_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home.join(".codex"));
    let codex_config = codex_home.join("config.toml");
    if codex_config.exists() || codex_home.exists() || find_on_path("codex").is_some() {
        targets.push(McpTarget {
            name: "Codex".to_string(),
            path: codex_config,
            kind: McpTargetKind::CodexToml,
        });
    }

    targets
}

fn json_args_match(entry: &Value, expected: &[&str]) -> bool {
    let Some(args) = entry.get("args").and_then(Value::as_array) else {
        return expected.is_empty();
    };
    let actual: Vec<&str> = args.iter().filter_map(Value::as_str).collect();
    actual == expected
}

fn inspect_json_target(
    target: &McpTarget,
    installed: &BTreeMap<&'static str, PathBuf>,
    fix: bool,
) -> DoctorRow {
    if installed.is_empty() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Skip,
            detail: "No installed sister MCP binaries detected".to_string(),
        };
    }

    let mut issues = Vec::new();
    let mut fixed_items = Vec::new();
    let mut changed = false;
    let mut config: Value;

    if target.path.exists() {
        match fs::read_to_string(&target.path)
            .ok()
            .and_then(|text| serde_json::from_str::<Value>(&text).ok())
        {
            Some(v) => config = v,
            None => {
                issues.push("Malformed JSON".to_string());
                if !fix {
                    return DoctorRow {
                        target: format!("{} ({})", target.name, target.path.display()),
                        status: DoctorStatus::Fail,
                        detail: issues.join("; "),
                    };
                }
                if let Err(err) = backup_file(&target.path) {
                    return DoctorRow {
                        target: format!("{} ({})", target.name, target.path.display()),
                        status: DoctorStatus::Fail,
                        detail: format!("Failed to back up malformed config: {err}"),
                    };
                }
                config = json!({});
                changed = true;
            }
        }
    } else {
        issues.push("Config file missing".to_string());
        if !fix {
            return DoctorRow {
                target: format!("{} ({})", target.name, target.path.display()),
                status: DoctorStatus::Fail,
                detail: issues.join("; "),
            };
        }
        config = json!({});
        changed = true;
    }

    if !config.is_object() {
        issues.push("Root JSON is not an object".to_string());
        if !fix {
            return DoctorRow {
                target: format!("{} ({})", target.name, target.path.display()),
                status: DoctorStatus::Fail,
                detail: issues.join("; "),
            };
        }
        config = json!({});
        changed = true;
    }

    if !config
        .get("mcpServers")
        .map(Value::is_object)
        .unwrap_or(false)
    {
        issues.push("Missing or invalid mcpServers object".to_string());
        if fix {
            config["mcpServers"] = json!({});
            changed = true;
        } else {
            return DoctorRow {
                target: format!("{} ({})", target.name, target.path.display()),
                status: DoctorStatus::Fail,
                detail: issues.join("; "),
            };
        }
    }

    let Some(servers) = config.get_mut("mcpServers").and_then(Value::as_object_mut) else {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Fail,
            detail: "mcpServers could not be parsed as object".to_string(),
        };
    };

    for spec in MCP_SISTERS {
        let Some(binary) = installed.get(spec.key) else {
            continue;
        };
        let expected_cmd = binary.display().to_string();

        let mut should_rewrite = false;
        match servers.get(spec.key) {
            Some(entry) if entry.is_object() => {
                let cmd = entry
                    .get("command")
                    .and_then(Value::as_str)
                    .unwrap_or_default()
                    .to_string();
                if cmd != expected_cmd {
                    issues.push(format!("{} command mismatch", spec.key));
                    should_rewrite = true;
                }
                if !command_resolves(&cmd) {
                    issues.push(format!("{} command is stale/missing", spec.key));
                    should_rewrite = true;
                }
                if !json_args_match(entry, spec.args) {
                    issues.push(format!("{} args mismatch", spec.key));
                    should_rewrite = true;
                }
            }
            _ => {
                issues.push(format!("Missing MCP entry '{}'", spec.key));
                should_rewrite = true;
            }
        }

        if fix && should_rewrite {
            servers.insert(
                spec.key.to_string(),
                json!({
                    "command": expected_cmd,
                    "args": spec.args,
                }),
            );
            changed = true;
            fixed_items.push(spec.key.to_string());
        }
    }

    if fix && changed {
        if target.path.exists() {
            let _ = backup_file(&target.path);
        }
        if let Some(parent) = target.path.parent() {
            if let Err(err) = fs::create_dir_all(parent) {
                return DoctorRow {
                    target: format!("{} ({})", target.name, target.path.display()),
                    status: DoctorStatus::Fail,
                    detail: format!("Failed to create parent directory: {err}"),
                };
            }
        }
        if let Err(err) = fs::write(
            &target.path,
            serde_json::to_string_pretty(&config)
                .unwrap_or_else(|_| "{}".to_string())
                + "\n",
        ) {
            return DoctorRow {
                target: format!("{} ({})", target.name, target.path.display()),
                status: DoctorStatus::Fail,
                detail: format!("Failed to write config: {err}"),
            };
        }
    }

    if issues.is_empty() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Pass,
            detail: "MCP entries are healthy".to_string(),
        };
    }

    if fix {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Fixed,
            detail: format!("Repaired: {}", fixed_items.join(", ")),
        };
    }

    DoctorRow {
        target: format!("{} ({})", target.name, target.path.display()),
        status: DoctorStatus::Fail,
        detail: issues.join("; "),
    }
}

fn run_command(cmd: &str, args: &[String]) -> io::Result<(bool, String)> {
    let output = Command::new(cmd).args(args).output()?;
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    Ok((output.status.success(), format!("{stdout}{stderr}")))
}

fn inspect_codex_target(
    target: &McpTarget,
    installed: &BTreeMap<&'static str, PathBuf>,
    fix: bool,
) -> DoctorRow {
    if installed.is_empty() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Skip,
            detail: "No installed sister MCP binaries detected".to_string(),
        };
    }

    if find_on_path("codex").is_none() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Fail,
            detail: "Codex CLI not found; cannot verify or repair Codex MCP config".to_string(),
        };
    }

    let mut issues = Vec::new();
    let mut fixed_items = Vec::new();

    for spec in MCP_SISTERS {
        let Some(binary) = installed.get(spec.key) else {
            continue;
        };

        let get_args = vec![
            "mcp".to_string(),
            "get".to_string(),
            spec.key.to_string(),
            "--json".to_string(),
        ];
        let (ok, output) = match run_command("codex", &get_args) {
            Ok(v) => v,
            Err(err) => {
                issues.push(format!("{} lookup failed: {}", spec.key, err));
                continue;
            }
        };

        let expected_cmd = binary.display().to_string();
        let expected_args: Vec<String> = spec.args.iter().map(|s| s.to_string()).collect();
        let mut needs_repair = false;

        if !ok {
            issues.push(format!("Missing Codex MCP entry '{}'", spec.key));
            needs_repair = true;
        } else {
            let parsed = serde_json::from_str::<Value>(&output);
            match parsed {
                Ok(json_value) => {
                    let command = json_value
                        .pointer("/transport/command")
                        .and_then(Value::as_str)
                        .unwrap_or_default()
                        .to_string();
                    let args = json_value
                        .pointer("/transport/args")
                        .and_then(Value::as_array)
                        .map(|arr| {
                            arr.iter()
                                .filter_map(Value::as_str)
                                .map(|s| s.to_string())
                                .collect::<Vec<String>>()
                        })
                        .unwrap_or_default();

                    if command != expected_cmd {
                        issues.push(format!("{} command mismatch in Codex", spec.key));
                        needs_repair = true;
                    }
                    if !command_resolves(&command) {
                        issues.push(format!("{} command is stale/missing in Codex", spec.key));
                        needs_repair = true;
                    }
                    if args != expected_args {
                        issues.push(format!("{} args mismatch in Codex", spec.key));
                        needs_repair = true;
                    }
                }
                Err(_) => {
                    issues.push(format!("{} returned non-JSON data from Codex", spec.key));
                    needs_repair = true;
                }
            }
        }

        if fix && needs_repair {
            let remove_args = vec![
                "mcp".to_string(),
                "remove".to_string(),
                spec.key.to_string(),
            ];
            let _ = run_command("codex", &remove_args);

            let mut add_args = vec![
                "mcp".to_string(),
                "add".to_string(),
                spec.key.to_string(),
                "--".to_string(),
                expected_cmd.clone(),
            ];
            add_args.extend(expected_args.clone());

            match run_command("codex", &add_args) {
                Ok((true, _)) => fixed_items.push(spec.key.to_string()),
                Ok((false, out)) => {
                    issues.push(format!("{} add failed in Codex: {}", spec.key, out.trim()));
                }
                Err(err) => {
                    issues.push(format!("{} add command failed in Codex: {}", spec.key, err));
                }
            }
        }
    }

    if issues.is_empty() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Pass,
            detail: "MCP entries are healthy".to_string(),
        };
    }

    if fix && !fixed_items.is_empty() {
        return DoctorRow {
            target: format!("{} ({})", target.name, target.path.display()),
            status: DoctorStatus::Fixed,
            detail: format!("Repaired: {}", fixed_items.join(", ")),
        };
    }

    DoctorRow {
        target: format!("{} ({})", target.name, target.path.display()),
        status: DoctorStatus::Fail,
        detail: issues.join("; "),
    }
}

fn scan_artifacts_recursive(root: &Path, depth: usize, presence: &mut ArtifactPresence) {
    if depth == 0 || !root.is_dir() {
        return;
    }
    let Ok(entries) = fs::read_dir(root) else {
        return;
    };
    for entry in entries {
        let Ok(entry) = entry else {
            continue;
        };
        let path = entry.path();
        if path.is_dir() {
            scan_artifacts_recursive(&path, depth - 1, presence);
            continue;
        }
        if !path.is_file() {
            continue;
        }
        let Some(ext) = path.extension().and_then(|v| v.to_str()) else {
            continue;
        };
        match ext.to_ascii_lowercase().as_str() {
            "acb" => presence.codebase += 1,
            "amem" => presence.memory += 1,
            "avis" => presence.vision += 1,
            _ => {}
        }
    }
}

fn detect_artifact_presence() -> ArtifactPresence {
    let mut presence = ArtifactPresence::default();
    let root = workspace_root();
    scan_artifacts_recursive(&root, 6, &mut presence);
    if let Some(home) = home_dir() {
        if presence.memory == 0 {
            let default_brain = home.join(".brain.amem");
            if default_brain.is_file() {
                presence.memory += 1;
            }
        }
    }
    presence
}

fn auto_resync_from_artifacts() -> io::Result<Vec<String>> {
    let mut config = load_config();
    if !config.agentra_full_control {
        return Ok(Vec::new());
    }

    let presence = detect_artifact_presence();
    let mut changed = Vec::new();

    if presence.codebase > 0 && !config.use_codebase {
        config.use_codebase = true;
        changed.push(format!(
            "Enabled codebase from detected .acb artifacts ({})",
            presence.codebase
        ));
    }
    if presence.memory > 0 && !config.use_memory {
        config.use_memory = true;
        changed.push(format!(
            "Enabled memory from detected .amem artifacts ({})",
            presence.memory
        ));
    }
    if presence.vision > 0 && !config.use_vision {
        config.use_vision = true;
        changed.push(format!(
            "Enabled vision from detected .avis artifacts ({})",
            presence.vision
        ));
    }

    if !changed.is_empty() {
        save_config(&config)?;
    }
    Ok(changed)
}

fn run_doctor(fix: bool) -> io::Result<()> {
    println!("Agentra Doctor");
    println!("=============");
    println!(
        "Mode: {}",
        if fix {
            "diagnose + auto-fix"
        } else {
            "diagnose only"
        }
    );
    println!();

    let installed: BTreeMap<&'static str, PathBuf> = MCP_SISTERS
        .iter()
        .filter_map(|spec| resolve_sister_binary(*spec).map(|path| (spec.key, path)))
        .collect();

    let mut rows = Vec::new();

    for spec in MCP_SISTERS {
        let row = if let Some(path) = installed.get(spec.key) {
            DoctorRow {
                target: format!("Binary {}", spec.binary),
                status: DoctorStatus::Pass,
                detail: format!("Detected at {}", path.display()),
            }
        } else {
            DoctorRow {
                target: format!("Binary {}", spec.binary),
                status: DoctorStatus::Fail,
                detail: format!(
                    "Missing. Install this sister to expose '{}'.",
                    spec.key
                ),
            }
        };
        rows.push(row);
    }

    let targets = collect_mcp_targets();
    if targets.is_empty() {
        rows.push(DoctorRow {
            target: "MCP target discovery".to_string(),
            status: DoctorStatus::Fail,
            detail: "No MCP client configs detected on this machine".to_string(),
        });
    } else {
        for target in &targets {
            let row = match target.kind {
                McpTargetKind::Json => inspect_json_target(target, &installed, fix),
                McpTargetKind::CodexToml => inspect_codex_target(target, &installed, fix),
            };
            rows.push(row);
        }
    }

    let mut pass_count = 0usize;
    let mut fixed_count = 0usize;
    let mut fail_count = 0usize;
    let mut skip_count = 0usize;

    for row in &rows {
        match row.status {
            DoctorStatus::Pass => pass_count += 1,
            DoctorStatus::Fixed => fixed_count += 1,
            DoctorStatus::Fail => fail_count += 1,
            DoctorStatus::Skip => skip_count += 1,
        }
        println!(
            "[{}] {:<42} {}",
            row.status.as_label(),
            row.target,
            row.detail
        );
    }

    println!();
    println!(
        "Summary: pass={} fixed={} fail={} skip={}",
        pass_count, fixed_count, fail_count, skip_count
    );

    if fix && (fixed_count > 0 || pass_count > 0) {
        println!("Next: restart MCP clients so updated configs are reloaded.");
    }

    if fail_count > 0 {
        return Err(io::Error::other(
            "doctor found unresolved issues; rerun with --fix",
        ));
    }
    Ok(())
}

impl App {
    fn new() -> Self {
        let config = load_config();
        let tools = detect_tools(&config);
        let (ok, disabled, total) = counts(&tools);

        Self {
            tools,
            config,
            last_refresh: now_string(),
            last_action_log: format!(
                "Initialized at {} - OK: {ok}/{total}, Disabled: {disabled}.",
                hhmm_string()
            ),
            message: "Press r to refresh, h for start hints, q to quit.".to_string(),
            show_help_popup: false,
        }
    }

    fn refresh(&mut self, reason: &str) {
        self.config = load_config();
        self.tools = detect_tools(&self.config);
        self.last_refresh = now_string();
        let (ok, disabled, total) = counts(&self.tools);
        self.last_action_log = format!(
            "{reason} at {} - OK: {ok}/{total}, Disabled: {disabled}.",
            hhmm_string()
        );
        self.message = "Press h for hints popup, r to refresh, q to quit.".to_string();
    }

    fn open_hints(&mut self) {
        self.show_help_popup = true;
        let hints: Vec<&str> = self
            .tools
            .iter()
            .filter(|t| matches!(t.status, ToolStatus::Ok))
            .map(|t| t.start_hint)
            .collect();

        if hints.is_empty() {
            self.message =
                "No active tools detected. Enable sisters with agentra toggle <sister> on."
                    .to_string();
        } else {
            self.message = format!("Hints: {}", hints.join(" | "));
        }
    }

    fn close_hints(&mut self) {
        self.show_help_popup = false;
        self.message = "Press h for hints popup, r to refresh, q to quit.".to_string();
    }
}

fn draw_ui(frame: &mut ratatui::Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(8),
            Constraint::Length(3),
            Constraint::Length(3),
        ])
        .split(frame.area());

    let header =
        Paragraph::new("Sisters remain independently installable; this UI is only for ease.")
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("Agentra Dashboard"),
            )
            .wrap(Wrap { trim: true });
    frame.render_widget(header, chunks[0]);

    let rows = app.tools.iter().map(|t| {
        let style = match t.status {
            ToolStatus::Ok => Style::default().fg(Color::Green),
            ToolStatus::Missing => Style::default().fg(Color::Red),
            ToolStatus::Disabled => Style::default().fg(Color::Yellow),
        };

        Row::new(vec![
            Cell::from(t.label),
            Cell::from(t.status.as_label()).style(style.add_modifier(Modifier::BOLD)),
            Cell::from(t.source.clone()),
        ])
    });

    let table = Table::new(
        rows,
        [
            Constraint::Length(14),
            Constraint::Length(9),
            Constraint::Min(40),
        ],
    )
    .header(
        Row::new(vec!["Tool", "Status", "Detected From"]).style(
            Style::default()
                .fg(Color::Cyan)
                .add_modifier(Modifier::BOLD),
        ),
    )
    .block(
        Block::default()
            .borders(Borders::ALL)
            .title("Sister Tooling"),
    );

    frame.render_widget(table, chunks[1]);

    let log_widget = Paragraph::new(format!(
        "{} (snapshot: {})",
        app.last_action_log, app.last_refresh
    ))
    .block(
        Block::default()
            .borders(Borders::ALL)
            .title("Last Action Log"),
    )
    .wrap(Wrap { trim: true });
    frame.render_widget(log_widget, chunks[2]);

    let footer = Paragraph::new(app.message.clone())
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Controls: r refresh | h hints | q quit"),
        )
        .wrap(Wrap { trim: true });
    frame.render_widget(footer, chunks[3]);

    if app.show_help_popup {
        let popup_area = centered_rect(72, 52, frame.area());
        frame.render_widget(Clear, popup_area);

        let hints: Vec<&str> = app
            .tools
            .iter()
            .filter(|t| matches!(t.status, ToolStatus::Ok))
            .map(|t| t.start_hint)
            .collect();
        let hint_line = if hints.is_empty() {
            "No active tools. Enable sisters with: agentra toggle <sister> on".to_string()
        } else {
            hints.join(" | ")
        };
        let popup_text = format!(
            "Agentra Help\n\n\
             - Auto refresh: every {}s\n\
             - Press r: manual refresh\n\
             - Press h or Esc: close this popup\n\
             - Press q: quit dashboard\n\n\
             Start hints:\n{}\n\n\
             Full config:\n{}",
            AUTO_REFRESH_INTERVAL.as_secs(),
            hint_line,
            app.config.summary()
        );

        let popup = Paragraph::new(popup_text)
            .block(Block::default().borders(Borders::ALL).title("Hints"))
            .wrap(Wrap { trim: true });
        frame.render_widget(popup, popup_area);
    }
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}

fn run_ui() -> io::Result<()> {
    let _ = auto_resync_from_artifacts();

    enable_raw_mode()?;
    let mut stdout = io::stdout();
    stdout.execute(EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    let mut app = App::new();
    let mut last_auto_refresh = Instant::now();

    let result = loop {
        if last_auto_refresh.elapsed() >= AUTO_REFRESH_INTERVAL {
            app.refresh("Auto-refreshed");
            last_auto_refresh = Instant::now();
        }

        terminal.draw(|f| draw_ui(f, &app))?;

        if event::poll(Duration::from_millis(250))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    match key.code {
                        KeyCode::Esc => {
                            if app.show_help_popup {
                                app.close_hints();
                            } else {
                                break Ok(());
                            }
                        }
                        KeyCode::Char('q') => break Ok(()),
                        KeyCode::Char('r') => {
                            app.refresh("Manually refreshed");
                            last_auto_refresh = Instant::now();
                        }
                        KeyCode::Char('h') => {
                            if app.show_help_popup {
                                app.close_hints();
                            } else {
                                app.open_hints();
                            }
                        }
                        _ => {}
                    }
                }
            }
        }
    };

    disable_raw_mode()?;
    terminal.backend_mut().execute(LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    result
}

fn run_status() {
    let resync_notes = auto_resync_from_artifacts().unwrap_or_default();
    let config = load_config();
    let tools = detect_tools(&config);

    println!("Agentra sister status");
    println!("=====================");
    println!("Config file: {}", config_path().display());
    println!("Config: {}", config.summary());
    println!();

    if !resync_notes.is_empty() {
        println!("Runtime resync:");
        for note in &resync_notes {
            println!("  - {note}");
        }
        println!();
    }

    for t in tools {
        println!("{:<16} {:<8} {}", t.label, t.status.as_label(), t.source);
        if matches!(t.status, ToolStatus::Missing) {
            println!("  hint: {}", t.start_hint);
        }
    }

    println!();
    println!(
        "Note: Sisters can be installed and used independently; agentra only orchestrates UX."
    );
}

fn run_status_session() {
    let _ = auto_resync_from_artifacts();
    let config = load_config();
    let tools = detect_tools(&config);

    let enabled_count = [config.use_codebase, config.use_memory, config.use_vision]
        .iter()
        .filter(|v| **v)
        .count();

    let codebase_active = tools
        .iter()
        .any(|t| t.label.starts_with("Codebase ") && matches!(t.status, ToolStatus::Ok));
    let memory_active = tools
        .iter()
        .any(|t| t.label.starts_with("Memory ") && matches!(t.status, ToolStatus::Ok));
    let vision_active = tools
        .iter()
        .any(|t| t.label.starts_with("Vision ") && matches!(t.status, ToolStatus::Ok));

    let active_count = [codebase_active, memory_active, vision_active]
        .iter()
        .filter(|v| **v)
        .count();

    let (state_icon, state_label) = if active_count == 0 {
        ("🔴", "Disconnected")
    } else {
        ("🟢", "Connected")
    };

    let codebase_icon = if config.use_codebase { "✅" } else { "❌" };
    let memory_icon = if config.use_memory { "✅" } else { "❌" };
    let vision_icon = if config.use_vision { "✅" } else { "❌" };

    let codebase_state = if config.use_codebase { "On" } else { "Off" };
    let memory_state = if config.use_memory { "On" } else { "Off" };
    let vision_state = if config.use_vision { "On" } else { "Off" };

    let full_control = if config.agentra_full_control && active_count > 0 {
        "Yes"
    } else {
        "No"
    };

    println!("{state_icon} {state_label} | Idle");
    println!("Agentra: ✅ Active | Use for status/control");
    println!(
        "Sisters: Codebase {codebase_icon} ({codebase_state}) | Memory {memory_icon} ({memory_state}) | Vision {vision_icon} ({vision_state})"
    );
    println!(
        "Full Control: {full_control} ({active_count}/3 active, {enabled_count}/3 enabled) | Toggle with `agentra ui` or command"
    );
    println!("Config file: {}", config_path().display());
}

fn run_toggle(sister: Sister, state: ToggleState) -> io::Result<()> {
    let mut config = load_config();
    config.set_enabled(sister, state.is_enabled());
    save_config(&config)?;

    println!("Updated '{}' => {}", sister.as_label(), state.as_label());
    println!("Config file: {}", config_path().display());
    println!("Config: {}", config.summary());
    Ok(())
}

fn run_control(state: ToggleState) -> io::Result<()> {
    let mut config = load_config();
    config.agentra_full_control = state.is_enabled();
    save_config(&config)?;

    println!("Updated full control => {}", state.as_label());
    println!("Config file: {}", config_path().display());
    println!("Config: {}", config.summary());
    Ok(())
}

fn main() -> io::Result<()> {
    let cli = Cli::parse();

    match cli.command.unwrap_or(Commands::Ui) {
        Commands::Ui => run_ui(),
        Commands::Status { session } => {
            if session {
                run_status_session();
            } else {
                run_status();
            }
            Ok(())
        }
        Commands::Toggle { sister, state } => run_toggle(sister, state),
        Commands::Control { state } => run_control(state),
        Commands::Doctor { fix } => run_doctor(fix),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::process;

    fn temp_dir(prefix: &str) -> PathBuf {
        let ts = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let dir = env::temp_dir().join(format!("agentra-{prefix}-{}-{ts}", process::id()));
        fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn fixture_path(name: &str) -> PathBuf {
        Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests")
            .join("fixtures")
            .join("mcp")
            .join(name)
    }

    fn fake_installed_map(root: &Path) -> BTreeMap<&'static str, PathBuf> {
        let bin = root.join("bin");
        fs::create_dir_all(&bin).expect("create bin dir");
        let mut map = BTreeMap::new();
        for spec in MCP_SISTERS {
            let path = bin.join(spec.binary);
            fs::write(&path, "#!/bin/sh\necho ok\n").expect("write fake binary");
            map.insert(spec.key, path);
        }
        map
    }

    fn assert_entry_matches(entry: &Value, expected_cmd: &Path, expected_args: &[&str]) {
        let cmd = entry
            .get("command")
            .and_then(Value::as_str)
            .expect("command string");
        assert_eq!(cmd, expected_cmd.display().to_string());

        let args: Vec<String> = entry
            .get("args")
            .and_then(Value::as_array)
            .expect("args array")
            .iter()
            .filter_map(Value::as_str)
            .map(ToString::to_string)
            .collect();
        let expected: Vec<String> = expected_args.iter().map(|s| s.to_string()).collect();
        assert_eq!(args, expected);
    }

    #[test]
    fn golden_fixtures_repair_non_destructive() {
        let fixtures = [
            ("claude_desktop.json", "some-other-server", "theme"),
            ("cursor.json", "github", "telemetry"),
            ("vscode_cline.json", "filesystem", "window"),
        ];

        for (fixture, unrelated_server, top_level_key) in fixtures {
            let root = temp_dir("fixture");
            let cfg_path = root.join("mcp.json");
            fs::copy(fixture_path(fixture), &cfg_path).expect("copy fixture");

            let installed = fake_installed_map(&root);
            let target = McpTarget {
                name: "fixture".to_string(),
                path: cfg_path.clone(),
                kind: McpTargetKind::Json,
            };

            let before = inspect_json_target(&target, &installed, false);
            assert_eq!(before.status, DoctorStatus::Fail);

            let repaired = inspect_json_target(&target, &installed, true);
            assert_eq!(repaired.status, DoctorStatus::Fixed);

            let after_text = fs::read_to_string(&cfg_path).expect("read fixed config");
            let after_json: Value = serde_json::from_str(&after_text).expect("valid json");
            let servers = after_json
                .get("mcpServers")
                .and_then(Value::as_object)
                .expect("mcpServers object");

            assert!(servers.contains_key(unrelated_server));
            assert!(after_json.get(top_level_key).is_some());

            for spec in MCP_SISTERS {
                let entry = servers.get(spec.key).expect("sister entry present");
                let expected_cmd = installed.get(spec.key).expect("installed path");
                assert_entry_matches(entry, expected_cmd, spec.args);
            }
        }
    }

    #[test]
    fn healthy_config_reports_pass() {
        let root = temp_dir("healthy");
        let cfg_path = root.join("mcp.json");
        let installed = fake_installed_map(&root);

        let mut servers = serde_json::Map::new();
        servers.insert(
            "some-other".to_string(),
            json!({ "command": "other", "args": ["serve"] }),
        );
        for spec in MCP_SISTERS {
            servers.insert(
                spec.key.to_string(),
                json!({
                    "command": installed
                        .get(spec.key)
                        .expect("installed")
                        .display()
                        .to_string(),
                    "args": spec.args,
                }),
            );
        }
        let config = json!({
            "mcpServers": servers,
            "meta": {"kept": true}
        });
        fs::write(&cfg_path, serde_json::to_string_pretty(&config).unwrap() + "\n")
            .expect("write config");

        let target = McpTarget {
            name: "healthy".to_string(),
            path: cfg_path.clone(),
            kind: McpTargetKind::Json,
        };

        let row = inspect_json_target(&target, &installed, false);
        assert_eq!(row.status, DoctorStatus::Pass);

        let row_fix = inspect_json_target(&target, &installed, true);
        assert_eq!(row_fix.status, DoctorStatus::Pass);
    }

    #[test]
    fn malformed_json_can_be_repaired() {
        let root = temp_dir("malformed");
        let cfg_path = root.join("mcp.json");
        fs::write(&cfg_path, "{ this is not valid json").expect("write malformed");

        let installed = fake_installed_map(&root);
        let target = McpTarget {
            name: "malformed".to_string(),
            path: cfg_path.clone(),
            kind: McpTargetKind::Json,
        };

        let row = inspect_json_target(&target, &installed, false);
        assert_eq!(row.status, DoctorStatus::Fail);

        let row_fix = inspect_json_target(&target, &installed, true);
        assert_eq!(row_fix.status, DoctorStatus::Fixed);

        let fixed_text = fs::read_to_string(&cfg_path).expect("read fixed");
        let fixed_json: Value = serde_json::from_str(&fixed_text).expect("valid repaired json");
        let servers = fixed_json
            .get("mcpServers")
            .and_then(Value::as_object)
            .expect("mcpServers object");

        for spec in MCP_SISTERS {
            assert!(servers.contains_key(spec.key));
        }
    }
}
