# OmniTerm

OmniTerm is a local-first desktop coding agent for local models. It provides Ollama chat, a workspace file browser, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change your project or system.

> **Status:** Early preview. The desktop application is usable, but installers are unsigned and the agent does not yet autonomously choose filesystem or terminal tools from chat.

## Run OmniTerm on your own desktop

The source ZIP does not already contain a compiled `.exe` or `.app`. It must be built once on the computer where you want to run it. After that build finishes, you can install and launch OmniTerm like a normal desktop application.

GitHub Actions is optional and is not required for local use.

## Windows local desktop build

### 1. Download the source ZIP

1. Open this repository.
2. Select **Code → Download ZIP**.
3. Extract `omniterm-main.zip`.

### 2. Install the Windows build prerequisites once

Install Node.js LTS:

```powershell
winget install OpenJS.NodeJS.LTS
```

Install Rust:

```powershell
winget install Rustlang.Rustup
```

Install Microsoft Visual Studio Build Tools with the **Desktop development with C++** workload. Tauri also uses Microsoft Edge WebView2, which is already included on most current Windows systems.

Restart Windows or reopen your terminal after installing the prerequisites.

### 3. Build by double-clicking

Inside the extracted OmniTerm folder, double-click:

```text
BUILD-WINDOWS.cmd
```

The script installs the project dependencies and builds the Windows application locally.

When it finishes, the installer is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

You may also find an MSI under:

```text
apps\desktop\src-tauri\target\release\bundle\msi\
```

Double-click the generated setup `.exe` or `.msi`, then launch OmniTerm from the Start menu.

Because the preview installer is not code-signed, Windows SmartScreen may display a warning.

## macOS local desktop build

### 1. Download and extract the source ZIP

Download **Code → Download ZIP**, then extract it.

### 2. Install the macOS build prerequisites once

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

Install Node.js LTS and Rust. With Homebrew:

```bash
brew install node
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 3. Build the app

Double-click:

```text
BUILD-MACOS.command
```

If macOS blocks the script, Control-click it, choose **Open**, and confirm.

The build produces a DMG under:

```text
apps/desktop/src-tauri/target/release/bundle/dmg/
```

It may also produce an app bundle under:

```text
apps/desktop/src-tauri/target/release/bundle/macos/
```

Open the DMG, drag OmniTerm into **Applications**, and launch it normally.

Preview macOS builds are not signed or notarized yet.

## What currently works

- Native Windows and macOS desktop window
- Ollama chat through the native Rust backend
- Configurable Ollama model and endpoint
- Native project-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- Automatic execution for recognized low-risk read-only commands
- **Allow once** confirmation for unknown or state-changing commands
- Blocking for recognized privileged or destructive commands

## First launch

Install Ollama separately, start it, and pull a coding model:

```text
ollama pull qwen2.5-coder:7b
```

The default settings are:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

Select **Choose workspace** and pick a project directory. OmniTerm lists files while skipping folders such as `.git`, `node_modules`, `.venv`, and Rust `target` directories.

Select a text file to preview it. Commands run from the selected workspace. Read-only commands can run automatically; unknown or state-changing commands are shown in the **Approvals** panel with **Cancel** and **Allow once** controls.

## Developer launch without creating an installer

For contributors who already have Node.js, Rust, and the Tauri prerequisites installed:

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm/apps/desktop
npm install
npm run tauri dev
```

Create a local installer manually:

```bash
npm run tauri build
```

## Command-line runtime

The original Python CLI remains available for development and testing, but the desktop application does not require Python.

```bash
python -m venv .venv
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
omniterm --help
```

## Repository structure

```text
BUILD-WINDOWS.cmd                Double-click Windows local build launcher
BUILD-MACOS.command              Double-click macOS local build launcher
apps/desktop/                    Tauri, React, and TypeScript desktop app
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and packaging
scripts/build-windows.ps1        Windows local build implementation
scripts/build-macos.sh           macOS local build implementation
src/omniterm/                    Python CLI runtime
tests/                           Python runtime safety tests
```

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Let the chat agent request file and terminal tools
- Show proposed file edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
- Add signed Windows installers and notarized macOS releases
- Add browser automation and structured desktop control
