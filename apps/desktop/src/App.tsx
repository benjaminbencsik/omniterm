import { FormEvent, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { open } from "@tauri-apps/plugin-dialog";

type ChatMessage = { role: "user" | "assistant"; content: string };
type Provider = "openai" | "ollama" | "compatible";
type WorkspaceEntry = { path: string; isDirectory: boolean };
type CommandResult = {
  decision: "allow" | "ask" | "deny";
  reason: string;
  executed: boolean;
  exitCode: number | null;
  stdout: string;
  stderr: string;
};
type PendingCommand = { command: string; reason: string };

const providerDefaults: Record<Provider, { label: string; baseUrl: string; model: string; help: string }> = {
  openai: {
    label: "OpenAI",
    baseUrl: "https://api.openai.com",
    model: "gpt-5-mini",
    help: "Cloud models. Enter an OpenAI API key; no Ollama install is required.",
  },
  ollama: {
    label: "Ollama",
    baseUrl: "http://127.0.0.1:11434",
    model: "qwen2.5-coder:7b",
    help: "Local models. Ollama must be installed, but models can be selected from inside OmniTerm.",
  },
  compatible: {
    label: "OpenAI-compatible",
    baseUrl: "http://127.0.0.1:1234",
    model: "",
    help: "Use LM Studio, LocalAI, vLLM, or another server exposing an OpenAI-compatible API.",
  },
};

const initialMessages: ChatMessage[] = [
  {
    role: "assistant",
    content: "Welcome to OmniTerm. Choose an AI provider and model in the sidebar, then send a coding task.",
  },
];

export default function App() {
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [prompt, setPrompt] = useState("");
  const [workspace, setWorkspace] = useState<string | null>(null);
  const [workspaceEntries, setWorkspaceEntries] = useState<WorkspaceEntry[]>([]);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [filePreview, setFilePreview] = useState("Select a file to preview it here.");
  const [provider, setProvider] = useState<Provider>("openai");
  const [model, setModel] = useState(providerDefaults.openai.model);
  const [models, setModels] = useState<string[]>([]);
  const [baseUrl, setBaseUrl] = useState(providerDefaults.openai.baseUrl);
  const [apiKey, setApiKey] = useState("");
  const [busy, setBusy] = useState(false);
  const [loadingModels, setLoadingModels] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [terminalCommand, setTerminalCommand] = useState("git status");
  const [terminalOutput, setTerminalOutput] = useState("$ Select a workspace to begin.");
  const [pendingCommand, setPendingCommand] = useState<PendingCommand | null>(null);

  const status = useMemo(() => {
    if (busy || loadingModels) return "Working";
    if (error) return "Error";
    return "Ready";
  }, [busy, loadingModels, error]);

  function changeProvider(nextProvider: Provider) {
    const defaults = providerDefaults[nextProvider];
    setProvider(nextProvider);
    setBaseUrl(defaults.baseUrl);
    setModel(defaults.model);
    setModels([]);
    setError(null);
    if (nextProvider === "ollama") setApiKey("");
  }

  async function loadModels() {
    setLoadingModels(true);
    setError(null);
    try {
      const available = await invoke<string[]>("list_provider_models", {
        provider,
        baseUrl,
        apiKey,
      });
      setModels(available);
      if (available.length > 0 && !available.includes(model)) setModel(available[0]);
      if (available.length === 0) setError("The provider connected, but returned no models.");
    } catch (caught) {
      setModels([]);
      setError(String(caught));
    } finally {
      setLoadingModels(false);
    }
  }

  async function refreshWorkspace(selectedWorkspace: string) {
    try {
      const entries = await invoke<WorkspaceEntry[]>("list_workspace", { workspace: selectedWorkspace });
      setWorkspaceEntries(entries);
      setError(null);
    } catch (caught) {
      setError(String(caught));
      setWorkspaceEntries([]);
    }
  }

  async function chooseWorkspace() {
    const selected = await open({ directory: true, multiple: false });
    if (typeof selected === "string") {
      setWorkspace(selected);
      setSelectedFile(null);
      setFilePreview("Select a file to preview it here.");
      setTerminalOutput(`$ Workspace: ${selected}`);
      await refreshWorkspace(selected);
    }
  }

  async function previewFile(path: string) {
    if (!workspace) return;
    setSelectedFile(path);
    try {
      const content = await invoke<string>("read_workspace_file", { workspace, path });
      setFilePreview(content);
      setError(null);
    } catch (caught) {
      setFilePreview(String(caught));
      setError(String(caught));
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    const text = prompt.trim();
    if (!text || busy || !model.trim()) return;

    const nextMessages: ChatMessage[] = [...messages, { role: "user", content: text }];
    setMessages(nextMessages);
    setPrompt("");
    setBusy(true);
    setError(null);

    try {
      const content = await invoke<string>("provider_chat", {
        provider,
        baseUrl,
        apiKey,
        model,
        messages: nextMessages,
      });
      setMessages((current) => [...current, { role: "assistant", content }]);
    } catch (caught) {
      const message = String(caught);
      setError(message);
      setMessages((current) => [
        ...current,
        { role: "assistant", content: `The selected provider could not complete the request. ${message}` },
      ]);
    } finally {
      setBusy(false);
    }
  }

  function formatCommandResult(command: string, result: CommandResult) {
    const lines = [`$ ${command}`, `[${result.decision.toUpperCase()}] ${result.reason}`];
    if (result.executed) {
      lines.push(`Exit code: ${result.exitCode ?? "unknown"}`);
      if (result.stdout) lines.push("", result.stdout.trimEnd());
      if (result.stderr) lines.push("", result.stderr.trimEnd());
    }
    return lines.join("\n");
  }

  async function executeCommand(command: string, approved: boolean) {
    if (!workspace || !command.trim()) return;
    setBusy(true);
    setError(null);
    try {
      const result = await invoke<CommandResult>("run_workspace_command", {
        workspace,
        command,
        approved,
      });
      setTerminalOutput(formatCommandResult(command, result));
      if (result.decision === "ask" && !result.executed) {
        setPendingCommand({ command, reason: result.reason });
      } else {
        setPendingCommand(null);
        if (result.executed) await refreshWorkspace(workspace);
      }
    } catch (caught) {
      setError(String(caught));
      setTerminalOutput(`$ ${command}\n${String(caught)}`);
    } finally {
      setBusy(false);
    }
  }

  async function submitCommand(event: FormEvent) {
    event.preventDefault();
    await executeCommand(terminalCommand.trim(), false);
  }

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">O</div>
          <div><h1>OmniTerm</h1><p>Windows coding agent</p></div>
        </div>

        <section className="panel compact provider-card">
          <span className="eyebrow">AI connection</span>
          <strong>Choose your provider</strong>
          <small>{providerDefaults[provider].help}</small>
        </section>

        <section className="settings">
          <label>
            <span>Provider</span>
            <select value={provider} onChange={(event) => changeProvider(event.target.value as Provider)}>
              <option value="openai">OpenAI</option>
              <option value="ollama">Ollama</option>
              <option value="compatible">OpenAI-compatible</option>
            </select>
          </label>
          <label>
            <span>Endpoint</span>
            <input value={baseUrl} onChange={(event) => setBaseUrl(event.target.value)} />
          </label>
          {provider !== "ollama" && (
            <label>
              <span>API key</span>
              <input
                type="password"
                value={apiKey}
                onChange={(event) => setApiKey(event.target.value)}
                placeholder={provider === "openai" ? "sk-..." : "Optional for local servers"}
                autoComplete="off"
              />
              <small>Kept in memory for this session and not saved by OmniTerm.</small>
            </label>
          )}
          <button className="ghost-button" onClick={loadModels} disabled={loadingModels}>
            {loadingModels ? "Loading models…" : "Load models"}
          </button>
          <label>
            <span>Model</span>
            {models.length > 0 ? (
              <select value={model} onChange={(event) => setModel(event.target.value)}>
                {models.map((availableModel) => <option value={availableModel} key={availableModel}>{availableModel}</option>)}
              </select>
            ) : (
              <input value={model} onChange={(event) => setModel(event.target.value)} placeholder="Enter a model name" />
            )}
          </label>
        </section>

        <button className="primary-button" onClick={chooseWorkspace}>Choose workspace</button>
        <section className="panel compact">
          <span className="eyebrow">Workspace</span>
          <strong>{workspace ? "Connected" : "Not selected"}</strong>
          <small title={workspace || undefined}>{workspace || "Select a project folder"}</small>
        </section>

        <section className="panel compact status-card">
          <span className={`status-dot ${error ? "error" : ""}`} />
          <div><strong>{status}</strong><small>{error || `${providerDefaults[provider].label} · ${model || "No model selected"}`}</small></div>
        </section>
      </aside>

      <section className="workspace-area">
        <header className="topbar">
          <div><span className="eyebrow">Session</span><h2>New coding task</h2></div>
          <button className="ghost-button" onClick={() => setMessages(initialMessages)}>Clear chat</button>
        </header>

        <div className="content-grid">
          <section className="chat-panel">
            <div className="messages">
              {messages.map((message, index) => (
                <article className={`message ${message.role}`} key={`${message.role}-${index}`}>
                  <div className="avatar">{message.role === "assistant" ? "O" : "You"}</div>
                  <div><span>{message.role === "assistant" ? "OmniTerm" : "You"}</span><p>{message.content}</p></div>
                </article>
              ))}
              {busy && <div className="thinking">OmniTerm is working…</div>}
            </div>
            <form className="composer" onSubmit={submit}>
              <textarea value={prompt} onChange={(event) => setPrompt(event.target.value)} placeholder="Ask OmniTerm to explain or build something…" rows={4} />
              <div className="composer-footer">
                <span>{providerDefaults[provider].label} · {model || "Choose a model"}</span>
                <button className="primary-button" disabled={busy || !prompt.trim() || !model.trim()} type="submit">{busy ? "Working…" : "Send"}</button>
              </div>
            </form>
          </section>

          <aside className="activity-column">
            <section className="panel file-panel">
              <div className="panel-heading"><div><span className="eyebrow">Files</span><h3>Workspace browser</h3></div><span className="count">{workspaceEntries.length}</span></div>
              <div className="file-browser">
                {workspaceEntries.length === 0 && <p className="muted">Choose a workspace to list files.</p>}
                {workspaceEntries.map((entry) => (
                  <button className={`file-entry ${selectedFile === entry.path ? "selected" : ""}`} disabled={entry.isDirectory} key={entry.path} onClick={() => previewFile(entry.path)} title={entry.path}>
                    {entry.isDirectory ? "▸" : "•"} {entry.path}
                  </button>
                ))}
              </div>
              <pre className="file-preview">{filePreview}</pre>
            </section>

            <section className="panel">
              <div className="panel-heading"><div><span className="eyebrow">Terminal</span><h3>Optional command tools</h3></div><span className="badge">Not required for setup</span></div>
              <form className="terminal-form" onSubmit={submitCommand}>
                <input value={terminalCommand} onChange={(event) => setTerminalCommand(event.target.value)} placeholder="git status" />
                <button className="primary-button" disabled={!workspace || busy} type="submit">Run</button>
              </form>
              <pre>{terminalOutput}</pre>
            </section>

            <section className="panel">
              <div className="panel-heading"><div><span className="eyebrow">Approvals</span><h3>Pending actions</h3></div><span className="count">{pendingCommand ? 1 : 0}</span></div>
              {pendingCommand ? (
                <div className="approval-card">
                  <code>{pendingCommand.command}</code><p className="muted">{pendingCommand.reason}</p>
                  <div className="approval-actions">
                    <button className="ghost-button" onClick={() => setPendingCommand(null)}>Cancel</button>
                    <button className="primary-button" onClick={() => executeCommand(pendingCommand.command, true)}>Allow once</button>
                  </div>
                </div>
              ) : <p className="muted">State-changing commands appear here before execution.</p>}
            </section>
          </aside>
        </div>
      </section>
    </main>
  );
}
