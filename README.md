# EcoSweep


[![Status](https://img.shields.io/badge/status-active-success)](#) [![License](https://img.shields.io/badge/license-MIT-informational)](#license) [![CI](https://img.shields.io/badge/CI-GitHub%20Actions-blue)](#-continuous-integration) [![Docs](https://img.shields.io/badge/docs-README-lightgrey)](#-table-of-contents)

---

## ✨ Key Features

* **Batch/Sweep Execution:** <brief feature>
* **Config-Driven:** \<how users define runs (.yaml/.json/.env)>
* **Reproducible:** \<seeding, locking, versions>
* **Parallel/Distributed:** \<threads/processes/cluster>
* **Rich Outputs:** \<logs, metrics, CSV/JSON/Parquet, dashboards>
* **Extensible:** \<plugins/hooks/CLI & API>

<!-- Add/remove bullets to match the project. -->

---

## 📦 Supported Environments

* \<Language/Runtime> — e.g., **Python 3.10+** / **Node 18+** / **Go 1.22+**
* Platforms: Linux, macOS, Windows
* Optional: **Docker** & **Docker Compose**

---

## 🧭 Table of Contents

* [About](#-about)
* [Architecture](#-architecture)
* [Quickstart](#-quickstart)

  * [Option A: Run with Docker](#option-a-run-with-docker)
  * [Option B: Run from Source](#option-b-run-from-source)
* [Configuration](#-configuration)
* [Usage](#-usage)

  * [CLI](#cli)
  * [Library/API](#libraryapi)
  * [Examples](#examples)
* [Project Structure](#-project-structure)
* [Output & Result Formats](#-output--result-formats)
* [Performance Tips](#-performance-tips)
* [Testing](#-testing)
* [Troubleshooting](#-troubleshooting)
* [FAQ](#-faq)
* [Roadmap](#-roadmap)
* [Contributing](#-contributing)
* [Security](#-security)
* [License](#-license)
* [Acknowledgments](#-acknowledgments)

---

## 🔎 About

`ecpsweep` helps you <what it helps with>. It’s designed for \<target users: researchers/devops/data-engineers/etc.> who need to <core value>.

**Why ecpsweep?**

* \<Differentiator 1>
* \<Differentiator 2>
* \<Differentiator 3>

> **Demo / Screenshot:**
> Add a short GIF or screenshot here.
> `docs/media/demo.gif`

---

## 🏗 Architecture

```
+-------------------+       +--------------------+
|  CLI / REST API   | <---> |  Core Orchestrator |
+-------------------+       +--------------------+
                                     |
                   +-----------------+-----------------+
                   |                 |                 |
             Runners/Exec       Metrics/Logs       Storage/Artifacts
               (local,             (stdout,         (fs, S3, DB)
            threads, remote)         JSON)
```

* **Core Orchestrator:** parses configs, schedules runs, handles retries, collects results.
* **Runners:** \<local subprocess, thread pool, k8s jobs, ssh, etc.>
* **Telemetry:** \<structured logs, metrics, optional OpenTelemetry>
* **Storage:** \<file system/S3/DB — describe where results live>

> Detailed diagram: `docs/architecture.svg`

---

## ⚡ Quickstart

### Option A: Run with Docker

```bash
# 1) Build
docker build -t ecpsweep:latest .

# 2) Run a sample sweep (mount local config & outputs)
docker run --rm \
  -v "$PWD/config:/app/config" \
  -v "$PWD/outputs:/app/outputs" \
  ecpsweep:latest run --config config/sample.yaml --out outputs/run1
```

> Compose example (optional): see `deploy/docker-compose.yml`.

### Option B: Run from Source

<!-- Keep only the block that matches your stack and delete the others. -->

**Python**

```bash
# 1) Create venv
python -m venv .venv && source .venv/bin/activate  # (Windows) .venv\Scripts\activate

# 2) Install
pip install -U pip
pip install -e .  # if using a pyproject.toml / setup.cfg
# or: pip install -r requirements.txt

# 3) Sanity check
ecpsweep --version
ecpsweep --help
```

**Node.js**

```bash
# 1) Install
pnpm i  # or npm i / yarn

# 2) Build (if TS)
pnpm build

# 3) Run
pnpm ecpsweep --help
```

---

## ⚙️ Configuration

`ecpsweep` is configured via YAML/JSON and environment variables.

**Config file (YAML)**

```yaml
# config/sample.yaml
name: "baseline-sweep-001"
seed: 42
concurrency: 4
matrix:
  lr: [0.001, 0.01, 0.1]
  batch_size: [32, 64]
  optimizer: ["adam", "sgd"]
runner:
  type: local            # local|process|thread|ssh|k8s
  max_retries: 1
  timeout_sec: 1800
task:
  entrypoint: "scripts/train.py"
  args:
    epochs: 10
    dataset_path: "data/dataset.csv"
artifacts:
  dir: "outputs/${name}"
  save_stdout: true
  save_stderr: true
  save_metrics: "metrics.json"
```

**Environment (.env)**

```dotenv
# .env
ECP_LOG_LEVEL=INFO
ECP_MAX_WORKERS=4
# e.g., S3 or DB creds if used
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
```

> All config keys are documented in [`docs/config.md`](docs/config.md).
> Precedence: CLI flags > env vars > config file defaults.

---

## 🧰 Usage

### CLI

```bash
ecpsweep --help

Usage: ecpsweep [command] [options]

Commands:
  run            Run a sweep from a config file
  dry-run        Validate config and show planned runs
  resume         Resume a failed/interrupted sweep
  ls             List previous runs
  view           Show run details (summary/metrics)
  export         Export results to CSV/JSON/Parquet
  version        Show version

Options:
  -c, --config <path>          Path to YAML/JSON config
  -o, --out <dir>              Output directory
  -j, --concurrency <n>        Override concurrency
  --filter "key==val"          Filter matrix combinations
  --max-retries <n>            Retries per run (default: 0)
  --timeout <sec>              Per-run timeout
  -v, --verbose                Verbose logs
  -q, --quiet                  Minimal logs
```

**Common commands**

```bash
# Validate config without executing
ecpsweep dry-run --config config/sample.yaml

# Run and override a parameter on the fly
ecpsweep run -c config/sample.yaml --out outputs/aug1 --filter "optimizer==adam" -j 8

# Export a completed sweep to CSV
ecpsweep export --run outputs/aug1 --format csv > results.csv
```

### Library/API

<!-- Keep only the relevant language block. -->

**Python**

```python
from ecpsweep import Sweep, Export

sweep = Sweep.from_file("config/sample.yaml")
result = sweep.run()  # returns rich result model
Export.to_csv(result, "outputs/aug1.csv")
```

**Node (TypeScript)**

```ts
import { Sweep, exportCsv } from "ecpsweep";

const sweep = await Sweep.fromFile("config/sample.yaml");
const res = await sweep.run();
await exportCsv(res, "outputs/aug1.csv");
```

### Examples

* **Basic grid:** `examples/basic-grid/config.yaml`
* **Resume failed runs:** `examples/resume/`
* **Remote runner (SSH/K8s):** `examples/remote/`
* **Custom metrics hook:** `examples/hooks/metrics.py`

Run:

```bash
ecpsweep run -c examples/basic-grid/config.yaml -o outputs/basic
```

---

## 📁 Project Structure

```
ecpsweep/
├─ src/                       # library/cli source
│  └─ ecpsweep/
│     ├─ cli.py               # CLI entrypoint (Python) / cli.ts (Node)
│     ├─ core/                # orchestrator, scheduler, runners
│     ├─ io/                  # config parsing, export, storage
│     ├─ hooks/               # user extensibility
│     └─ __init__.py
├─ scripts/                   # example tasks/entrypoints
│  └─ train.py
├─ config/
│  └─ sample.yaml
├─ outputs/                   # default artifacts
├─ tests/
├─ pyproject.toml / package.json
├─ README.md
└─ LICENSE
```

> Adjust to your actual tree; this is a sane default.

---

## 📊 Output & Result Formats

Each run generates:

* **Run directory:** `outputs/<run-name>/<combination-id>/`
* **Logs:** `stdout.log`, `stderr.log`
* **Metrics:** `metrics.json` (schema below)
* **Artifacts:** any files created by the task (e.g., model weights, reports)

**`metrics.json` schema**

```json
{
  "status": "success|failed|timeout",
  "duration_sec": 123.4,
  "params": { "lr": 0.01, "batch_size": 32, "optimizer": "adam" },
  "metrics": { "loss": 0.123, "accuracy": 0.987 },
  "started_at": "2025-09-09T12:34:56Z",
  "finished_at": "2025-09-09T12:36:59Z",
  "host": "hostname",
  "notes": "optional"
}
```

---

## 🚀 Performance Tips

* Prefer **process** runner for CPU-bound tasks; **thread** for I/O-bound.
* Pin dependencies; run with `--concurrency` tuned to cores/I/O.
* Use **resume** to recover instead of restarting a whole sweep.
* For huge matrices, use `--filter` or **random/latin** sampling (<if supported>).
* Store outputs on a fast local disk, then sync to remote/S3.

---

## ✅ Testing

```bash
# Python
pytest -q

# Node
pnpm test
```

* Unit tests live in `tests/`.
* Add integration tests for runners and config parsing.
* For deterministic tests, set `seed` and mock time/FS as needed.

---

## 🛠 Troubleshooting

| Symptom                             | Likely Cause                  | Fix                                        |
| ----------------------------------- | ----------------------------- | ------------------------------------------ |
| “Permission denied” writing outputs | Missing write perms           | Set `--out` to a writable path             |
| Runs hang or time out               | Too low timeout / blocked I/O | Increase `--timeout`, inspect `stderr.log` |
| CPU under-utilized                  | Low concurrency               | Raise `-j/--concurrency`                   |
| Duplicate work after resume         | Changed `matrix` mid-run      | Keep config immutable; or use `resume`     |
| “Config key not found”              | Wrong schema                  | Validate with `dry-run` to see errors      |

> Logs: `outputs/<run>/ecpsweep.log`.
> Enable verbose mode with `-v`.

---

## 🤔 FAQ

**Q: Can I run only a subset of parameters?**
Yes, use `--filter "key==value"` or config `include/exclude` patterns.

**Q: How do I add custom metrics?**
Emit a `metrics.json` file from your task or register a hook in `hooks/metrics.*`.

**Q: Does it support remote execution?**
\<Answer: SSH, Kubernetes, Slurm, etc., if applicable.>

**Q: How do I integrate with dashboards?**
Export CSV/JSON and load into your BI tool, or enable the `<wandb/mlflow/opentelemetry>` plugin.

---

## 🗺 Roadmap

* [ ] \<Feature 1, e.g., Slurm runner>
* [ ] \<Feature 2, e.g., Web UI for live runs>
* [ ] \<Feature 3, e.g., Checkpoint deduplication>

See [`CHANGELOG.md`](CHANGELOG.md) for released changes.

---

## 🤝 Contributing

Contributions are welcome!

1. Fork and create a feature branch: `git checkout -b feat/<name>`
2. Add tests and docs for your changes
3. Run the linter/tests
4. Open a PR with a clear description & screenshots/logs

**Dev tooling**

```bash
# Python
ruff check . && ruff format .
pytest

# Node
pnpm lint
pnpm test
```

> See `CONTRIBUTING.md` for full guidelines and `CODE_OF_CONDUCT.md`.

---

## 🔐 Security

If you discover a vulnerability, **do not** open a public issue.
Email: `<security@yourdomain>` or follow `SECURITY.md`.

---

## 📄 License

`ecpsweep` is released under the **\<MIT/Apache-2.0/GPL-3.0>** license.
See [`LICENSE`](LICENSE) for details.

---

## 🙏 Acknowledgments

* \<People, labs, libraries, papers>
* \<Sponsors/Grants>

---

### Drop-in Snippets (optional)

**GitHub Actions CI (Python)** — `.github/workflows/ci.yml`

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -U pip
      - run: pip install -e .[dev] || pip install -r requirements.txt
      - run: pytest -q
```

**.gitignore (common)**

```
.venv/
node_modules/
__pycache__/
dist/
build/
outputs/
*.log
.env
```
