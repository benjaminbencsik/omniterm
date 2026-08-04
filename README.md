# OmniTerm

OmniTerm is a native Windows desktop coding assistant built with C# and .NET 8.

It supports direct API-key connections to:

- OpenAI
- Anthropic
- Google Gemini

OmniTerm can open a project folder, preview files, chat with a selected model, and run optional workspace commands with approval prompts.

## Features

- Native Windows interface using WPF
- Direct OpenAI API support
- Direct Anthropic API support
- Direct Google Gemini API support
- Provider-specific model discovery
- Session-only API key entry
- Workspace folder selection
- Workspace file browser
- Text-file preview
- Optional workspace command runner
- Approval prompts for commands that may change files
- Blocking for several recognized destructive or privileged commands

## Using OmniTerm

1. Open `OmniTerm.exe`.
2. Choose **OpenAI**, **Anthropic**, or **Google Gemini**.
3. Enter the API key for that provider.
4. Select **Load models**.
5. Choose a model.
6. Select **Choose workspace** and pick a project folder.
7. Enter a message and select **Send**.

API keys are kept only in memory while OmniTerm is open and are not saved between launches.

## Provider setup

### OpenAI

Choose **OpenAI**, enter an OpenAI API key, load the available models, and select one.

### Anthropic

Choose **Anthropic**, enter an Anthropic API key, load the available Claude models, and select one.

### Google Gemini

Choose **Google Gemini**, enter a Gemini API key from Google AI Studio, load the available Gemini models, and select one.

## Run from the repository

On Windows, download and extract the repository ZIP, then double-click:

```text
RUN-OMNITERM.cmd
```

The launcher installs the .NET 8 SDK with Windows Package Manager when needed, builds the app, and opens OmniTerm.

## Development

The Windows desktop project is:

```text
apps/desktop-dotnet/OmniTerm.csproj
```

Build and run it on Windows with the .NET 8 SDK:

```powershell
dotnet restore apps/desktop-dotnet/OmniTerm.csproj
dotnet run --project apps/desktop-dotnet/OmniTerm.csproj
```

Create a self-contained Windows build with:

```powershell
dotnet publish apps/desktop-dotnet/OmniTerm.csproj `
  --configuration Release `
  --runtime win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true
```

## Repository structure

```text
RUN-OMNITERM.cmd                 Windows build-and-run launcher
apps/desktop-dotnet/             C#/.NET Windows app
.github/workflows/               GitHub Actions build workflow
apps/desktop/                    Previous Tauri prototype
src/omniterm/                    Earlier Python prototype
tests/                           Earlier runtime tests
```
