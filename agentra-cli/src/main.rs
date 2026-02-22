use std::collections::{BTreeMap, BTreeSet};
use std::env;
use std::fs;
use std::io;
use std::io::Read;
use std::path::{Component, Path, PathBuf};
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
use sha2::{Digest, Sha256};

#[derive(Parser)]
#[command(name = "agentra")]
#[command(about = "Unified UX for agentic-codebase, agentic-memory, and agentic-vision")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand, Clone)]
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
    /// Backup and restore Agentra operational state.
    Backup {
        #[command(subcommand)]
        command: BackupCommands,
    },
    /// Server runtime authentication and artifact sync checks.
    Server {
        #[command(subcommand)]
        command: ServerCommands,
    },
}

#[derive(Subcommand, Clone)]
enum BackupCommands {
    /// Create a timestamped backup snapshot.
    Run {
        /// Workspace root to scan for runtime artifacts.
        #[arg(long)]
        workspace: Option<PathBuf>,
        /// Backup root directory (defaults to ~/.agentra-backups).
        #[arg(long)]
        output: Option<PathBuf>,
    },
    /// List known backup snapshots.
    List {
        /// Backup root directory (defaults to ~/.agentra-backups).
        #[arg(long)]
        output: Option<PathBuf>,
        /// Max snapshots to display.
        #[arg(long, default_value_t = 20)]
        limit: usize,
    },
    /// Verify checksums in a backup snapshot.
    Verify {
        /// Snapshot directory name under backup root, or absolute path.
        snapshot: Option<String>,
        /// Backup root directory (defaults to ~/.agentra-backups).
        #[arg(long)]
        output: Option<PathBuf>,
    },
    /// Restore files from a backup snapshot.
    Restore {
        /// Snapshot directory name under backup root, or absolute path.
        snapshot: String,
        /// Backup root directory (defaults to ~/.agentra-backups).
        #[arg(long)]
        output: Option<PathBuf>,
        /// Restore memory files only.
        #[arg(long)]
        memory: bool,
        /// Restore MCP config files only.
        #[arg(long)]
        mcp: bool,
        /// Restore artifact files only.
        #[arg(long)]
        artifacts: bool,
        /// Overwrite files without creating timestamped .agentra.bak backups.
        #[arg(long)]
        force: bool,
    },
    /// Delete older snapshots and keep only the newest N.
    Prune {
        /// Backup root directory (defaults to ~/.agentra-backups).
        #[arg(long)]
        output: Option<PathBuf>,
        /// Number of newest snapshots to keep.
        #[arg(long, default_value_t = 20)]
        keep: usize,
        /// Show what would be deleted without deleting it.
        #[arg(long)]
        dry_run: bool,
    },
}

#[derive(Subcommand, Clone)]
enum ServerCommands {
    /// Validate server runtime auth, artifact dirs, and MCP binaries.
    Preflight {
        /// Fail the command if any required check fails.
        #[arg(long)]
        strict: bool,
        /// Optional artifact directory override (repeatable).
        #[arg(long = "artifact-dir")]
        artifact_dirs: Vec<PathBuf>,
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
    launcher: &'static str,
    local_rel: &'static str,
    args: &'static [&'static str],
}

