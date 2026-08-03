# OmniTerm

OmniTerm is a local-first desktop coding agent for local models. It provides Ollama chat, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change your project or computer.

> **Early preview:** OmniTerm is usable as a desktop application, but it is not code-signed, chat does not yet invoke tools autonomously, and Ollama must be installed separately.

## Quick start

There is now only **one launcher per operating system**:

- Windows: `RUN-WINDOWS.cmd`
- macOS: `RUN-MACOS.command`

Each launcher builds OmniTerm when needed and then opens the desktop application. Separate `BUILD-*` launchers are no longer necessary.

## Windows

### 1. Download OmniTerm

1. Select **Code → Download ZIP**.
2. Extract `omniterm-main.zip`.

### 2. Install prerequisites once

Install Node.js LTS:

```powershell
winget install OpenJS.NodeJS.LTS
```

Install Rust:

```powershell
winget install Rustlang.Rustup
```

Install Microsoft Visual Studio Build Tools with the **Desktop development with C++** workload. Microsoft Edge WebView2 is also required and is already installed on most current Windows systems.

Restart Windows or reopen your terminal after installing these tools.

### 3. Launch OmniTerm

Double-click:

```text
RUN-WINDOWS.cmd
```

On the first run, the launcher installs the frontend dependencies, builds OmniTerm locally, and opens it. Later launches reuse the existing build and open the application directly.

The compiled application is stored under:

```text
apps\desktop\src-tauri\target\release\
```

Tauri may also create installer packages under:

```text
apps\desktop\src-tauri\target\release\bundle\
```

You do not need to use those installer files to run OmniTerm from the extracted folder.

## macOS

### 1. Download OmniTerm

1. Select **Code → Download ZIP**.
2. Extract the ZIP.

### 2. Install prerequisites once

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

With Homebrew, install Node.js:

```bash
brew install node
```

Install Rust:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 3. Launch OmniTerm

Open:

```text
RUN-MACOS.command
```

The first run builds the app and opens it. Later launches reuse the existing application bundle.

If macOS removes executable permissions from the downloaded script, run this once inside the extracted folder:

```bash
chmod +x RUN-MACOS.command scripts/run-macos.sh
```

The compiled app is stored under:

```text
apps/desktop/src-tauri/target/release/bundle/macos/
```

Preview builds are not signed or notarized. Control-click OmniTerm, choose **Open**, and confirm if macOS blocks the first launch.

## First launch setup

Install Ollama separately, start it, and pull a coding model:

```text
ollama pull qwen2.5-coder:7b
```

Default settings:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

Select **Choose workspace** and pick a project directory. OmniTerm lists files while skipping folders such as `.git`, `node_modules`, `.venv`, and Rust `target` directories.

Commands run inside the selected workspace. Recognized read-only commands can run automatically. Unknown or state-changing commands appear in the **Approvals** panel with **Cancel** and **Allow once** controls. Recognized destructive or privileged commands are blocked.

## What currently works

- Native Windows and macOS desktop application
- Ollama chat through the Rust backend
- Configurable Ollama model and endpoint
- Native project-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- One-time command approvals
- Blocking for recognized destructive and privileged commands

## Developer launch

Developers can run the desktop application directly:

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm/apps/desktop
npm install
npm run tauri dev
```

Create a release build manually:

```bash
npm run tauri build
```

## Repository structure

```text
RUN-WINDOWS.cmd                 Windows build-and-launch shortcut
RUN-MACOS.command               macOS build-and-launch shortcut
apps/desktop/                   Tauri, React, and TypeScript desktop app
apps/desktop/src/               Desktop interface
apps/desktop/src-tauri/         Native Rust backend and packaging
scripts/run-windows.ps1         Windows launcher implementation
scripts/run-macos.sh            macOS launcher implementation
src/omniterm/                   Python CLI runtime
tests/                          Python runtime safety tests
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
