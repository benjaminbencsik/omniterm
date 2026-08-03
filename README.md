# OmniTerm

OmniTerm is a local-first coding agent that works with local language models and, eventually, user-supplied cloud API keys. The current release provides an Ollama chat command, workspace-restricted filesystem access, and approval-controlled terminal execution.

> **Development status:** This is an early command-line runtime. The desktop interface, BYOK provider settings, persistent terminal, and computer-control layer are still under development.

## Choose an installation method

- **Windows with WSL:** recommended for the current release
- **Windows without WSL:** runs directly in PowerShell using Python
- **Linux or macOS:** standard Git and Python installation

## Standard installation with Git clone

Requirements:

- Git
- Python 3.11 or newer
- Ollama, when using a local model

Clone and install:

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm
python -m venv .venv
```

Activate the virtual environment.

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

Windows Command Prompt:

```bat
.venv\Scripts\activate.bat
```

Linux, macOS, or WSL:

```bash
source .venv/bin/activate
```

Install OmniTerm:

```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
omniterm --help
```

Run the tests:

```bash
pytest
```

## Windows installation without WSL

OmniTerm can run directly in Windows PowerShell. You need Python 3.11 or newer. Git is optional because you can either clone the repository or download a ZIP file.

### Option A: Install Git and clone the repository

Install Git for Windows using either method below.

Using Windows Package Manager:

```powershell
winget install --id Git.Git -e
```

Or download Git for Windows from its official installer page, then reopen PowerShell after installation.

Verify Git and Python:

```powershell
git --version
python --version
```

Clone and install OmniTerm:

```powershell
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -e ".[dev]"
omniterm --help
```

### Option B: Download OmniTerm without Git

1. Open the OmniTerm repository in a web browser.
2. Select **Code**.
3. Select **Download ZIP**.
4. Extract the ZIP file, usually named `omniterm-main.zip`.
5. Open PowerShell inside the extracted `omniterm-main` folder.

Then install:

```powershell
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -e ".[dev]"
omniterm --help
```

If the `python` command is unavailable, install Python with Windows Package Manager:

```powershell
winget install --id Python.Python.3.12 -e
```

Reopen PowerShell after installation and verify it:

```powershell
python --version
```

### Launching OmniTerm later on Windows

Open PowerShell in the OmniTerm folder and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
omniterm --help
```

## Windows installation using WSL

This is the recommended setup for Windows. Git is not required in PowerShell because installation and execution happen inside WSL.

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

### 2. Install OmniTerm inside WSL automatically

Run this from PowerShell or Windows Terminal:

```powershell
wsl bash -lc "curl -fsSL https://raw.githubusercontent.com/benjaminbencsik/omniterm/main/scripts/install-wsl.sh | bash"
```

The installer installs Git, Python, and required build tools inside WSL, clones OmniTerm to `~/omniterm`, creates a virtual environment, and installs the CLI.

### 3. Install manually with Git clone inside WSL

Enter WSL:

```powershell
wsl
```

Then run:

```bash
sudo apt update
sudo apt install -y git python3 python3-venv python3-pip
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
omniterm --help
```

### 4. Launch OmniTerm through WSL

From PowerShell:

```powershell
wsl bash -lc "source ~/omniterm/.venv/bin/activate && omniterm --help"
```

The repository also includes `omniterm-wsl.cmd`, a Windows launcher that forwards command-line arguments into WSL after OmniTerm has been installed.

Example:

```powershell
.\omniterm-wsl.cmd files --workspace /mnt/c/Users/YourName/Documents/project
```

## Ollama setup

Install Ollama and pull a coding model:

```powershell
ollama pull qwen2.5-coder:7b
```

Test local chat:

```powershell
omniterm chat "Write a Python hello world program"
```

Choose another model:

```powershell
omniterm chat "Explain this architecture" --model qwen3-coder:latest
```

Set another Ollama endpoint:

```powershell
omniterm chat "Hello" --base-url http://127.0.0.1:11434
```

## Filesystem tools

List files inside a selected workspace:

```powershell
omniterm files --workspace C:\Users\YourName\Documents\project
```

Inside Linux, macOS, or WSL:

```bash
omniterm files --workspace ~/projects/example
```

The filesystem layer rejects paths that escape the selected workspace.

## Terminal tools

Run a recognized low-risk command:

```powershell
omniterm run "git status" --workspace C:\Users\YourName\Documents\project
```

Commands that may modify state, install software, access the network, or start another shell require explicit approval:

```powershell
omniterm run "git commit -am 'Update files'" --workspace C:\Users\YourName\Documents\project
```

After reviewing the exact command, approve it explicitly:

```powershell
omniterm run "git commit -am 'Update files'" --workspace C:\Users\YourName\Documents\project --approve
```

Recognized destructive or privileged commands remain blocked even with `--approve`.

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
