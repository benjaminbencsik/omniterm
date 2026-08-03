# OmniTerm

OmniTerm is an early native Windows desktop coding agent for Ollama. It includes a Tauri desktop interface, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change a project or computer.

## Project status

OmniTerm is currently focused on Windows only.

The repository contains source code. There is not yet a validated prebuilt Windows installer attached to the repository. The green **Code → Download ZIP** button downloads the source code, not a finished application.

GitHub Actions, macOS packaging, WSL launchers, and WSL installers have been removed while the native Windows application is being validated.

## Run OmniTerm on Windows from source

### Requirements

Install these once:

- Windows 10 or Windows 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime
- Ollama for Windows

### Start Ollama

Open PowerShell and install the default model:

```powershell
ollama pull qwen2.5-coder:7b
```

Confirm Ollama is available:

```powershell
ollama list
```

### Start OmniTerm in development mode

Open PowerShell in the repository folder and run:

```powershell
cd apps\desktop
npm install
npm run tauri dev
```

This opens the actual native OmniTerm desktop window. Keep the PowerShell window open while development mode is running.

## Build the Windows setup executable

From `apps\desktop`, run:

```powershell
npm run tauri build
```

The configured Windows package type is NSIS. After a successful build, the real setup executable is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

The filename should end in:

```text
-setup.exe
```

That generated `.exe` is the installer. Batch files, PowerShell files, source ZIPs, and repository scripts are not the finished application.

The build has not yet been validated on a clean Windows machine, so do not assume an installer exists until `npm run tauri build` completes successfully and the file appears in the NSIS folder.

## Use OmniTerm

After launching the desktop window:

1. Leave the Ollama endpoint as `http://127.0.0.1:11434` unless your setup is different.
2. Leave the model as `qwen2.5-coder:7b`, or enter another model already installed in Ollama.
3. Select **Choose workspace** and choose a project folder.
4. Enter a prompt and select **Send**.
5. Select files in the workspace browser to preview them.
6. Use the terminal panel for workspace commands.

Recognized read-only commands can run automatically. Unknown or state-changing commands appear in the **Approvals** panel with **Cancel** and **Allow once** controls. Recognized destructive and privileged commands are blocked.

## First test

Try this prompt:

```text
Write a short Python hello-world program and explain each line.
```

A successful response confirms that OmniTerm can connect to the local Ollama service.

## What currently works

- Native Windows desktop interface
- Ollama chat through the Rust backend
- Configurable Ollama model and endpoint
- Native workspace-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Workspace-scoped terminal commands
- One-time approval prompts for state-changing commands
- Blocking for recognized destructive and privileged commands

## Current limitations

- The Windows installer still needs a successful local build and clean-machine validation.
- The installer is not code-signed.
- Chat does not yet autonomously invoke file or terminal tools.
- File editing and unified-diff approval are not implemented yet.
- Ollama must be installed separately.
- macOS support is paused.
- WSL support has been removed.

## Repository structure

```text
apps/desktop/                    Tauri, React, and TypeScript desktop app
apps/desktop/src/                Desktop interface
apps/desktop/src-tauri/          Native Rust backend and Windows packaging
src/omniterm/                    Original Python CLI runtime
tests/                           Runtime safety tests
pyproject.toml                   Python package configuration
```

## Safety model

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit one-time approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Run the native app successfully on Windows
- Produce and validate the first Windows setup executable
- Test installation and launch on a clean Windows system
- Let the chat agent request file and terminal tools
- Show proposed edits and unified diffs before writing
- Add BYOK providers and encrypted credential storage
- Add persistent terminal sessions
