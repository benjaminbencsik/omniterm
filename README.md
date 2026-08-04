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

## Build the real Windows installer with one double-click

The repository includes this developer tool:

```text
BUILD-WINDOWS-INSTALLER.cmd
```

This batch file is **not OmniTerm itself**. It compiles the actual Windows setup executable.

### One-time requirements for the build computer

Install these once:

- Windows 10 or Windows 11
- Node.js 20 or newer
- Rust stable toolchain
- Microsoft Visual Studio Build Tools with **Desktop development with C++**
- Microsoft Edge WebView2 Runtime

### Build steps

1. Download or clone the repository.
2. Extract the entire ZIP if you downloaded the source ZIP.
3. Double-click:

```text
BUILD-WINDOWS-INSTALLER.cmd
```

The builder will:

1. Confirm that Node.js, npm, and Rust are available.
2. Install the desktop JavaScript dependencies.
3. Compile the Tauri application.
4. Create the NSIS Windows setup executable.
5. Open the output folder in File Explorer.
6. Keep the command window open if the build fails.

The generated installer is written under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

Its filename should end in:

```text
_x64-setup.exe
```

That generated `.exe` is the real installer normal users should run.

## How OmniTerm becomes a normal downloadable program

After `BUILD-WINDOWS-INSTALLER.cmd` succeeds:

1. Run the generated `_x64-setup.exe` on your Windows computer.
2. Confirm that installation completes.
3. Open OmniTerm from the Start menu.
4. Confirm that provider selection and chat work.
5. Create a GitHub Release.
6. Upload the generated `_x64-setup.exe` as a Release asset.

After that, users only download and run the installer. They do not compile OmniTerm themselves.

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

## Manual developer commands

The one-click builder runs these commands internally:

```powershell
cd apps\desktop
npm install
npm run tauri build
```

Developers can run the application without creating an installer with:

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
- One-click developer installer build script

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
BUILD-WINDOWS-INSTALLER.cmd      One-click developer installer builder
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

- Run `BUILD-WINDOWS-INSTALLER.cmd` on Windows
- Validate the generated installer
- Upload the installer to GitHub Releases
- Test installation and launch on a clean Windows system
- Store provider credentials securely with an OS-backed secret store
- Let the chat agent request file and command tools
- Show proposed edits and unified diffs before writing
- Add persistent command sessions
