# OmniTerm

OmniTerm is an early local-first desktop coding agent for Ollama and other local models. It includes a Tauri desktop interface, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change a project or computer.

## Download the desktop application

OmniTerm now has an automated native build pipeline for Windows and macOS.

After a successful build, open the repository's **Releases** page and select **OmniTerm Desktop Preview**.

Download the package for your operating system:

- Windows: `*-setup.exe` is the recommended installer. An `.msi` may also be available.
- macOS: download the `.dmg`, open it, and move OmniTerm into Applications.

The source-code ZIP from the green **Code** button is not the application installer. Use the files attached to the Desktop Preview release instead.

Preview builds are currently unsigned. Windows SmartScreen may show a warning, and macOS may require Control-clicking OmniTerm and choosing **Open**.

## Automated installer builds

The workflow at `.github/workflows/desktop-build.yml` compiles OmniTerm on native GitHub-hosted systems:

- `windows-latest` produces the Windows setup executable and MSI.
- `macos-latest` produces the macOS DMG.
- Successful builds are published to the rolling `desktop-preview` prerelease.
- Version tags such as `v0.1.0` publish a versioned release.

A new build runs when changes are pushed to `main`, when a `v*` tag is pushed, or when the workflow is started manually.

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

Ollama remains separate because local model downloads can be several gigabytes.

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

Windows packages are written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
apps\desktop\src-tauri\target\release\bundle\msi\
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

Build output is written under:

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

## Repository structure

```text
apps/desktop/                    Tauri, React, and TypeScript desktop app
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and packaging
.github/workflows/desktop-build.yml  Native installer build and release workflow
src/omniterm/                    Python CLI runtime
src/omniterm/tools/              Python workspace and terminal tools
tests/                           Runtime safety tests
pyproject.toml                   Python package configuration
```

## Current limitations

- The first automated Windows and macOS packages still need a successful build validation.
- Builds are not code-signed or notarized.
- Chat does not yet autonomously invoke file or terminal tools.
- File editing and unified-diff approval are not implemented yet.
- Ollama must be installed separately.

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Validate and sign Windows installers
- Notarize macOS releases
- Let the chat agent request file and terminal tools
- Show proposed edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
- Add browser automation and structured desktop control
