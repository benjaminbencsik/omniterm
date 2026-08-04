# OmniTerm

OmniTerm is an early native Windows desktop coding agent. It includes in-app AI provider selection, model discovery, workspace browsing, file previews, optional workspace commands, and approval prompts for actions that may change a project.

## Windows application status

OmniTerm is currently focused on Windows only.

The intended finished experience is a normal Windows application:

1. Download an installer named similar to `OmniTerm_0.1.0_x64-setup.exe`.
2. Double-click the installer.
3. Complete the setup wizard.
4. Open **OmniTerm** from the Windows Start menu.

An installed user should not need Node.js, Rust, PowerShell, a terminal, or the source repository.

At the moment, this repository contains the application source code, but a validated prebuilt installer has not yet been uploaded. The green **Code → Download ZIP** button downloads source code, not the finished program.

## How OmniTerm becomes a normal program

The Tauri project is already configured to produce a Windows NSIS installer. It needs to be compiled once on a Windows development machine.

The generated installer is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

Its filename should end in:

```text
_x64-setup.exe
```

That generated `.exe` should then be uploaded manually to the repository's **Releases** section.

After it is uploaded, normal users only download and run that installer. They do not compile OmniTerm themselves.

A GitHub source ZIP cannot automatically contain a newly compiled Windows program. The practical distribution choices are:

- Upload the compiled installer as a GitHub Release asset — recommended.
- Host the installer on a separate download page.
- Commit the binary directly into the repository — not recommended because binaries make the repository large and difficult to maintain.

## Install OmniTerm

This section applies after the first validated installer has been uploaded.

1. Open the repository's **Releases** section.
2. Open the newest Windows release.
3. Under **Assets**, download the file ending in `_x64-setup.exe`.
4. Double-click it and complete installation.
5. Launch **OmniTerm** from the Start menu.

The preview installer is not currently code-signed, so Windows SmartScreen may display a warning. Only run an installer downloaded from this repository's official Releases section.

## AI providers

Provider setup happens inside OmniTerm. A terminal is not required.

Supported modes:

- **OpenAI** — enter an OpenAI API key and load available cloud models.
- **Ollama** — use locally installed Ollama models.
- **OpenAI-compatible** — connect to LM Studio, LocalAI, vLLM, or another compatible server.

Inside the application:

1. Select a provider.
2. Confirm or change its endpoint.
3. Enter an API key when required.
4. Select **Load models**.
5. Choose a model.
6. Start chatting.

API keys currently remain in memory for the active session and are not saved by OmniTerm.

Ollama is optional. Users selecting OpenAI or another cloud provider do not need to install or download Ollama models.

## Use OmniTerm

1. Open OmniTerm from the Start menu.
2. Choose an AI provider and model.
3. Select **Choose workspace** and choose a project folder.
4. Enter a prompt and select **Send**.
5. Select files in the workspace browser to preview them.
6. Use the command panel only when needed; it is not required for provider setup or normal chat.

Recognized read-only commands can run automatically. Unknown or state-changing commands require approval. Recognized destructive and privileged commands are blocked.

## Build the installer on a Windows development machine

This section is only for the person producing the release installer. End users do not follow these steps.

### One-time build requirements

- Windows 10 or Windows 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime

### Build

Open PowerShell in the repository and run:

```powershell
cd apps\desktop
npm install
npm run tauri build
```

After the build finishes, open:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

Test the generated `_x64-setup.exe` on Windows. Once installation and launch are confirmed, upload that file to a GitHub Release.

This is a one-time task for each version. Everyone else installs and runs the resulting `.exe` normally.

## Development mode

Developers can run the application without creating an installer:

```powershell
cd apps\desktop
npm install
npm run tauri dev
```

Development mode requires the terminal to remain open. The installed release version does not.

## What currently works

- Native Windows desktop interface
- OpenAI provider connection
- Ollama provider connection
- Custom OpenAI-compatible endpoints
- In-app provider selection
- In-app model discovery and selection
- Session-only API-key entry
- Native workspace-folder picker
- Workspace file browser
- Text-file preview up to 1 MB
- Optional workspace-scoped commands
- One-time approval prompts for state-changing commands
- Blocking for recognized destructive and privileged commands

## Current limitations

- The first Windows installer still needs to be compiled and validated on a Windows machine.
- No validated installer is currently attached to Releases.
- The installer is not code-signed.
- Chat does not yet autonomously invoke file or command tools.
- File editing and unified-diff approval are not implemented yet.
- API keys are not persisted between launches.
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

OmniTerm operates inside a user-selected workspace. The desktop backend canonicalizes workspace paths before reading files or starting commands. Read-only commands can run automatically, unknown or state-changing commands require explicit approval, and recognized destructive or privileged commands are blocked.

This policy is an additional safeguard, not a complete security sandbox. Review commands before approving them and avoid selecting folders containing sensitive material.

## Roadmap

- Compile and validate the first Windows installer
- Upload the installer to GitHub Releases
- Test installation and launch on a clean Windows system
- Store provider credentials securely with an OS-backed secret store
- Let the chat agent request file and command tools
- Show proposed edits and unified diffs before writing
- Add persistent command sessions