const MCP_SISTERS: [SisterMcpSpec; 3] = [
    SisterMcpSpec {
        key: "agentic-codebase",
        binary: "acb-mcp",
        launcher: "acb-mcp-agentra",
        local_rel: "agentic-codebase/target/release/acb-mcp",
        args: &[],
    },
    SisterMcpSpec {
        key: "agentic-memory",
        binary: "agentic-memory-mcp",
        launcher: "agentic-memory-mcp-agentra",
        local_rel: "agentic-memory/target/release/agentic-memory-mcp",
        args: &["serve"],
    },
    SisterMcpSpec {
        key: "agentic-vision",
        binary: "agentic-vision-mcp",
        launcher: "agentic-vision-mcp-agentra",
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

#[derive(Debug, Serialize, Deserialize)]
struct BackupManifest {
    version: u32,
    created_unix: u64,
    workspace_root: String,
    entries: Vec<BackupEntry>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct BackupEntry {
    category: String,
    relative_path: String,
    restore_path: String,
    size: u64,
    sha256: String,
}

const BACKUP_MANIFEST_VERSION: u32 = 1;
const BACKUP_CATEGORY_MEMORY: &str = "memory";
const BACKUP_CATEGORY_MCP: &str = "mcp";
const BACKUP_CATEGORY_ARTIFACTS: &str = "artifacts";
const BACKUP_CATEGORY_HEALTH: &str = "health";

fn backup_root_default() -> PathBuf {
    home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".agentra-backups")
}

fn resolve_backup_root(output: Option<PathBuf>) -> PathBuf {
    output.unwrap_or_else(backup_root_default)
}

fn snapshot_dir_name() -> String {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("snapshot-{ts}")
}

fn backup_manifest_path(snapshot_dir: &Path) -> PathBuf {
    snapshot_dir.join("meta").join("manifest.json")
}

fn sha256_file(path: &Path) -> io::Result<String> {
    let mut file = fs::File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 16 * 1024];
    loop {
        let read = file.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn write_checksum_ledger(snapshot_dir: &Path, entries: &[BackupEntry]) -> io::Result<()> {
    let mut lines = entries
        .iter()
        .map(|entry| format!("{}  {}", entry.sha256, entry.relative_path))
        .collect::<Vec<String>>();
    lines.sort();
    let content = if lines.is_empty() {
        String::new()
    } else {
        format!("{}\n", lines.join("\n"))
    };
    fs::write(snapshot_dir.join("meta").join("SHA256SUMS.txt"), content)
}

fn load_backup_manifest(snapshot_dir: &Path) -> io::Result<BackupManifest> {
    let manifest_path = backup_manifest_path(snapshot_dir);
    let raw = fs::read_to_string(&manifest_path).map_err(|err| {
        io::Error::other(format!(
            "failed to read manifest at {}: {err}",
            manifest_path.display()
        ))
    })?;
    serde_json::from_str::<BackupManifest>(&raw).map_err(|err| {
        io::Error::other(format!(
            "failed to parse manifest at {}: {err}",
            manifest_path.display()
        ))
    })
}

fn collect_snapshot_dirs(root: &Path) -> io::Result<Vec<PathBuf>> {
    if !root.is_dir() {
        return Ok(Vec::new());
    }
    let mut snapshots = Vec::new();
    for entry in fs::read_dir(root)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_dir() {
            snapshots.push(path);
        }
    }
    snapshots.sort_by(|a, b| b.file_name().cmp(&a.file_name()));
    Ok(snapshots)
}

fn is_managed_snapshot_dir(path: &Path) -> bool {
    path.file_name()
        .and_then(|v| v.to_str())
        .map(|name| name.starts_with("snapshot-"))
        .unwrap_or(false)
}

fn plan_backup_prune(snapshots: &[PathBuf], keep: usize) -> (Vec<PathBuf>, Vec<PathBuf>) {
    let mut kept = Vec::new();
    let mut removed = Vec::new();
    for (index, path) in snapshots.iter().enumerate() {
        if index < keep {
            kept.push(path.clone());
        } else {
            removed.push(path.clone());
        }
    }
    (kept, removed)
}

fn resolve_snapshot_dir(backup_root: &Path, input: Option<&str>) -> io::Result<PathBuf> {
    if let Some(raw) = input {
        let is_path_like = raw.starts_with('.')
            || raw.contains('/')
            || raw.contains('\\')
            || Path::new(raw).is_absolute();
        let snapshot = if is_path_like {
            PathBuf::from(raw)
        } else {
            backup_root.join(raw)
        };
        if snapshot.is_dir() {
            return Ok(snapshot);
        }
        return Err(io::Error::other(format!(
            "snapshot not found: {}",
            snapshot.display()
        )));
    }

    let snapshots = collect_snapshot_dirs(backup_root)?;
    snapshots
        .into_iter()
        .next()
        .ok_or_else(|| io::Error::other("no snapshots found"))
}

fn collect_files_recursive(root: &Path, depth: usize, out: &mut Vec<PathBuf>) {
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
            collect_files_recursive(&path, depth - 1, out);
            continue;
        }
        if path.is_file() {
            out.push(path);
        }
    }
}

fn is_runtime_artifact(path: &Path) -> bool {
    matches!(
        path.extension()
            .and_then(|v| v.to_str())
            .map(|v| v.to_ascii_lowercase()),
        Some(ext) if ext == "acb" || ext == "amem" || ext == "avis"
    )
}

fn collect_workspace_artifacts(workspace: &Path, depth: usize) -> Vec<PathBuf> {
    let mut files = Vec::new();
    collect_files_recursive(workspace, depth, &mut files);
    files
        .into_iter()
        .filter(|p| is_runtime_artifact(p))
        .collect()
}

fn resolve_health_ledger_dir() -> Option<PathBuf> {
    for key in ["ACB_HEALTH_LEDGER_DIR", "AGENTRA_HEALTH_LEDGER_DIR"] {
        if let Ok(value) = env::var(key) {
            let trimmed = value.trim();
            if !trimmed.is_empty() {
                return Some(PathBuf::from(trimmed));
            }
        }
    }
    home_dir().map(|home| home.join(".agentra").join("health-ledger"))
}

