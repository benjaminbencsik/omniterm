# OmniTerm

OmniTerm is a local-first desktop coding agent for local models. It provides Ollama chat, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change your project or computer.

> **Early preview:** OmniTerm is usable as a desktop application, but it is not code-signed, chat does not yet invoke tools autonomously, and Ollama must be installed separately.

## Quick start on your desktop

A GitHub source ZIP cannot include a newly compiled Windows `.exe` or macOS `.app`. The first launch builds OmniTerm on your computer. Later launches reuse that build and open the application directly.

### Windows

1. Select **Code → Download ZIP** on this repository.
2. Extract `omniterm-main.zip`.
3. Install the prerequisites listed below once.
4. Double-click:

```text
RUN-WINDOWS.cmd
```

On the first run, the launcher installs JavaScript dependencies, builds OmniTerm, and opens the desktop application. Later, double-clicking `RUN-WINDOWS.cmd` launches the existing build without rebuilding it.

To create a normal Windows installer instead, double-click:

```text
BUILD-WINDOWS.cmd
```

Generated installers are placed under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
apps\desktop\src-tauri\target\release\bundle\msi\
```

### macOS

1. Select **Code → Download ZIP**.
2. Extract the ZIP.
3. Install the prerequisites listed below once.
4. Open:

```text
RUN-MACOS.command
```

The first run builds OmniTerm and opens the generated application. Later launches reuse the existing build.

To build a DMG installer, open:

```text
BUILD-MACOS.command
```

Generated packages are placed under:

```text
apps/desktop/src-tauri/target/release/bundle/dmg/
apps/desktop/src-tauri/target/release/bundle/macos/
```

Because files downloaded in a ZIP may lose executable permissions, macOS may require this once from Terminal inside the extracted folder:

```bash
chmod +x RUN-MACOS.command BUILD-MACOS.command scripts/*.sh
```

Preview macOS builds are not signed or notarized, so Control-click **OmniTerm**, choose **Open**, and confirm when macOS blocks the first launch.

## First-time prerequisites

These tools are required only because the source ZIP must build the native desktop application locally. Once OmniTerm is built, opening the existing application does not require running setup commands again.

### Windows prerequisites

Install Node.js LTS:

```powershell
winget install OpenJS.NodeJS.LTS
```

Install Rust:

```powershell
winget install Rustlang.Rustup
```

Install **Microsoft Visual Studio Build Tools** with the **Desktop development with C++** workload. Tauri also requires Microsoft Edge WebView2, which is already present on most supported Windows systems.

Restart Windows, or at least reopen your terminal session, after installing these tools.

### macOS prerequisites

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

Using Homebrew, install Node.js:

```bash
brew install node
```

Install Rust:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Ollama setup

Install and start Ollama separately, then pull a coding model:

```text
ollama pull qwen2.5-coder:7b
```

OmniTerm defaults to:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

Change the model field in OmniTerm when using another installed Ollama model.

## What currently works

- Native Windows and macOS desktop application
- Ollama chat through the native Rust backend
- Configurable Ollama model and endpoint
- Native project-folder picker
- Recursive workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- Automatic execution for recognized low-risk, read-only commands
- **Allow once** approval for unknown or state-changing commands
- Blocking for recognized privileged or destructive commands
- Local Windows installer and macOS DMG creation

## Using OmniTerm

Select **Choose workspace** and pick a project folder. OmniTerm lists files while skipping common internal directories such as `.git`, `node_modules`, `.venv`, and Rust `target` folders.

Select a text file to preview it. Commands run from the selected workspace. Read-only commands may run automatically; unknown or state-changing commands appear in the **Approvals** panel with **Cancel** and **Allow once** controls.

Examples of low-risk commands include:

```text
git status
git diff
git log
ls
dir
pwd
```

## Developer mode

Developers can launch the application without creating an installer:

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm/apps/desktop
npm install
npm run tauri dev
```

Build the release application manually:

```bash
npm run tauri build
```

## Command-line runtime

The original Python CLI remains available for development and testing. The desktop application does not require this Python environment.

```bash
python -m venv .venv
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
omniterm --help
```

## Repository structure

```text
RUN-WINDOWS.cmd                  Build when needed and launch on Windows
BUILD-WINDOWS.cmd                Create Windows setup installers
RUN-MACOS.command                Build when needed and launch on macOS
BUILD-MACOS.command              Create a macOS application and DMG
apps/desktop/                    Tauri, React, and TypeScript application
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and packaging
scripts/run-windows.ps1          Windows build-and-launch implementation
scripts/build-windows.ps1        Windows installer build implementation
scripts/run-macos.sh             macOS build-and-launch implementation
scripts/build-macos.sh           macOS package build implementation
src/omniterm/                    Python CLI runtime
tests/                           Python runtime safety tests
```

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands may run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Allow the chat agent to request file and terminal tools
- Show proposed file edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
- Add signed Windows installers and notarized macOS releases
- Add browser automation and structured desktop control
