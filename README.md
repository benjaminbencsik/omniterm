# OmniTerm

OmniTerm is a native Windows desktop coding assistant built with C# and .NET 8.

It can connect to:

- OpenAI
- Ollama
- OpenAI-compatible servers such as LM Studio, LocalAI, and vLLM

OmniTerm can also open a project folder, preview files, and run optional workspace commands with approval prompts.

## Download OmniTerm

OmniTerm is built automatically by GitHub. You do not need Node.js, Rust, Visual Studio, C++ Build Tools, or the .NET SDK to run the finished app.

1. Open the repository's **Actions** tab.
2. Select **Build Windows App**.
3. Open the newest run with a green check mark.
4. Scroll to **Artifacts**.
5. Download **OmniTerm-Windows-x64**.
6. Extract the downloaded ZIP.
7. Double-click `OmniTerm.exe`.

The app is currently unsigned, so Windows SmartScreen may show a warning. Only run a build downloaded from this repository.

## How to use OmniTerm

1. Open `OmniTerm.exe`.
2. Choose an AI provider.
3. Confirm the endpoint.
4. Enter an API key when required.
5. Select **Load models**.
6. Choose a model.
7. Select **Choose workspace** and pick a project folder.
8. Enter a message and select **Send**.

API keys are kept only in memory while OmniTerm is open. They are not saved between launches.

## Provider setup

### OpenAI

Choose **OpenAI**, enter an OpenAI API key, load the available models, and select one. Ollama is not required.

### Ollama

Choose **Ollama** to use models installed locally. Ollama must already be installed and running.

### OpenAI-compatible

Choose **OpenAI-compatible** for LM Studio, LocalAI, vLLM, or another compatible server. Enter the server's `/v1` endpoint and an API key when required.

## Current features

- Native C#/.NET Windows interface
- OpenAI chat and model discovery
- Ollama chat and model discovery
- OpenAI-compatible endpoints
- Session-only API-key entry
- Workspace folder picker
- Workspace file browser
- Text-file previews up to 1 MB
- Optional workspace commands
- Approval prompt for commands that are not recognized as read-only
- Blocking for several recognized destructive or privileged commands
- Automatic self-contained Windows builds through GitHub Actions

## Current limitations

- The new .NET version still needs its first successful GitHub Actions build and Windows test.
- The app is distributed as a portable ZIP rather than a traditional setup wizard.
- The executable is not code-signed.
- Chat does not yet edit files automatically.
- File enumeration is currently limited to the first 1,000 files.
- API keys are not saved.

## Development

The active desktop project is:

```text
apps/desktop-dotnet/OmniTerm.csproj
```

To build it on a Windows development computer with the .NET 8 SDK:

```powershell
dotnet build apps/desktop-dotnet/OmniTerm.csproj
dotnet run --project apps/desktop-dotnet/OmniTerm.csproj
```

To create the same self-contained output used by GitHub Actions:

```powershell
dotnet publish apps/desktop-dotnet/OmniTerm.csproj `
  --configuration Release `
  --runtime win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true
```

## Repository structure

```text
apps/desktop-dotnet/             Active native C#/.NET Windows app
apps/desktop/                    Previous Tauri prototype
src/omniterm/                    Earlier Python command-line runtime
tests/                           Runtime safety tests
.github/workflows/               Automatic Windows build
```