fn path_under_home_or_abs(path: &Path) -> PathBuf {
    if let Some(home) = home_dir() {
        if let Ok(rel) = path.strip_prefix(&home) {
            return PathBuf::from("home").join(rel);
        }
    }

    let mut out = PathBuf::from("abs");
    for component in path.components() {
        match component {
            Component::Normal(part) => out.push(part),
            Component::Prefix(prefix) => out.push(prefix.as_os_str()),
            Component::RootDir | Component::CurDir | Component::ParentDir => {}
        }
    }
    out
}

fn copy_and_record_backup(
    snapshot_dir: &Path,
    source: &Path,
    relative_path: &Path,
    restore_path: &Path,
    category: &str,
    entries: &mut Vec<BackupEntry>,
) -> io::Result<bool> {
    if !source.is_file() {
        return Ok(false);
    }
    let dest = snapshot_dir.join(relative_path);
    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::copy(source, &dest)?;
    let digest = sha256_file(&dest)?;
    let size = fs::metadata(&dest)?.len();
    entries.push(BackupEntry {
        category: category.to_string(),
        relative_path: relative_path.to_string_lossy().to_string(),
        restore_path: restore_path.to_string_lossy().to_string(),
        size,
        sha256: digest,
    });
    Ok(true)
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
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        % 86_400;
    let h = secs / 3_600;
    let m = (secs % 3_600) / 60;
    let s = secs % 60;
    format!("{h:02}:{m:02}:{s:02}")
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

fn health_summary(ok: usize, disabled: usize, total: usize) -> String {
    if ok == total {
        return "All good.".to_string();
    }
    if ok == 0 {
        return "No active tools detected.".to_string();
    }
    let missing = total.saturating_sub(ok + disabled);
    if missing > 0 {
        return format!("{missing} missing, {disabled} disabled.");
    }
    if disabled > 0 {
        return format!("{disabled} disabled.");
    }
    "Status updated.".to_string()
}

fn bool_label(value: bool) -> &'static str {
    if value {
        "on"
    } else {
        "off"
    }
}

fn parse_artifact_dirs_value(value: &str) -> Vec<PathBuf> {
    value
        .split(':')
        .map(str::trim)
        .filter(|entry| !entry.is_empty())
        .map(PathBuf::from)
        .collect()
}

fn extra_artifact_dirs() -> Vec<PathBuf> {
    env::var("AGENTRA_ARTIFACT_DIRS")
        .ok()
        .map(|v| parse_artifact_dirs_value(&v))
        .unwrap_or_default()
}

fn env_truthy(name: &str) -> bool {
    matches!(
        env::var(name)
            .ok()
            .as_deref()
            .map(|v| v.trim().to_ascii_lowercase()),
        Some(v) if v == "1" || v == "true" || v == "yes" || v == "on"
    )
}

fn is_server_runtime() -> bool {
    if env_truthy("AGENTRA_SERVER") || env_truthy("AGENTRA_SERVER_MODE") {
        return true;
    }

    if let Ok(mode) = env::var("AGENTRA_RUNTIME_MODE") {
        if mode.trim().eq_ignore_ascii_case("server") {
            return true;
        }
    }

    if let Ok(profile) = env::var("AGENTRA_PROFILE") {
        if profile.trim().eq_ignore_ascii_case("server") {
            return true;
        }
    }

    if let Ok(profile) = env::var("AGENTRA_INSTALL_PROFILE") {
        if profile.trim().eq_ignore_ascii_case("server") {
            return true;
        }
    }

    false
}

fn server_auth_configured() -> bool {
    if env::var("AGENTIC_TOKEN")
        .ok()
        .map(|v| !v.trim().is_empty())
        .unwrap_or(false)
    {
        return true;
    }

    for key in ["AGENTIC_TOKEN_FILE", "AGENTRA_AUTH_TOKEN_FILE"] {
        if let Ok(path) = env::var(key) {
            let token_path = PathBuf::from(path.trim());
            if token_path.is_file() {
                if let Ok(content) = fs::read_to_string(&token_path) {
                    if !content.trim().is_empty() {
                        return true;
                    }
                }
            }
        }
    }

    false
}

