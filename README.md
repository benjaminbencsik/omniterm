# OmniTerm

OmniTerm is being rebuilt as a native Windows desktop app using C# and .NET 8.

## Current status

The active project is:

```text
apps/desktop-dotnet/OmniTerm.csproj
```

The .NET app is **not ready to download yet**. The current GitHub Actions build is still failing, so there is no working `OmniTerm.exe` artifact at this time.

The older folders are retained only as reference during the migration:

```text
apps/desktop/      Previous Tauri prototype
src/omniterm/      Earlier Python command-line prototype
```

They are not the active Windows app.

## What the .NET app is intended to do

- Connect to OpenAI
- Connect to Ollama
- Connect to OpenAI-compatible servers
- Load available models
- Chat with the selected model
- Open a project folder
- Browse and preview project files
- Run optional workspace commands with approval prompts

## How to run it

### After GitHub Actions succeeds

1. Open the repository's **Actions** tab.
2. Open **Build Windows App**.
3. Open the newest run with a green check mark.
4. Download the `OmniTerm-Windows-x64` artifact.
5. Extract the downloaded ZIP.
6. Open the extracted folder.
7. Double-click `OmniTerm.exe`.

Until a run has a green check mark and an artifact, there is nothing usable to download.

### Build locally for development

A Windows computer with the .NET 8 SDK can run:

```powershell
dotnet restore apps/desktop-dotnet/OmniTerm.csproj
dotnet run --project apps/desktop-dotnet/OmniTerm.csproj
```

Normal users will not need the .NET SDK after a self-contained build is produced.

## Provider setup

### OpenAI

Choose **OpenAI**, enter an API key, load models, and select a model.

### Ollama

Choose **Ollama**. Ollama must already be installed and running locally.

### OpenAI-compatible

Choose **OpenAI-compatible** for software such as LM Studio, LocalAI, or vLLM. Enter the server's `/v1` endpoint and an API key when required.

## Security and limitations

- API keys are kept only in memory for the current session.
- The app is not code-signed.
- Chat does not yet edit files automatically.
- The command runner blocks several recognized destructive commands and asks for approval for commands that are not recognized as read-only.
- The .NET rewrite has not yet completed its first successful Windows build.

## Repository structure

```text
apps/desktop-dotnet/             Active C#/.NET Windows app
.github/workflows/               GitHub Actions build workflow
apps/desktop/                    Previous Tauri prototype
src/omniterm/                    Earlier Python prototype
tests/                           Earlier runtime tests
```
