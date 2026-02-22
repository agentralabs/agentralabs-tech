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
```

Expected states are `OK` or `MISSING` with hints.

## 3. Start the Dashboard

```bash
cargo run --bin agentra ui
```

Controls:

- `r` refresh
- `h` hints
- `q` quit

## 4. Run a Local AI Smoke Test

```bash
./local_ai_test.sh
```

Requirements:

- `ollama` in `PATH`
- local model `llama3`

## 5. Build and Package

```bash
cargo build --release -p agentra-cli
cargo package -p agentra-cli
```