fn server_auth_source() -> Option<String> {
    if env::var("AGENTIC_TOKEN")
        .ok()
        .map(|v| !v.trim().is_empty())
        .unwrap_or(false)
    {
        return Some("AGENTIC_TOKEN env".to_string());
    }

    for key in ["AGENTIC_TOKEN_FILE", "AGENTRA_AUTH_TOKEN_FILE"] {
        if let Ok(path) = env::var(key) {
            let trimmed = path.trim();
            if trimmed.is_empty() {
                continue;
            }
            let token_path = PathBuf::from(trimmed);
            if token_path.is_file() {
                if let Ok(content) = fs::read_to_string(&token_path) {
                    if !content.trim().is_empty() {
                        return Some(format!("{key}={}", token_path.display()));
                    }
                }
            }
        }
    }

    None
}

fn runtime_mode_label() -> &'static str {
    if is_server_runtime() {
        "server"
    } else {
        "desktop/terminal"
    }
}

fn artifact_roots_for_scan() -> Vec<PathBuf> {
    let mut roots = BTreeSet::new();
    roots.insert(workspace_root());
    for dir in extra_artifact_dirs() {
        roots.insert(dir);
    }
    roots.into_iter().collect()
}

fn artifact_roots_display() -> String {
    let roots = artifact_roots_for_scan();
    roots
        .iter()
        .map(|p| p.display().to_string())
        .collect::<Vec<String>>()
        .join(" | ")
}

fn artifact_roots_for_server_preflight(overrides: &[PathBuf]) -> Vec<PathBuf> {
    let mut roots = BTreeSet::new();
    if !overrides.is_empty() {
        for dir in overrides {
            roots.insert(dir.clone());
        }
        return roots.into_iter().collect();
    }
    for dir in extra_artifact_dirs() {
        roots.insert(dir);
    }
    roots.into_iter().collect()
}

fn detect_artifact_presence_in_roots(roots: &[PathBuf]) -> ArtifactPresence {
    let mut presence = ArtifactPresence::default();
    for root in roots {
        scan_artifacts_recursive(root, 8, &mut presence);
    }
    presence
}

fn server_takeover_block_reason() -> Option<String> {
    if is_server_runtime() && !server_auth_configured() {
        return Some(
            "Skipped takeover: server auth missing (set AGENTIC_TOKEN or AGENTIC_TOKEN_FILE)"
                .to_string(),
        );
    }
    None
}

fn home_dir() -> Option<PathBuf> {
    env::var_os("HOME").map(PathBuf::from)
}

