# OmniTerm

OmniTerm is a local-first desktop coding agent for local models. It provides Ollama chat, a workspace file browser, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change your project or system.

> **Status:** Early preview. The desktop application is usable, but installers are currently unsigned and the agent does not yet autonomously choose filesystem or terminal tools from chat.

## Download the desktop application

You do not need Python, Node.js, Rust, Git, PowerShell, or WSL to use a packaged build.

### Windows

1. Open the repository's **Actions** page.
2. Open the newest successful **Desktop builds** run.
3. Download the `OmniTerm-Windows` artifact ZIP.
4. Extract the ZIP.
5. Double-click the included `*-setup.exe` or `.msi` installer.
6. Launch OmniTerm from the Start menu.

Because preview installers are not code-signed yet, Windows SmartScreen may show a warning. Review the publisher information and use **More info → Run anyway** only when you downloaded it from this repository.

### macOS

1. Open the repository's **Actions** page.
2. Open the newest successful **Desktop builds** run.
3. Download the `OmniTerm-macOS` artifact ZIP.
4. Extract and open the `.dmg`.
5. Drag OmniTerm into **Applications**.
6. Launch OmniTerm from Applications.

Preview macOS builds are not notarized yet. macOS may require Control-clicking the app, choosing **Open**, and confirming the prompt.

Tagged versions such as `v0.1.0` also create a draft GitHub Release containing the platform installers.

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
- Automatic Windows installer and macOS DMG builds through GitHub Actions

## First launch

### 1. Install Ollama

Install Ollama for your operating system, start it, and pull a coding model:

```text
ollama pull qwen2.5-coder:7b
```

Ollama is separate from OmniTerm because model files can be several gigabytes and users may already have their preferred local models installed.

### 2. Open OmniTerm

The default settings are:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

Change the model field when using another installed Ollama model.

### 3. Choose a workspace

Select **Choose workspace** and pick a project directory. OmniTerm will list files while skipping common large internal folders such as `.git`, `node_modules`, `.venv`, and Rust `target` directories.

Select a text file to preview it. Canonical path checks prevent previews from escaping the selected workspace through `..` paths or symbolic links.

### 4. Use the terminal

Enter a command in the terminal panel. Examples of recognized read-only commands include:

```text
git status
git diff
git log
ls
dir
pwd
```

A command such as a package installation, Git commit, or other state-changing operation is paused and shown in the **Approvals** panel. Choose **Allow once** to execute that exact command or **Cancel** to discard it.

Recognized destructive or privileged commands are denied rather than offered for approval.

## Build from source

End users should use the packaged installers above. These commands are only for contributors.

Requirements:

- Node.js 20 or newer
- Rust stable toolchain
- Tauri operating-system prerequisites

```bash
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm/apps/desktop
npm install
npm run tauri dev
```

Create an installer locally:

```bash
npm run tauri build
```

Build output is written under:

```text
apps/desktop/src-tauri/target/release/bundle/
```

## Command-line runtime

The original Python CLI remains in the repository for development and testing. It requires Python 3.11 or newer:

```bash
python -m venv .venv
```

Activate the environment and install:

```bash
python -m pip install --upgrade pip
pip install -e ".[dev]"
pytest
omniterm --help
```

The desktop application does not require this Python environment.

## Repository structure

```text
apps/desktop/                    Tauri, React, and TypeScript desktop app
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and packaging
.github/workflows/               Windows and macOS build automation
src/omniterm/                    Python CLI runtime
src/omniterm/tools/              Python workspace and terminal tools
tests/                           Python runtime safety tests
scripts/                         WSL helper installer
pyproject.toml                   Python package configuration
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
