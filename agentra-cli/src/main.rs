use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

use clap::{Parser, Subcommand, ValueEnum};
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use crossterm::ExecutableCommand;
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout};
use ratatui::style::{Color, Modifier, Style};
use ratatui::widgets::{Block, Borders, Cell, Paragraph, Row, Table, Wrap};
use ratatui::Terminal;
use serde::{Deserialize, Serialize};

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
    message: String,
}

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

fn bool_label(value: bool) -> &'static str {
    if value {
        "on"
    } else {
        "off"
    }
}

impl App {
    fn new() -> Self {
        let config = load_config();

        Self {
            tools: detect_tools(&config),
            config,
            last_refresh: now_string(),
            message: "Press r to refresh, h for start hints, q to quit.".to_string(),
        }
    }

    fn refresh(&mut self) {
        self.config = load_config();
        self.tools = detect_tools(&self.config);
        self.last_refresh = now_string();
        self.message = "Status refreshed.".to_string();
    }

    fn show_hints(&mut self) {
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
            self.message = format!("Start hints: {}", hints.join(" | "));
        }
    }
}

fn draw_ui(frame: &mut ratatui::Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),
            Constraint::Min(8),
            Constraint::Length(4),
            Constraint::Length(3),
        ])
        .split(frame.area());

    let header = Paragraph::new(
        "Agentra Dashboard: sisters remain independently installable; this UI orchestrates state and visibility.",
    )
    .block(Block::default().borders(Borders::ALL).title("Agentra"))
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
            Constraint::Length(16),
            Constraint::Length(10),
            Constraint::Min(20),
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

    let ok_count = app
        .tools
        .iter()
        .filter(|t| matches!(t.status, ToolStatus::Ok))
        .count();
    let disabled_count = app
        .tools
        .iter()
        .filter(|t| matches!(t.status, ToolStatus::Disabled))
        .count();
    let summary = format!(
        "OK: {} | Disabled: {} | Total: {} | Last refresh: {}\nConfig: {}",
        ok_count,
        disabled_count,
        app.tools.len(),
        app.last_refresh,
        app.config.summary()
    );

    let summary_widget = Paragraph::new(summary)
        .block(Block::default().borders(Borders::ALL).title("Summary"))
        .wrap(Wrap { trim: true });
    frame.render_widget(summary_widget, chunks[2]);

    let footer = Paragraph::new(app.message.clone())
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Controls: r refresh | h hints | q quit"),
        )
        .wrap(Wrap { trim: true });
    frame.render_widget(footer, chunks[3]);
}

fn run_ui() -> io::Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    stdout.execute(EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    let mut app = App::new();

    let result = loop {
        terminal.draw(|f| draw_ui(f, &app))?;

        if event::poll(Duration::from_millis(250))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    match key.code {
                        KeyCode::Char('q') | KeyCode::Esc => break Ok(()),
                        KeyCode::Char('r') => app.refresh(),
                        KeyCode::Char('h') => app.show_hints(),
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
    let config = load_config();
    let tools = detect_tools(&config);

    println!("Agentra sister status");
    println!("=====================");
    println!("Config file: {}", config_path().display());
    println!("Config: {}", config.summary());
    println!();

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
    let config = load_config();

    let enabled_count = [config.use_codebase, config.use_memory, config.use_vision]
        .iter()
        .filter(|v| **v)
        .count();

    let (state_icon, state_label) = if enabled_count == 0 {
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

    let full_control = if config.agentra_full_control && enabled_count == 3 {
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
        "Full Control: {full_control} ({enabled_count}/3 enabled) | Toggle with `agentra ui` or command"
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
    }
}
