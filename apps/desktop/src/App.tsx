import { FormEvent, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { open } from "@tauri-apps/plugin-dialog";

type ChatMessage = {
  role: "user" | "assistant";
  content: string;
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
  const [model, setModel] = useState("qwen2.5-coder:7b");
  const [baseUrl, setBaseUrl] = useState("http://127.0.0.1:11434");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const status = useMemo(() => {
    if (busy) return "Thinking";
    if (error) return "Connection error";
    return "Ready";
  }, [busy, error]);

  async function chooseWorkspace() {
    const selected = await open({ directory: true, multiple: false });
    if (typeof selected === "string") setWorkspace(selected);
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
      const message = caught instanceof Error ? caught.message : String(caught);
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
            <small>{error || "Ollama connection is checked when you send"}</small>
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
              {busy && <div className="thinking">OmniTerm is thinking…</div>}
            </div>

            <form className="composer" onSubmit={submit}>
              <textarea
                value={prompt}
                onChange={(event) => setPrompt(event.target.value)}
                placeholder="Ask OmniTerm to inspect, explain, or build something…"
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
            <section className="panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow">Terminal</span>
                  <h3>Command output</h3>
                </div>
                <span className="badge">Next milestone</span>
              </div>
              <pre>$ OmniTerm terminal bridge is not connected yet.</pre>
            </section>

            <section className="panel">
              <div className="panel-heading">
                <div>
                  <span className="eyebrow">Approvals</span>
                  <h3>Pending actions</h3>
                </div>
                <span className="count">0</span>
              </div>
              <p className="muted">
                Commands and file writes will appear here for review before execution.
              </p>
            </section>

            <section className="panel">
              <span className="eyebrow">Safety mode</span>
              <h3>Ask before changes</h3>
              <p className="muted">
                Workspace reads can run automatically. Writes and state-changing commands require approval.
              </p>
            </section>
          </aside>
        </div>
      </section>
    </main>
  );
}
