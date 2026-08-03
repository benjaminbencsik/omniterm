# OmniTerm

OmniTerm is a local-first coding agent for local models and bring-your-own API providers. The project now includes a Tauri desktop application for Windows and macOS alongside the original Python CLI runtime.

> **Development status:** The desktop app currently provides Ollama chat, model and endpoint settings, a native workspace picker, and prepared terminal and approval panels. Filesystem and terminal execution are still being connected to the GUI.

## Recommended installation: desktop app

End users should not need Python, Node.js, Rust, Git, WSL, or terminal commands.

### Windows

1. Open the repository's **Releases** page.
2. Download the Windows setup executable or MSI.
3. Double-click the installer.
4. Open OmniTerm from the Start menu or desktop shortcut.

For development builds, open the latest **Desktop builds** GitHub Actions run, download `OmniTerm-Windows`, extract the ZIP, and double-click the included installer.

### macOS

1. Open the repository's **Releases** page.
2. Download the OmniTerm DMG.
3. Open the DMG and drag OmniTerm into Applications.
4. Launch OmniTerm from Applications.

For development builds, open the latest **Desktop builds** GitHub Actions run and download `OmniTerm-macOS`.

Unsigned development builds may show Windows SmartScreen or macOS Gatekeeper warnings. Public production releases should be code-signed and macOS builds should be notarized.

## Ollama setup

The first desktop milestone uses Ollama for local models. Install and start Ollama, then pull a coding model:

```powershell
ollama pull qwen2.5-coder:7b
```

Launch OmniTerm, leave the endpoint as `http://127.0.0.1:11434`, and select the installed model.

## Desktop features

- Native Windows and macOS application
- Ollama chat through the Rust backend
- Configurable model and endpoint
- Native project-folder picker
- Chat history and connection status
- Prepared terminal, approval, and safety panels
- Automated Windows and macOS installer builds

Desktop contributor instructions are in [`apps/desktop/README.md`](apps/desktop/README.md).

## CLI installation with Git

The Python CLI remains available for developers and advanced users.

Requirements:

- Git
- Python 3.11 or newer
- Ollama for local chat

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm
python -m venv .venv
```

Activate the environment.

Windows PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Linux, macOS, or WSL:

```bash
source .venv/bin/activate
```

Install and test:

```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
omniterm --help
```

## CLI installation without Git

1. Select **Code** on GitHub.
2. Select **Download ZIP**.
3. Extract the ZIP.
4. Open a terminal in the extracted folder.
5. Create the virtual environment and install as shown above.

## WSL CLI installer

Windows users can install the CLI inside WSL without Git in PowerShell:

```powershell
wsl bash -lc "curl -fsSL https://raw.githubusercontent.com/benjaminbencsik/omniterm/main/scripts/install-wsl.sh | bash"
```

Launch it later with:

```powershell
wsl bash -lc "source ~/omniterm/.venv/bin/activate && omniterm --help"
```

## CLI usage

Chat with Ollama:

```bash
omniterm chat "Write a Python hello world program"
```

List files inside a selected workspace:

```bash
omniterm files --workspace /path/to/project
```

Run a recognized low-risk command:

```bash
omniterm run "git status" --workspace /path/to/project
```

State-changing commands require explicit approval:

```bash
omniterm run "git commit -am 'Update files'" --workspace /path/to/project --approve
```

Recognized destructive or privileged commands remain blocked even with `--approve`.

## Project structure

```text
apps/desktop/        Tauri, React, and TypeScript desktop application
src/omniterm/        Python agent and CLI runtime
src/omniterm/tools/  Workspace filesystem and terminal tools
tests/               Runtime safety tests
scripts/             WSL installer
.github/workflows/   Automated desktop builds
```

## Planned work

- Connect GUI approvals to the existing Python safety policy
- Add integrated terminal sessions and file editing
- Bundle the agent runtime with installers
- Add OpenAI-compatible, Anthropic, Google, and custom providers
- Store API keys in operating-system credential storage
- Add browser and permission-controlled desktop automation

## Safety principles

OmniTerm operates inside a user-selected workspace by default. Destructive commands, privilege escalation, credential access, package installation, external application control, and Git pushes should require explicit approval.
