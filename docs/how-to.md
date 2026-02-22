# Agentra Workspace How-To

## 1. Install All Sisters Locally

From `/Users/omoshola/Documents/agentralabs-tech`:

```bash
./install_all.sh
```

Dry run only:

```bash
./install_all.sh --test-mode
```

## 2. Verify Tool Detection

```bash
cargo run --bin agentra status
cargo run --bin agentra -- status --session
```

Expected states are `OK`, `DISABLED`, or `MISSING` with hints.

## 3. Toggle Sisters On/Off

```bash
cargo run --bin agentra -- toggle codebase off
cargo run --bin agentra -- toggle memory off
cargo run --bin agentra -- toggle vision off
```

Re-enable any sister:

```bash
cargo run --bin agentra -- toggle codebase on
```

Toggles are persisted in `/Users/omoshola/Documents/agentralabs-tech/agentra-config.json`.

## 4. Start the Dashboard

```bash
cargo run --bin agentra ui
```

Controls:

- `r` refresh
- `h` hints
- `q` quit

## 5. Run a Local AI Smoke Test

```bash
./local_ai_test.sh
```

Requirements:

- `ollama` in `PATH`
- local model `llama3`

## 6. Build and Package

```bash
cargo build --release -p agentra-cli
cargo package -p agentra-cli
```

## 7. Server Runtime (Auth + Local Artifacts)

For server takeover with local artifacts, set:

```bash
export AGENTRA_RUNTIME_MODE=server
export AGENTIC_TOKEN="$(openssl rand -hex 32)"
export AGENTRA_ARTIFACT_DIRS="/srv/agentra:/data/brains"
cargo run --bin agentra -- status --session
```

If you prefer token file:

```bash
export AGENTIC_TOKEN_FILE="/etc/agentra/token"
```

Cloud/server runtimes cannot read files from your laptop directly. Sync first:

```bash
./sync_artifacts.sh --target=<server-path-or-rsync-target>
```

## 8. Screenshot Evidence (Sisters Running)

Generated runtime screenshots are stored under:

- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/codebase-query.png`
- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/memory-add-search.png`
- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/vision-runtime.png`
- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/agentra-status.png`
- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/install-progress.png`
- `/Users/omoshola/Documents/agentralabs-tech/docs/assets/web-screenshots/integrated-workflow.png`
