# OmniTerm

OmniTerm is an early Windows desktop coding agent for Ollama. It includes a native desktop interface, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change a project or computer.

## Windows only for now

The current goal is to get one Windows build working reliably before adding macOS support.

There is one supported installer format:

```text
OmniTerm_*_x64-setup.exe
```

Do not use the green **Code → Download ZIP** button when you only want to install the application. That ZIP contains source code, not the finished Windows app.

## Install OmniTerm on Windows

### 1. Download the installer

1. Open this repository's **Releases** section.
2. Open **OmniTerm Windows Preview**.
3. Under **Assets**, download the file ending in:

```text
-setup.exe
```

If no `-setup.exe` file is listed, the Windows build has not completed successfully yet. There is nothing installable to download until that file appears.

### 2. Install it

1. Double-click the downloaded `-setup.exe` file.
2. Complete the setup wizard.
3. Launch **OmniTerm** from the Windows Start menu.

The preview installer is unsigned. Windows SmartScreen may display a warning. Only continue when the installer came from this repository's Releases section.

## Set up Ollama

OmniTerm currently uses Ollama for local models. Ollama is installed separately.

1. Install Ollama for Windows.
2. Start Ollama.
3. Open PowerShell and pull the default coding model:

```powershell
ollama pull qwen2.5-coder:7b
```

4. Confirm Ollama is running:

```powershell
ollama list
```

## Use OmniTerm

1. Open OmniTerm from the Start menu.
2. Leave these defaults unless your Ollama setup is different:

```text
Provider: Ollama
Model: qwen2.5-coder:7b
Endpoint: http://127.0.0.1:11434
```

3. Select **Choose workspace**.
4. Choose a project folder.
5. Enter a prompt in the chat box and select **Send**.
6. Select files in the workspace browser to preview them.
7. Use the terminal panel for workspace commands.

Recognized read-only commands can run automatically. Unknown or state-changing commands appear in the **Approvals** panel with **Cancel** and **Allow once** controls. Recognized destructive and privileged commands are blocked.

## First test

After installing Ollama and OmniTerm, try:

```text
Write a short Python hello-world program and explain each line.
```

A successful response confirms that OmniTerm can connect to the local Ollama service.

## What currently works

- Native Windows desktop application
- Ollama chat through the Rust backend
- Configurable Ollama model and endpoint
- Native workspace-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- One-time approval prompts for state-changing commands
- Blocking for recognized destructive and privileged commands

## Current limitations

- The Windows installer still needs a successful build and real-machine validation.
- The installer is not code-signed.
- Chat does not yet autonomously invoke file or terminal tools.
- File editing and unified-diff approval are not implemented yet.
- Ollama must be installed separately.
- macOS support is paused until the Windows application is validated.

## Windows build pipeline

The workflow at:

```text
.github/workflows/desktop-build.yml
```

builds one Windows NSIS setup executable on `windows-latest` and publishes it to the rolling **OmniTerm Windows Preview** release.

The expected release asset path is:

```text
apps/desktop/src-tauri/target/release/bundle/nsis/*-setup.exe
```

## Build from source

This section is for developers only.

Requirements:

- Windows 10 or 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime

```powershell
git clone https://github.com/benjaminbencsik/omniterm.git
cd omniterm\apps\desktop
npm install
npm run tauri build
```

The Windows setup executable is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

## Repository structure

```text
apps/desktop/                         Tauri, React, and TypeScript desktop app
apps/desktop/src/                     Desktop interface
apps/desktop/src-tauri/               Native Rust backend and Windows packaging
.github/workflows/desktop-build.yml   Windows installer build and release workflow
src/omniterm/                         Python CLI runtime
tests/                                Runtime safety tests
```

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Produce and validate the first Windows installer
- Test installation and launch on a clean Windows system
- Let the chat agent request file and terminal tools
- Show proposed edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
- Revisit macOS after Windows is stable
