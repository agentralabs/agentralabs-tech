//! AgenticCognition MCP Server — stdio transport
//!
//! Serves 14 MCP tools for longitudinal user modeling.

use std::io::{BufRead, Write};
use std::path::PathBuf;
use clap::Parser;

mod tools;
mod types;
mod protocol;

use types::*;
use protocol::ProtocolHandler;

#[derive(Parser)]
#[command(name = "acog-mcp", version = "0.1.0", about = "AgenticCognition MCP Server")]
struct Args {
    /// Storage directory for .acog files
    #[arg(long, default_value = "~/.agentic/cognition")]
    storage: String,
}

fn resolve_path(path: &str) -> PathBuf {
    if path.starts_with('~') {
        if let Some(home) = dirs::home_dir() {
            return home.join(&path[2..]);
        }
    }
    PathBuf::from(path)
}

fn main() {
    let args = Args::parse();
    let storage_dir = resolve_path(&args.storage);

    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_writer(std::io::stderr)
        .init();

    tracing::info!("AgenticCognition MCP Server v0.1.0 starting");
    tracing::info!("Storage: {:?}", storage_dir);

    let handler = match ProtocolHandler::new(storage_dir) {
        Ok(h) => h,
        Err(e) => {
            tracing::error!("Failed to initialize: {}", e);
            std::process::exit(1);
        }
    };

    let stdin = std::io::stdin();
    let stdout = std::io::stdout();
    let mut stdout = stdout.lock();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                tracing::error!("Read error: {}", e);
                break;
            }
        };

        if line.trim().is_empty() {
            continue;
        }

        let request: JsonRpcRequest = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                let error_response = JsonRpcResponse::error(
                    None,
                    PARSE_ERROR,
                    format!("Parse error: {e}"),
                );
                let _ = writeln!(stdout, "{}", serde_json::to_string(&error_response).unwrap_or_default());
                let _ = stdout.flush();
                continue;
            }
        };

        let response = handler.handle_request(&request);
        let _ = writeln!(stdout, "{}", serde_json::to_string(&response).unwrap_or_default());
        let _ = stdout.flush();
    }
}
