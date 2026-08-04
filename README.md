# OmniTerm

OmniTerm is a Windows desktop app that lets you chat with an AI model while working with files in a project folder.

You can use:

- OpenAI
- Ollama
- Other services that support the OpenAI API format

You choose the provider and model inside the app. You do not need to use a terminal for normal use.

## Current status

OmniTerm is still being prepared for its first public Windows installer.

The repository currently contains the source code. A finished installer has not been uploaded yet.

Do not use **Code → Download ZIP** if you only want to install OmniTerm. That ZIP contains the project files, not the finished app.

## For normal users

Once the first installer is ready, installation will work like this:

1. Open the repository's **Releases** page.
2. Download the file ending in:

```text
_x64-setup.exe
```

3. Double-click the downloaded file.
4. Follow the installation steps.
5. Open **OmniTerm** from the Windows Start menu.

Normal users will not need Node.js, Rust, PowerShell, or any build tools.

## How to use OmniTerm

After opening the app:

1. Choose an AI provider.
2. Enter an API key if that provider requires one.
3. Select **Load models**.
4. Choose a model.
5. Select **Choose workspace** and pick a project folder.
6. Type a message and select **Send**.

You can also select files in the workspace browser to preview them.

The command panel is optional. You do not need it for provider setup or normal chat.

## AI provider choices

### OpenAI

Choose **OpenAI**, enter your API key, load the models, and select one.

Ollama is not required when using OpenAI.

### Ollama

Choose **Ollama** to use models running locally on your computer.

Ollama must already be installed and running. OmniTerm can show the models that are already available in Ollama, but it does not currently download large model files for you.

### OpenAI-compatible

Choose **OpenAI-compatible** to connect to software such as LM Studio, LocalAI, or vLLM.

Enter the server address and an API key when required.

## Privacy and API keys

API keys are currently kept only while OmniTerm is open.

They are not saved between app launches.

## What OmniTerm can currently do

- Chat with OpenAI, Ollama, and compatible providers
- Load available models inside the app
- Open a project folder
- Browse project files
- Preview text files
- Run optional commands inside the selected project
- Ask for approval before commands that may change files
- Block recognized destructive or privileged commands

## For the developer: create the Windows installer

This section is only for the person building OmniTerm. Normal users do not need to do this.

The repository includes:

```text
BUILD-WINDOWS-INSTALLER.cmd
```

This file is a builder. It is not the OmniTerm app.

### What the builder installs

The builder now uses Windows Package Manager to install missing build tools automatically:

- Node.js LTS and npm
- Rust
- Microsoft Visual Studio 2022 Build Tools
- The Desktop development with C++ workload
- Microsoft Edge WebView2 Runtime

Windows may ask for administrator permission during installation. A restart may be required after Visual Studio Build Tools or Rust is installed.

### Build the installer

1. Download the repository ZIP.
2. Right-click the ZIP and choose **Extract All**.
3. Open the extracted `omniterm-main` folder.
4. Double-click:

```text
BUILD-WINDOWS-INSTALLER.cmd
```

Do not double-click the builder while browsing inside the ZIP. Windows runs ZIP files from a temporary folder, and the builder cannot find the rest of the project there.

The builder will:

1. Check for Windows Package Manager.
2. Install any missing build tools.
3. Install the OmniTerm project dependencies.
4. Compile the Windows application.
5. Create the real setup `.exe`.
6. Open the installer folder in File Explorer.

The installer will be created under:

```text
apps\desktop\src-tauri\target\release\bundle\nsis\
```

Look for a file ending in:

```text
_x64-setup.exe
```

That `.exe` is the real Windows installer.

Test it on Windows, confirm OmniTerm opens correctly, and then upload it to a GitHub Release so normal users can download it.

### If Windows Package Manager is missing

The builder requires `winget`, which is normally included with modern Windows 10 and Windows 11 through Microsoft App Installer.

When the builder says `winget` is missing, install or update **App Installer** from the Microsoft Store, restart Windows, and run the builder again.

## Important notes

- The first Windows installer has not yet been validated.
- The installer is not code-signed, so Windows SmartScreen may show a warning.
- Chat cannot yet edit files automatically.
- API keys are not saved between launches.
- macOS support is paused.
- WSL support has been removed.

## Project folders

```text
BUILD-WINDOWS-INSTALLER.cmd      Installs build tools and builds the Windows installer
apps/desktop/                    Windows desktop app
apps/desktop/src/                App interface
apps/desktop/src-tauri/          Native Windows backend and installer setup
src/omniterm/                    Older Python command-line code
tests/                           Safety tests
```
