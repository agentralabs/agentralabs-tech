use std::env;
use std::io;
use std::path::{Path, PathBuf};
use std::time::{Duration, SystemTime};

use clap::{Parser, Subcommand};
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
    Status,
}

#[derive(Clone, Copy)]
struct ToolSpec {
    label: &'static str,
    command: &'static str,
    local_rel: &'static str,
    start_hint: &'static str,
}

#[derive(Clone)]
struct ToolState {
    label: &'static str,
    installed: bool,
    source: String,
    start_hint: &'static str,
}

struct App {
    tools: Vec<ToolState>,
    last_refresh: String,
    message: String,
}

const TOOL_SPECS: [ToolSpec; 6] = [
    ToolSpec {
        label: "Codebase CLI",
        command: "acb",
        local_rel: "agentic-codebase/target/release/acb",
        start_hint: "acb --help",
    },
    ToolSpec {
        label: "Codebase MCP",
        command: "acb-mcp",
        local_rel: "agentic-codebase/target/release/acb-mcp",
        start_hint: "acb-mcp --help",
    },
    ToolSpec {
        label: "Memory CLI",
        command: "amem",
        local_rel: "agentic-memory/target/release/amem",
        start_hint: "amem --help",
    },
    ToolSpec {
        label: "Memory MCP",
        command: "agentic-memory-mcp",
        local_rel: "agentic-memory/target/release/agentic-memory-mcp",
        start_hint: "agentic-memory-mcp --help",
    },
    ToolSpec {
        label: "Vision MCP",
        command: "agentic-vision-mcp",
        local_rel: "agentic-vision/target/release/agentic-vision-mcp",
        start_hint: "agentic-vision-mcp --help",
    },
    ToolSpec {
        label: "Ollama",
        command: "ollama",
        local_rel: "",
        start_hint: "ollama serve",
    },
];

fn workspace_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map(Path::to_path_buf)
        .unwrap_or_else(|| PathBuf::from("."))
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

fn detect_tools() -> Vec<ToolState> {
    let root = workspace_root();

    TOOL_SPECS
        .iter()
        .map(|spec| {
            if let Some(path_hit) = find_on_path(spec.command) {
                return ToolState {
                    label: spec.label,
                    installed: true,
                    source: format!("PATH: {}", path_hit.display()),
                    start_hint: spec.start_hint,
                };
            }

            if !spec.local_rel.is_empty() {
                let local = root.join(spec.local_rel);
                if local.is_file() {
                    return ToolState {
                        label: spec.label,
                        installed: true,
                        source: format!("local build: {}", local.display()),
                        start_hint: spec.start_hint,
                    };
                }
            }

            ToolState {
                label: spec.label,
                installed: false,
                source: "not found".to_string(),
                start_hint: spec.start_hint,
            }
        })
        .collect()
}

fn now_string() -> String {
    format!("{:?}", SystemTime::now())
}

impl App {
    fn new() -> Self {
        Self {
            tools: detect_tools(),
            last_refresh: now_string(),
            message: "Press r to refresh, h for start hints, q to quit.".to_string(),
        }
    }

    fn refresh(&mut self) {
        self.tools = detect_tools();
        self.last_refresh = now_string();
        self.message = "Status refreshed.".to_string();
    }

    fn show_hints(&mut self) {
        let hints: Vec<&str> = self
            .tools
            .iter()
            .filter(|t| t.installed)
            .map(|t| t.start_hint)
            .collect();

        if hints.is_empty() {
            self.message = "No tools detected. Install sisters individually; this UI will pick them up automatically."
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

    let header = Paragraph::new("Agentra Dashboard: Sisters remain independently installable; this UI is only an orchestrator.")
        .block(Block::default().borders(Borders::ALL).title("Agentra"))
        .wrap(Wrap { trim: true });
    frame.render_widget(header, chunks[0]);

    let rows = app.tools.iter().map(|t| {
        let status = if t.installed { "OK" } else { "MISSING" };
        let style = if t.installed {
            Style::default().fg(Color::Green)
        } else {
            Style::default().fg(Color::Red)
        };

        Row::new(vec![
            Cell::from(t.label),
            Cell::from(status).style(style.add_modifier(Modifier::BOLD)),
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

    let summary = format!(
        "Installed: {} / {} | Last refresh: {}",
        app.tools.iter().filter(|t| t.installed).count(),
        app.tools.len(),
        app.last_refresh
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
    let tools = detect_tools();
    println!("Agentra sister status");
    println!("=====================");

    for t in tools {
        let status = if t.installed { "OK" } else { "MISSING" };
        println!("{:<16} {:<8} {}", t.label, status, t.source);
        if !t.installed {
            println!("  hint: {}", t.start_hint);
        }
    }

    println!();
    println!(
        "Note: Sisters can be installed and used independently; agentra only orchestrates UX."
    );
}

fn main() -> io::Result<()> {
    let cli = Cli::parse();

    match cli.command.unwrap_or(Commands::Ui) {
        Commands::Ui => run_ui(),
        Commands::Status => {
            run_status();
            Ok(())
        }
    }
}
