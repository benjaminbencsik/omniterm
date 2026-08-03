# OmniTerm

OmniTerm is a local-first desktop coding agent for local models. It provides Ollama chat, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change your project or computer.

> **Early preview:** OmniTerm is usable as a desktop application, but it is not code-signed, chat does not yet invoke tools autonomously, and Ollama must be installed separately.

## Quick start

There is one launcher per operating system:

- Windows: `RUN-WINDOWS.cmd`
- macOS: `RUN-MACOS.command`

Each launcher builds OmniTerm when needed and then opens the desktop application.

## Windows

### 1. Download OmniTerm

1. Select **Code → Download ZIP**.
2. Extract `omniterm-main.zip`.
3. Double-click `RUN-WINDOWS.cmd`.

### Automatic prerequisite setup

The Windows launcher now detects and installs missing build prerequisites automatically using Windows Package Manager (`winget`):

- Node.js LTS
- Rust stable toolchain
- Microsoft Visual Studio C++ Build Tools
- Microsoft Edge WebView2 Runtime

Windows may show an administrator approval prompt while installing Microsoft components. Accept it to continue.

The only required Windows component that the launcher cannot install by itself is Windows Package Manager. If the launcher reports that `winget` is missing, install **App Installer** from the Microsoft Store and run `RUN-WINDOWS.cmd` again.

### First and later launches

On the first successful run, the launcher:

1. Installs missing prerequisites.
2. Refreshes the command environment.
3. Installs OmniTerm frontend dependencies.
4. Builds the native desktop application.
5. Opens OmniTerm.

Later launches reuse the existing build and open OmniTerm directly.

A diagnostic log is saved as:

```text
omniterm-launch.log
```

If startup fails, the command window remains open and displays the error. The same details are preserved in the log file.

The compiled application is stored under:

```text
apps\desktop\src-tauri\target\release\
```

## macOS

### 1. Download OmniTerm

1. Select **Code → Download ZIP**.
2. Extract the ZIP.
3. Install the prerequisites below once.
4. Open `RUN-MACOS.command`.

### macOS prerequisites

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
- Automatic Windows build-prerequisite installation
- Persistent Windows startup diagnostics

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
RUN-WINDOWS.cmd                 Windows bootstrap and launch shortcut
RUN-MACOS.command               macOS build-and-launch shortcut
apps/desktop/                   Tauri, React, and TypeScript desktop app
apps/desktop/src/               Desktop interface
apps/desktop/src-tauri/         Native Rust backend and packaging
scripts/run-windows.ps1         Windows prerequisite, build, and launch logic
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
