# OmniTerm

OmniTerm is a local-first coding agent that works with local language models and, eventually, user-supplied cloud API keys. The current release provides an Ollama chat command, workspace-restricted filesystem access, and approval-controlled terminal execution.

> **Development status:** This is an early command-line runtime. The desktop interface, BYOK provider settings, persistent terminal, and computer-control layer are still under development.

## Windows installation using WSL

This is the recommended setup for Windows. Git is **not** required in PowerShell because installation and execution happen inside WSL.

### 1. Confirm WSL is installed

Open PowerShell and run:

```powershell
wsl --status
```

If WSL is missing, open PowerShell as Administrator and run:

```powershell
wsl --install -d Ubuntu
```

Restart Windows if requested, then open Ubuntu once and create your Linux username and password.

### 2. Install OmniTerm inside WSL

Run this from PowerShell or Windows Terminal:

```powershell
wsl bash -lc "curl -fsSL https://raw.githubusercontent.com/benjaminbencsik/omniterm/main/scripts/install-wsl.sh | bash"
```

The installer uses Ubuntu's package manager to install Git, Python, and the required build tools **inside WSL**, clones OmniTerm to `~/omniterm`, creates a virtual environment, and installs the CLI.

### 3. Launch OmniTerm

From PowerShell:

```powershell
wsl bash -lc "source ~/.bashrc && omniterm --help"
```

Or enter WSL first:

```powershell
wsl
```

Then run:

```bash
omniterm --help
```

The repository also includes `omniterm-wsl.cmd`, a Windows launcher that forwards command-line arguments into WSL after OmniTerm has been installed.

Example:

```powershell
.\omniterm-wsl.cmd files --workspace /mnt/c/Users/YourName/Documents/project
```

## Ollama setup

Install Ollama on Windows and start it normally. Pull a coding model:

```powershell
ollama pull qwen2.5-coder:7b
```

Ollama normally listens on `http://127.0.0.1:11434`. Depending on your WSL networking configuration, WSL may be able to reach this address directly.

Test local chat from WSL:

```bash
omniterm chat "Write a Python hello world program"
```

Choose another model:

```bash
omniterm chat "Explain this architecture" --model qwen3-coder:latest
```

Set another Ollama endpoint:

```bash
omniterm chat "Hello" --base-url http://127.0.0.1:11434
```

## Filesystem tools

List files inside a selected workspace:

```bash
omniterm files --workspace ~/projects/example
```

The filesystem layer rejects paths that escape the selected workspace.

## Terminal tools

Run a recognized low-risk command:

```bash
omniterm run "git status" --workspace ~/projects/example
```

Commands that may modify state, install software, access the network, or start another shell require explicit approval:

```bash
omniterm run "git commit -am 'Update files'" --workspace ~/projects/example
```

After reviewing the exact command, approve it explicitly:

```bash
omniterm run "git commit -am 'Update files'" --workspace ~/projects/example --approve
```

Recognized destructive or privileged commands remain blocked even with `--approve`.

## Manual developer installation in WSL

```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pytest
omniterm --help
```

## Current project structure

```text
src/omniterm/       Python agent runtime
src/omniterm/tools/ Workspace filesystem and terminal tools
tests/              Runtime safety tests
scripts/             WSL installer
omniterm-wsl.cmd     Windows-to-WSL launcher
pyproject.toml       Python package configuration
```

## Planned architecture

- **Desktop application:** Tauri, React, and TypeScript
- **Agent runtime:** Python
- **Providers:** Ollama, OpenAI-compatible APIs, Anthropic, and Google
- **Terminal:** persistent pseudo-terminal sessions
- **Storage:** SQLite and operating-system credential storage
- **Automation:** Playwright first, structured desktop automation later

## Safety principles

OmniTerm operates inside a user-selected workspace by default. Destructive commands, privilege escalation, credential access, package installation, external application control, and Git pushes should require explicit approval.
