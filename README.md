# OmniTerm

OmniTerm is a native Windows desktop coding assistant built with C# and .NET 8.

It can connect to:

- OpenAI
- Ollama
- OpenAI-compatible servers such as LM Studio, LocalAI, and vLLM

OmniTerm can open a project folder, preview files, chat with a selected model, and run optional workspace commands with approval prompts.

## Features

- Native Windows interface using WPF
- OpenAI chat and model discovery
- Ollama chat and model discovery
- OpenAI-compatible endpoints
- Session-only API key entry
- Workspace folder selection
- Workspace file browser
- Text-file preview
- Optional workspace command runner
- Approval prompts for commands that may change files
- Blocking for several recognized destructive or privileged commands

## Using OmniTerm

1. Open `OmniTerm.exe`.
2. Choose an AI provider.
3. Confirm the endpoint.
4. Enter an API key when required.
5. Select **Load models**.
6. Choose a model.
7. Select **Choose workspace** and pick a project folder.
8. Enter a message and select **Send**.

API keys are kept only in memory while OmniTerm is open and are not saved between launches.

## Provider setup

### OpenAI

Choose **OpenAI**, enter an OpenAI API key, load the available models, and select one.

### Ollama

Choose **Ollama** to use locally installed models. Ollama must already be installed and running.

### OpenAI-compatible

Choose **OpenAI-compatible** for LM Studio, LocalAI, vLLM, or another compatible server. Enter the server's `/v1` endpoint and an API key when required.

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
apps/desktop-dotnet/             C#/.NET Windows app
.github/workflows/               GitHub Actions build workflow
apps/desktop/                    Previous Tauri prototype
src/omniterm/                    Earlier Python prototype
tests/                           Earlier runtime tests
```
