import { FormEvent, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { open } from "@tauri-apps/plugin-dialog";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
};

type WorkspaceEntry = {
  path: string;
  isDirectory: boolean;
};

type CommandResult = {
  decision: "allow" | "ask" | "deny";
  reason: string;
  executed: boolean;
  exitCode: number | null;
  stdout: string;
  stderr: string;
};

type PendingCommand = {
  command: string;
  reason: string;
};

const initialMessages: ChatMessage[] = [
  {
    role: "assistant",
    content:
      "Welcome to OmniTerm. Choose a workspace, confirm your Ollama model, and send a coding task.",
  },
];

export default function App() {
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [prompt, setPrompt] = useState("");
  const [workspace, setWorkspace] = useState<string | null>(null);
  const [workspaceEntries, setWorkspaceEntries] = useState<WorkspaceEntry[]>([]);
  const [selectedFile, setSelectedFile] = useState<string | null>(null);
  const [filePreview, setFilePreview] = useState("Select a file to preview it here.");
  const [model, setModel] = useState("qwen2.5-coder:7b");
  const [baseUrl, setBaseUrl] = useState("http://127.0.0.1:11434");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [terminalCommand, setTerminalCommand] = useState("git status");
  const [terminalOutput, setTerminalOutput] = useState("$ Select a workspace to begin.");
  const [pendingCommand, setPendingCommand] = useState<PendingCommand | null>(null);

  const status = useMemo(() => {
    if (busy) return "Working";
    if (error) return "Error";
    return "Ready";
  }, [busy, error]);

  async function refreshWorkspace(selectedWorkspace: string) {
    try {
      const entries = await invoke<WorkspaceEntry[]>("list_workspace", {
        workspace: selectedWorkspace,
      });
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
      const content = await invoke<string>("read_workspace_file", {
        workspace,
        path,
      });
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
    if (!text || busy) return;

    const nextMessages: ChatMessage[] = [...messages, { role: "user", content: text }];
    setMessages(nextMessages);
    setPrompt("");
    setBusy(true);
    setError(null);

    try {
      const content = await invoke<string>("ollama_chat", {
        baseUrl,
        model,
        messages: nextMessages,
      });
      setMessages((current) => [...current, { role: "assistant", content }]);
    } catch (caught) {
      const message = String(caught);
      setError(message);
      setMessages((current) => [
        ...current,
        {
          role: "assistant",
          content: `I could not reach the configured Ollama endpoint. ${message}`,
        },
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
          <div>
            <h1>OmniTerm</h1>
            <p>Local-first coding agent</p>
          </div>
        </div>

        <button className="primary-button" onClick={chooseWorkspace}>
          Choose workspace
        </button>

        <section className="panel compact">
          <span className="eyebrow">Workspace</span>
          <strong>{workspace ? "Connected" : "Not selected"}</strong>
          <small title={workspace || undefined}>{workspace || "Select a project folder"}</small>
        </section>

        <section className="settings">
          <label>
            <span>Provider</span>
            <select disabled value="ollama">
              <option value="ollama">Ollama</option>
            </select>
          </label>
          <label>
            <span>Model</span>
            <input value={model} onChange={(event) => setModel(event.target.value)} />
          </label>
          <label>
            <span>Endpoint</span>
            <input value={baseUrl} onChange={(event) => setBaseUrl(event.target.value)} />
          </label>
        </section>

        <section className="panel compact status-card">
          <span className={`status-dot ${error ? "error" : ""}`} />
          <div>
            <strong>{status}</strong>
            <small>{error || "Workspace tools and Ollama are ready"}</small>
          </div>
        </section>
      </aside>

      <section className="workspace-area">
        <header className="topbar">
          <div>
            <span className="eyebrow">Session</span>
            <h2>New coding task</h2>
          </div>
          <button className="ghost-button" onClick={() => setMessages(initialMessages)}>
            Clear chat
          </button>
        </header>

        <div className="content-grid">
          <section className="chat-panel">
            <div className="messages">
              {messages.map((message, index) => (
                <article className={`message ${message.role}`} key={`${message.role}-${index}`}>
                  <div className="avatar">{message.role === "assistant" ? "O" : "You"}</div>
                  <div>
                    <span>{message.role === "assistant" ? "OmniTerm" : "You"}</span>
                    <p>{message.content}</p>
                  </div>
                </article>
              ))}
              {busy && <div className="thinking">OmniTerm is working…</div>}
            </div>

            <form className="composer" onSubmit={submit}>
              <textarea
                value={prompt}
                onChange={(event) => setPrompt(event.target.value)}
                placeholder="Ask OmniTerm to explain or build something…"
                rows={4}
              />
              <div className="composer-footer">
                <span>{workspace ? "Workspace selected" : "Chat-only mode"}</span>
                <button className="primary-button" disabled={busy || !prompt.trim()} type="submit">
                  {busy ? "Working…" : "Send"}
                </button>
              </div>
            </form>
          </section>

          <aside className="activity-column">
            <section className="panel file-panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow">Files</span>
                  <h3>Workspace browser</h3>
                </div>
                <span className="count">{workspaceEntries.length}</span>
              </div>
              <div className="file-browser">
                {workspaceEntries.length === 0 && <p className="muted">Choose a workspace to list files.</p>}
                {workspaceEntries.map((entry) => (
                  <button
                    className={`file-entry ${selectedFile === entry.path ? "selected" : ""}`}
                    disabled={entry.isDirectory}
                    key={entry.path}
                    onClick={() => previewFile(entry.path)}
                    title={entry.path}
                  >
                    {entry.isDirectory ? "▸" : "•"} {entry.path}
                  </button>
                ))}
              </div>
              <pre className="file-preview">{filePreview}</pre>
            </section>

            <section className="panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow">Terminal</span>
                  <h3>Command output</h3>
                </div>
                <span className="badge">Workspace scoped</span>
              </div>
              <form className="terminal-form" onSubmit={submitCommand}>
                <input
                  value={terminalCommand}
                  onChange={(event) => setTerminalCommand(event.target.value)}
                  placeholder="git status"
                />
                <button className="primary-button" disabled={!workspace || busy} type="submit">
                  Run
                </button>
              </form>
              <pre>{terminalOutput}</pre>
            </section>

            <section className="panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow">Approvals</span>
                  <h3>Pending actions</h3>
                </div>
                <span className="count">{pendingCommand ? 1 : 0}</span>
              </div>
              {pendingCommand ? (
                <div className="approval-card">
                  <code>{pendingCommand.command}</code>
                  <p className="muted">{pendingCommand.reason}</p>
                  <div className="approval-actions">
                    <button className="ghost-button" onClick={() => setPendingCommand(null)}>
                      Cancel
                    </button>
                    <button
                      className="primary-button"
                      onClick={() => executeCommand(pendingCommand.command, true)}
                    >
                      Allow once
                    </button>
                  </div>
                </div>
              ) : (
                <p className="muted">State-changing commands appear here before execution.</p>
              )}
            </section>

            <section className="panel">
              <span className="eyebrow">Safety mode</span>
              <h3>Ask before changes</h3>
              <p className="muted">
                Read-only commands run automatically. Unknown or state-changing commands require approval,
                while recognized destructive commands are blocked.
              </p>
            </section>
          </aside>
        </div>
      </section>
    </main>
  );
}
