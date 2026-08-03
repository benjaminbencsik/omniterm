# OmniTerm Desktop

OmniTerm Desktop is the graphical Windows and macOS application.

## Installing a packaged build

End users should not install Python, Node.js, Rust, Git, or WSL.

### Windows

1. Open the repository's **Releases** page.
2. Download the Windows `OmniTerm` setup executable or MSI.
3. Double-click the downloaded installer.
4. Launch OmniTerm from the Start menu or desktop shortcut.

A ZIP artifact from a GitHub Actions run can also be downloaded and extracted. Open the extracted folder and double-click the included setup executable.

### macOS

1. Open the repository's **Releases** page.
2. Download the OmniTerm DMG.
3. Open the DMG.
4. Drag OmniTerm into Applications.
5. Launch OmniTerm from Applications.

Unsigned development builds may trigger Windows SmartScreen or macOS Gatekeeper. Production releases should be code-signed and macOS builds should be notarized before broad distribution.

## Local model requirement

The first desktop milestone connects to Ollama. Install and start Ollama separately, then pull a coding model such as:

```text
qwen2.5-coder:7b
```

The app defaults to `http://127.0.0.1:11434` and lets the user change the endpoint and model from the sidebar.

## Current GUI features

- Native Windows and macOS application window
- Ollama chat
- Configurable model and endpoint
- Native workspace folder picker
- Chat history and connection status
- Terminal, approval, and safety panels prepared for the next runtime integration

## Building locally

These commands are only for contributors. End users should download a packaged build.

Requirements:

- Node.js 22 or newer
- Rust stable toolchain
- Tauri operating-system prerequisites

```bash
cd apps/desktop
npm install
npm run tauri dev
```

Build installers:

```bash
npm run tauri build
```

Windows output is placed under `src-tauri/target/release/bundle/nsis` and `src-tauri/target/release/bundle/msi`.

macOS output is placed under `src-tauri/target/release/bundle/dmg` and `src-tauri/target/release/bundle/macos`.

## Automated builds

The `Desktop builds` GitHub Actions workflow builds Windows and macOS packages automatically.

- Branch and manual builds are uploaded as downloadable workflow artifacts.
- Version tags such as `v0.1.0` create a draft prerelease with platform installers attached.
