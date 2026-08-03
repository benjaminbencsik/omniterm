# OmniTerm

OmniTerm is an early local-first desktop coding agent for Ollama and other local models. The repository currently contains the application source code, including a Tauri desktop interface, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change a project or computer.

## Important: no prebuilt installer is currently included

The repository ZIP is **source code only**. It does not currently contain:

- a Windows `.exe` or `.msi` installer
- a portable Windows executable
- a macOS `.dmg` or ready-to-run `.app`

A `.cmd`, PowerShell, or shell script is not the finished desktop application. The earlier launcher scripts have been removed to avoid that confusion.

A real Windows executable must be compiled on a Windows machine with the required Tauri toolchain, or uploaded as a compiled release asset after a successful build. A real macOS application must be compiled on macOS.

## Current desktop features

- Native Tauri desktop interface
- Ollama chat through the Rust backend
- Configurable Ollama model and endpoint
- Native workspace-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- One-time approval prompts for state-changing commands
- Blocking for recognized destructive and privileged commands

## Build the Windows application from source

Requirements:

- Windows 10 or 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime

From PowerShell:

```powershell
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm\apps\desktop
npm install
npm run tauri build
```

After a successful build, Windows packages are normally written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
apps\desktop\src-tauri\target\release\bundle\msi\
```

The uninstalled executable is normally written under:

```text
apps\desktop\src-tauri\target\release\
```

## Build the macOS application from source

Requirements:

- macOS
- Xcode Command Line Tools
- Node.js 20 or newer
- Rust stable toolchain

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm/apps/desktop
npm install
npm run tauri build
```

Build output is normally written under:

```text
apps/desktop/src-tauri/target/release/bundle/dmg/
apps/desktop/src-tauri/target/release/bundle/macos/
```

## Development mode

Run the desktop application without creating an installer:

```bash
cd apps/desktop
npm install
npm run tauri dev
```

## Ollama setup

Install and start Ollama separately, then pull a coding model:

```text
ollama pull qwen2.5-coder:7b
```

Default OmniTerm settings:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

## Repository structure

```text
apps/desktop/                    Tauri, React, and TypeScript desktop app
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and packaging
src/omniterm/                    Python CLI runtime
src/omniterm/tools/              Python workspace and terminal tools
tests/                           Runtime safety tests
pyproject.toml                   Python package configuration
```

## Current limitations

- No prebuilt Windows or macOS installer is checked into the repository.
- Chat does not yet autonomously invoke file or terminal tools.
- File editing and unified-diff approval are not implemented yet.
- Builds are not code-signed or notarized.
- Ollama must be installed separately.

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Publish a real Windows installer and macOS application package
- Let the chat agent request file and terminal tools
- Show proposed edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
- Add browser automation and structured desktop control