fn resolve_sister_binary(spec: SisterMcpSpec) -> Option<PathBuf> {
    if let Some(path_hit) = find_on_path(spec.launcher) {
        return Some(path_hit);
    }
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
            push_json_target(&mut targets, &mut seen_paths, "Generic MCP JSON", path);
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
            serde_json::to_string_pretty(&config).unwrap_or_else(|_| "{}".to_string()) + "\n",
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
    for root in artifact_roots_for_scan() {
        scan_artifacts_recursive(&root, 6, &mut presence);
    }

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
    if let Some(reason) = server_takeover_block_reason() {
        return Ok(vec![reason]);
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
                target: format!("MCP command {}", spec.key),
                status: DoctorStatus::Pass,
                detail: format!("Detected at {}", path.display()),
            }
        } else {
            DoctorRow {
                target: format!("MCP command {}", spec.key),
                status: DoctorStatus::Fail,
                detail: format!("Missing. Install this sister to expose '{}'.", spec.key),
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

fn run_server_preflight(strict: bool, artifact_dirs: Vec<PathBuf>) -> io::Result<()> {
    println!("Agentra Server Preflight");
    println!("========================");
    println!("Mode: {}", if strict { "strict" } else { "advisory" });
    println!();

    let mut pass_count = 0usize;
    let mut warn_count = 0usize;
    let mut fail_count = 0usize;

    let mut emit = |status: &str, label: &str, detail: String| {
        match status {
            "PASS" => pass_count += 1,
            "WARN" => warn_count += 1,
            "FAIL" => fail_count += 1,
            _ => {}
        }
        println!("[{status}] {:<32} {detail}", label);
    };

    if is_server_runtime() {
        emit("PASS", "Runtime mode", "server runtime enabled".to_string());
    } else {
        emit(
            "FAIL",
            "Runtime mode",
            "not in server mode (set AGENTRA_RUNTIME_MODE=server)".to_string(),
        );
    }

    if let Some(source) = server_auth_source() {
        emit("PASS", "Server auth", format!("configured via {source}"));
    } else {
        emit(
            "FAIL",
            "Server auth",
            "missing token (set AGENTIC_TOKEN or AGENTIC_TOKEN_FILE)".to_string(),
        );
    }

    let roots = artifact_roots_for_server_preflight(&artifact_dirs);
    if roots.is_empty() {
        emit(
            "FAIL",
            "Artifact dirs",
            "none configured (set AGENTRA_ARTIFACT_DIRS or pass --artifact-dir)".to_string(),
        );
    } else {
        emit(
            "PASS",
            "Artifact dirs",
            roots
                .iter()
                .map(|p| p.display().to_string())
                .collect::<Vec<String>>()
                .join(" | "),
        );
        let mut existing_roots = Vec::new();
        for root in &roots {
            if root.is_dir() {
                emit(
                    "PASS",
                    "Artifact root",
                    format!("exists: {}", root.display()),
                );
                existing_roots.push(root.clone());
            } else {
                emit(
                    "FAIL",
                    "Artifact root",
                    format!(
                        "missing: {} (sync artifacts to this path first)",
                        root.display()
                    ),
                );
            }
        }

        if !existing_roots.is_empty() {
            let presence = detect_artifact_presence_in_roots(&existing_roots);
            let total = presence.codebase + presence.memory + presence.vision;
            if total > 0 {
                emit(
                    "PASS",
                    "Artifacts discovered",
                    format!(
                        ".acb={} .amem={} .avis={}",
                        presence.codebase, presence.memory, presence.vision
                    ),
                );
            } else {
                emit(
                    "WARN",
                    "Artifacts discovered",
                    "none found in artifact dirs (run ./sync_artifacts.sh --target=<server-path>)"
                        .to_string(),
                );
            }
        }
    }

    for spec in MCP_SISTERS {
        let label = format!("MCP command {}", spec.key);
        if let Some(path) = resolve_sister_binary(spec) {
            emit("PASS", &label, format!("resolved at {}", path.display()));
        } else {
            emit("FAIL", &label, "not found on server host".to_string());
        }
    }

    let sync_script = workspace_root().join("sync_artifacts.sh");
    if sync_script.is_file() {
        emit(
            "PASS",
            "Sync helper",
            format!("available at {}", sync_script.display()),
        );
    } else {
        emit(
            "WARN",
            "Sync helper",
            "sync_artifacts.sh not found in workspace root".to_string(),
        );
    }

    println!();
    println!(
        "Summary: pass={} warn={} fail={}",
        pass_count, warn_count, fail_count
    );
    if fail_count > 0 {
        println!("Recommended exports:");
        println!("  export AGENTRA_RUNTIME_MODE=server");
        println!("  export AGENTIC_TOKEN=\"$(openssl rand -hex 32)\"");
        println!("  export AGENTRA_ARTIFACT_DIRS=\"/srv/agentra:/data/brains\"");
    }
    if strict && fail_count > 0 {
        return Err(io::Error::other("server preflight failed in strict mode"));
    }
    Ok(())
}

fn run_backup_run(workspace: Option<PathBuf>, output: Option<PathBuf>) -> io::Result<()> {
    let workspace_root = workspace.unwrap_or(env::current_dir()?);
    let backup_root = resolve_backup_root(output);
    fs::create_dir_all(&backup_root)?;

    let snapshot_dir = backup_root.join(snapshot_dir_name());
    fs::create_dir_all(snapshot_dir.join("meta"))?;

    let mut entries = Vec::new();
    let mut category_counts: BTreeMap<&'static str, usize> = BTreeMap::new();

    if let Some(home) = home_dir() {
        let brain = home.join(".brain.amem");
        if copy_and_record_backup(
            &snapshot_dir,
            &brain,
            Path::new("memory").join("brain.amem").as_path(),
            &brain,
            BACKUP_CATEGORY_MEMORY,
            &mut entries,
        )? {
            *category_counts.entry(BACKUP_CATEGORY_MEMORY).or_insert(0) += 1;
        }
    }

    let mut mcp_paths = BTreeSet::new();
    for target in collect_mcp_targets() {
        if target.path.is_file() {
            mcp_paths.insert(target.path);
        }
    }
    for mcp_path in mcp_paths {
        let relative = Path::new("mcp").join(path_under_home_or_abs(&mcp_path));
        if copy_and_record_backup(
            &snapshot_dir,
            &mcp_path,
            &relative,
            &mcp_path,
            BACKUP_CATEGORY_MCP,
            &mut entries,
        )? {
            *category_counts.entry(BACKUP_CATEGORY_MCP).or_insert(0) += 1;
        }
    }

    for artifact in collect_workspace_artifacts(&workspace_root, 8) {
        let rel = artifact
            .strip_prefix(&workspace_root)
            .map(Path::to_path_buf)
            .unwrap_or_else(|_| {
                artifact
                    .file_name()
                    .map(PathBuf::from)
                    .unwrap_or_else(|| PathBuf::from("artifact"))
            });
        let relative = Path::new("artifacts").join(rel);
        if copy_and_record_backup(
            &snapshot_dir,
            &artifact,
            &relative,
            &artifact,
            BACKUP_CATEGORY_ARTIFACTS,
            &mut entries,
        )? {
            *category_counts
                .entry(BACKUP_CATEGORY_ARTIFACTS)
                .or_insert(0) += 1;
        }
    }

    if let Some(health_root) = resolve_health_ledger_dir() {
        if health_root.is_dir() {
            let mut health_files = Vec::new();
            collect_files_recursive(&health_root, 8, &mut health_files);
            for file in health_files {
                let rel = file
                    .strip_prefix(&health_root)
                    .map(Path::to_path_buf)
                    .unwrap_or_else(|_| {
                        file.file_name()
                            .map(PathBuf::from)
                            .unwrap_or_else(|| PathBuf::from("health-file"))
                    });
                let relative = Path::new("health").join(rel);
                if copy_and_record_backup(
                    &snapshot_dir,
                    &file,
                    &relative,
                    &file,
                    BACKUP_CATEGORY_HEALTH,
                    &mut entries,
                )? {
                    *category_counts.entry(BACKUP_CATEGORY_HEALTH).or_insert(0) += 1;
                }
            }
        }
    }

    let manifest = BackupManifest {
        version: BACKUP_MANIFEST_VERSION,
        created_unix: SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs(),
        workspace_root: workspace_root.display().to_string(),
        entries,
    };

    fs::write(
        backup_manifest_path(&snapshot_dir),
        serde_json::to_string_pretty(&manifest).unwrap_or_else(|_| "{}".to_string()) + "\n",
    )?;
    write_checksum_ledger(&snapshot_dir, &manifest.entries)?;

    println!("Agentra backup snapshot created");
    println!("Snapshot: {}", snapshot_dir.display());
    println!("Workspace: {}", workspace_root.display());
    println!("Entries: {}", manifest.entries.len());
    println!(
        "Counts: memory={} mcp={} artifacts={} health={}",
        category_counts
            .get(BACKUP_CATEGORY_MEMORY)
            .copied()
            .unwrap_or(0),
        category_counts
            .get(BACKUP_CATEGORY_MCP)
            .copied()
            .unwrap_or(0),
        category_counts
            .get(BACKUP_CATEGORY_ARTIFACTS)
            .copied()
            .unwrap_or(0),
        category_counts
            .get(BACKUP_CATEGORY_HEALTH)
            .copied()
            .unwrap_or(0),
    );
    println!(
        "Manifest: {}",
        backup_manifest_path(&snapshot_dir).display()
    );
    println!(
        "Checksums: {}",
        snapshot_dir.join("meta").join("SHA256SUMS.txt").display()
    );

    if manifest.entries.is_empty() {
        println!("Note: no files were discovered to back up in this run.");
    } else {
        println!(
            "Next: run `agentra backup verify {}`",
            snapshot_dir.display()
        );
    }
    Ok(())
}

fn run_backup_list(output: Option<PathBuf>, limit: usize) -> io::Result<()> {
    let backup_root = resolve_backup_root(output);
    println!("Agentra backups root: {}", backup_root.display());
    let snapshots = collect_snapshot_dirs(&backup_root)?;
    if snapshots.is_empty() {
        println!("No snapshots found.");
        return Ok(());
    }

    let mut shown = 0usize;
    for snapshot in snapshots {
        if shown >= limit {
            break;
        }
        let name = snapshot
            .file_name()
            .and_then(|v| v.to_str())
            .unwrap_or("<unknown>");
        match load_backup_manifest(&snapshot) {
            Ok(manifest) => {
                println!(
                    "{:<28} entries={:<4} created_unix={} workspace={}",
                    name,
                    manifest.entries.len(),
                    manifest.created_unix,
                    manifest.workspace_root
                );
            }
            Err(_) => {
                println!("{:<28} (missing or invalid manifest)", name);
            }
        }
        shown += 1;
    }
    Ok(())
}

fn run_backup_verify(snapshot: Option<String>, output: Option<PathBuf>) -> io::Result<()> {
    let backup_root = resolve_backup_root(output);
    let snapshot_dir = resolve_snapshot_dir(&backup_root, snapshot.as_deref())?;
    let manifest = load_backup_manifest(&snapshot_dir)?;

    println!("Agentra backup verify");
    println!("Snapshot: {}", snapshot_dir.display());
    println!("Entries: {}", manifest.entries.len());

    let mut ok = 0usize;
    let mut failed = 0usize;
    for entry in &manifest.entries {
        let path = snapshot_dir.join(&entry.relative_path);
        if !path.is_file() {
            println!("[FAIL] missing: {}", path.display());
            failed += 1;
            continue;
        }
        let digest = sha256_file(&path)?;
        if digest != entry.sha256 {
            println!(
                "[FAIL] checksum mismatch: {} expected={} actual={}",
                path.display(),
                entry.sha256,
                digest
            );
            failed += 1;
            continue;
        }
        ok += 1;
    }

    println!("Summary: ok={} fail={}", ok, failed);
    if failed > 0 {
        return Err(io::Error::other("backup verify detected checksum failures"));
    }
    Ok(())
}

fn should_restore_entry(
    category: &str,
    memory: bool,
    mcp: bool,
    artifacts: bool,
    any_selector: bool,
) -> bool {
    if !any_selector {
        return true;
    }
    (memory && category == BACKUP_CATEGORY_MEMORY)
        || (mcp && category == BACKUP_CATEGORY_MCP)
        || (artifacts
            && (category == BACKUP_CATEGORY_ARTIFACTS || category == BACKUP_CATEGORY_HEALTH))
}

fn run_backup_restore(
    snapshot: String,
    output: Option<PathBuf>,
    memory: bool,
    mcp: bool,
    artifacts: bool,
    force: bool,
) -> io::Result<()> {
    let backup_root = resolve_backup_root(output);
    let snapshot_dir = resolve_snapshot_dir(&backup_root, Some(snapshot.as_str()))?;
    let manifest = load_backup_manifest(&snapshot_dir)?;
    let any_selector = memory || mcp || artifacts;

    println!("Agentra backup restore");
    println!("Snapshot: {}", snapshot_dir.display());
    println!("Stop active MCP/desktop clients before restore for best results.");

    let mut restored = 0usize;
    let mut failed = 0usize;
    let mut skipped = 0usize;

    for entry in &manifest.entries {
        if !should_restore_entry(&entry.category, memory, mcp, artifacts, any_selector) {
            skipped += 1;
            continue;
        }

        let source = snapshot_dir.join(&entry.relative_path);
        let restore_path = PathBuf::from(&entry.restore_path);
        if !source.is_file() {
            println!("[FAIL] missing backup source: {}", source.display());
            failed += 1;
            continue;
        }

        let digest = sha256_file(&source)?;
        if digest != entry.sha256 {
            println!(
                "[FAIL] checksum mismatch before restore: {} expected={} actual={}",
                source.display(),
                entry.sha256,
                digest
            );
            failed += 1;
            continue;
        }

        if let Some(parent) = restore_path.parent() {
            fs::create_dir_all(parent)?;
        }
        if restore_path.exists() && !force {
            let _ = backup_file(&restore_path);
        }
        if let Err(err) = fs::copy(&source, &restore_path) {
            println!(
                "[FAIL] copy {} -> {} ({err})",
                source.display(),
                restore_path.display()
            );
            failed += 1;
            continue;
        }
        restored += 1;
    }

    println!(
        "Summary: restored={} skipped={} fail={}",
        restored, skipped, failed
    );
    if failed > 0 {
        return Err(io::Error::other("restore completed with failures"));
    }
    println!("Next: run `agentra doctor --fix` and restart MCP clients.");
    Ok(())
}

fn run_backup_prune(output: Option<PathBuf>, keep: usize, dry_run: bool) -> io::Result<()> {
    let backup_root = resolve_backup_root(output);
    println!("Agentra backup prune");
    println!("Root: {}", backup_root.display());
    println!("Keep newest: {}", keep);
    if dry_run {
        println!("Mode: dry-run");
    }

    let all = collect_snapshot_dirs(&backup_root)?;
    let managed = all
        .into_iter()
        .filter(|path| is_managed_snapshot_dir(path))
        .collect::<Vec<PathBuf>>();
    if managed.is_empty() {
        println!("No managed snapshot directories found.");
        return Ok(());
    }

    let (kept, removed) = plan_backup_prune(&managed, keep);
    if removed.is_empty() {
        println!("Nothing to prune (managed snapshots: {}).", managed.len());
        return Ok(());
    }

    for path in &removed {
        if dry_run {
            println!("[DRY] remove {}", path.display());
            continue;
        }
        fs::remove_dir_all(path)?;
        println!("[OK] removed {}", path.display());
    }

    println!(
        "Summary: kept={} pruned={} total_managed={}",
        kept.len(),
        removed.len(),
        managed.len()
    );
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
                "Initialized at {} - {} Press h for hints.",
                hhmm_string(),
                health_summary(ok, disabled, total)
            ),
            message: "Live auto-refresh every 5s. Press h for hints, r to refresh, q to quit."
                .to_string(),
            show_help_popup: false,
        }
    }

    fn refresh(&mut self, reason: &str) {
        self.config = load_config();
        self.tools = detect_tools(&self.config);
        self.last_refresh = now_string();
        let (ok, disabled, total) = counts(&self.tools);
        self.last_action_log = format!(
            "{reason} at {} - {} Press h for hints.",
            hhmm_string(),
            health_summary(ok, disabled, total)
        );
        self.message =
            "Live auto-refresh every 5s. Press h for hints, r to refresh, q to quit.".to_string();
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
        self.message =
            "Live auto-refresh every 5s. Press h for hints, r to refresh, q to quit.".to_string();
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

    let log_widget = Paragraph::new(app.last_action_log.clone())
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
    let runtime_mode = runtime_mode_label();

    println!("Agentra sister status");
    println!("=====================");
    println!("Config file: {}", config_path().display());
    println!("Config: {}", config.summary());
    println!("Runtime mode: {runtime_mode}");
    println!("Artifact scan roots: {}", artifact_roots_display());
    if is_server_runtime() {
        println!(
            "Server auth: {}",
            if server_auth_configured() {
                "configured"
            } else {
                "missing (set AGENTIC_TOKEN or AGENTIC_TOKEN_FILE)"
            }
        );
        if extra_artifact_dirs().is_empty() {
            println!(
                "Server note: cloud runtimes cannot read laptop files directly. Sync artifacts first, then set AGENTRA_ARTIFACT_DIRS."
            );
        }
    }
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
    let resync_notes = auto_resync_from_artifacts().unwrap_or_default();
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
    println!("Runtime mode: {}", runtime_mode_label());
    println!("Artifact roots: {}", artifact_roots_display());
    if is_server_runtime() {
        println!(
            "Server auth: {}",
            if server_auth_configured() {
                "configured"
            } else {
                "missing (set AGENTIC_TOKEN or AGENTIC_TOKEN_FILE)"
            }
        );
        if extra_artifact_dirs().is_empty() {
            println!("Server note: set AGENTRA_ARTIFACT_DIRS to synced artifact paths.");
        }
    }
    for note in &resync_notes {
        println!("Runtime resync: {note}");
    }
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
        Commands::Backup { command } => match command {
            BackupCommands::Run { workspace, output } => run_backup_run(workspace, output),
            BackupCommands::List { output, limit } => run_backup_list(output, limit),
            BackupCommands::Verify { snapshot, output } => run_backup_verify(snapshot, output),
            BackupCommands::Restore {
                snapshot,
                output,
                memory,
                mcp,
                artifacts,
                force,
            } => run_backup_restore(snapshot, output, memory, mcp, artifacts, force),
            BackupCommands::Prune {
                output,
                keep,
                dry_run,
            } => run_backup_prune(output, keep, dry_run),
        },
        Commands::Server { command } => match command {
            ServerCommands::Preflight {
                strict,
                artifact_dirs,
            } => run_server_preflight(strict, artifact_dirs),
        },
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
        fs::write(
            &cfg_path,
            serde_json::to_string_pretty(&config).unwrap() + "\n",
        )
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

    #[test]
    fn artifact_dirs_parser_handles_blanks() {
        let parsed = parse_artifact_dirs_value(" /a:/b::/c ");
        assert_eq!(
            parsed,
            vec![
                PathBuf::from("/a"),
                PathBuf::from("/b"),
                PathBuf::from("/c")
            ]
        );
    }

    #[test]
    fn prune_plan_keeps_newest_and_removes_older() {
        let snapshots = vec![
            PathBuf::from("/tmp/snapshot-300"),
            PathBuf::from("/tmp/snapshot-200"),
            PathBuf::from("/tmp/snapshot-100"),
        ];
        let (kept, removed) = plan_backup_prune(&snapshots, 2);
        assert_eq!(
            kept,
            vec![
                PathBuf::from("/tmp/snapshot-300"),
                PathBuf::from("/tmp/snapshot-200"),
            ]
        );
        assert_eq!(removed, vec![PathBuf::from("/tmp/snapshot-100")]);
    }

    #[test]
    fn managed_snapshot_dir_requires_snapshot_prefix() {
        assert!(is_managed_snapshot_dir(Path::new("/tmp/snapshot-123")));
        assert!(!is_managed_snapshot_dir(Path::new("/tmp/manual")));
    }
}
