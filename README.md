# OmniTerm

OmniTerm is a local-first desktop coding agent designed to work with local language models and user-supplied API keys. It will combine conversational coding assistance with permission-controlled terminal, filesystem, browser, and desktop tools.

## Goals

- Run local models through Ollama and OpenAI-compatible endpoints
- Support bring-your-own-key cloud providers
- Read, search, edit, and patch project files
- Run terminal commands through approval-controlled sessions
- Display proposed changes and Git diffs before commits
- Add browser and desktop automation behind explicit permissions
- Keep credentials in the operating system credential store

## Planned architecture

- **Desktop application:** Tauri, React, and TypeScript
- **Agent runtime:** Python
- **Provider layer:** Ollama, OpenAI-compatible APIs, Anthropic, and Google
- **Terminal:** persistent pseudo-terminal sessions
- **Storage:** SQLite plus operating system credential storage
- **Automation:** Playwright first, structured desktop automation later

## Safety principles

OmniTerm should operate inside a user-selected workspace by default. Destructive commands, privilege escalation, credential access, package installation, external application control, and Git pushes must require explicit approval.

## Status

Early development. The initial milestone is a provider-independent agent runtime with filesystem and terminal tools.
