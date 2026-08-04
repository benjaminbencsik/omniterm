# OmniTerm

OmniTerm is an early native Windows desktop coding agent. It includes AI provider selection, model discovery, workspace browsing, text-file previews, a workspace-scoped terminal, and approval prompts for commands that may change a project or computer.

## Project status

OmniTerm is currently focused on Windows only.

The repository contains source code. There is not yet a validated prebuilt Windows installer attached to the repository. The green **Code → Download ZIP** button downloads source code, not a finished application.

GitHub Actions, macOS packaging, WSL launchers, and WSL installers have been removed while the native Windows application is being validated.

## AI providers

Provider setup now happens inside the OmniTerm window. You do not need to use a terminal to select a provider or model.

Supported provider modes:

- **OpenAI** — enter an OpenAI API key and load cloud models. Ollama is not required.
- **Ollama** — use locally installed Ollama models.
- **OpenAI-compatible** — connect to LM Studio, LocalAI, vLLM, or another compatible server.

Inside OmniTerm:

1. Select a provider.
2. Confirm or change its endpoint.
3. Enter an API key when the provider requires one.
4. Select **Load models**.
5. Choose a model from the returned list.
6. Start chatting.

API keys are kept in memory for the current application session and are not saved by OmniTerm.

## No-Ollama setup

To use OmniTerm without Ollama:

1. Open OmniTerm.
2. Select **OpenAI**.
3. Enter your OpenAI API key.
4. Select **Load models**.
5. Choose a model.
6. Enter a prompt and select **Send**.

You can also select **OpenAI-compatible** and enter the endpoint of another compatible provider.

## Optional local Ollama setup

Ollama is now optional. To use local models:

1. Install and start Ollama for Windows.
2. Select **Ollama** inside OmniTerm.
3. Leave the default endpoint as:

```text
http://127.0.0.1:11434
```

4. Select **Load models** to display models already installed in Ollama.

OmniTerm does not currently download multi-gigabyte Ollama models automatically. Model installation remains managed by Ollama.

## Run OmniTerm on Windows from source

### Requirements

Install these once:

- Windows 10 or Windows 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime

Ollama is not required when using OpenAI or another cloud provider.

### Start OmniTerm in development mode

Open PowerShell in the repository folder and run:

```powershell
cd apps\desktop
npm install
npm run tauri dev
```

This opens the native OmniTerm desktop window. Keep PowerShell open while development mode is running.

## Build the Windows setup executable

From `apps\desktop`, run:

```powershell
npm run tauri build
```

After a successful build, the real NSIS setup executable is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

The filename should end in:

```text
-setup.exe
```

That generated `.exe` is the installer. Source ZIPs and scripts are not the finished application.

## Use OmniTerm

After launching the desktop window:

1. Choose an AI provider and model.
2. Select **Choose workspace** and choose a project folder.
3. Enter a prompt and select **Send**.
4. Select files in the workspace browser to preview them.
5. Use the terminal panel only when you want to run workspace commands; it is not required for AI setup or normal chat.

Recognized read-only commands can run automatically. Unknown or state-changing commands appear in the **Approvals** panel with **Cancel** and **Allow once** controls. Recognized destructive and privileged commands are blocked.

## What currently works

- Native Windows desktop interface
- OpenAI cloud-provider connection
- Ollama local-provider connection
- Custom OpenAI-compatible endpoints
- In-app provider selection
- In-app model discovery and selection
- Session-only API-key entry
- Native workspace-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Optional workspace-scoped terminal commands
- One-time approval prompts for state-changing commands
- Blocking for recognized destructive and privileged commands

## Current limitations

- The Windows installer still needs a successful local build and clean-machine validation.
- The installer is not code-signed.
- Chat does not yet autonomously invoke file or terminal tools.
- File editing and unified-diff approval are not implemented yet.
- Ollama model downloads are not managed by OmniTerm.
- API keys are not persisted between application launches.
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

- Run and validate the native app on Windows
- Produce and validate the first Windows setup executable
- Store provider credentials securely with an OS-backed secret store
- Let the chat agent request file and terminal tools
- Show proposed edits and unified diffs before writing
- Add persistent terminal sessions
