use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

#[derive(Debug, Deserialize, Serialize)]
struct ChatMessage {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct OllamaMessage {
    content: Option<String>,
}

#[derive(Debug, Deserialize)]
struct OllamaResponse {
    message: Option<OllamaMessage>,
    error: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct WorkspaceEntry {
    path: String,
    is_directory: bool,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct CommandResult {
    decision: String,
    reason: String,
    executed: bool,
    exit_code: Option<i32>,
    stdout: String,
    stderr: String,
}

fn canonical_workspace(workspace: &str) -> Result<PathBuf, String> {
    let root = fs::canonicalize(workspace)
        .map_err(|error| format!("Unable to open workspace: {error}"))?;
    if !root.is_dir() {
        return Err("The selected workspace is not a directory".to_string());
    }
    Ok(root)
}

fn safe_workspace_path(workspace: &str, relative_path: &str) -> Result<PathBuf, String> {
    let root = canonical_workspace(workspace)?;
    let candidate = root.join(relative_path);
    let resolved = fs::canonicalize(&candidate)
        .map_err(|error| format!("Unable to open workspace path: {error}"))?;
    if !resolved.starts_with(&root) {
        return Err("Path escapes the selected workspace".to_string());
    }
    Ok(resolved)
}

fn collect_entries(root: &Path, current: &Path, entries: &mut Vec<WorkspaceEntry>) -> Result<(), String> {
    if entries.len() >= 300 {
        return Ok(());
    }

    let mut children = fs::read_dir(current)
        .map_err(|error| format!("Unable to list workspace: {error}"))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("Unable to read workspace entry: {error}"))?;
    children.sort_by_key(|entry| entry.file_name());

    for child in children {
        if entries.len() >= 300 {
            break;
        }
        let path = child.path();
        let name = child.file_name();
        if matches!(name.to_str(), Some(".git" | "node_modules" | "target" | ".venv" | "venv")) {
            continue;
        }
        let relative = path
            .strip_prefix(root)
            .map_err(|_| "Unable to calculate workspace path".to_string())?
            .to_string_lossy()
            .replace('\\', "/");
        let is_directory = path.is_dir();
        entries.push(WorkspaceEntry {
            path: relative,
            is_directory,
        });
        if is_directory {
            collect_entries(root, &path, entries)?;
        }
    }
    Ok(())
}

fn command_policy(command: &str) -> (&'static str, &'static str) {
    let normalized = command.trim().to_lowercase();
    if normalized.is_empty() {
        return ("deny", "Empty commands are not allowed");
    }

    let denied = [
        "sudo ", "su ", "doas ", "shutdown", "reboot", "poweroff", "halt", "mkfs",
        "fdisk", "parted", "format ", "reg delete", "rm -rf /", "rm -rf ~",
    ];
    if denied.iter().any(|pattern| normalized.contains(pattern)) {
        return ("deny", "Command matches a blocked destructive or privileged pattern");
    }

    let allowed_prefixes = [
        "git status", "git diff", "git log", "git show", "git branch", "ls", "dir",
        "pwd", "cat ", "type ", "head ", "tail ", "grep ", "rg ", "find ", "where ",
        "which ", "echo ", "python --version", "python3 --version", "node --version",
        "npm --version", "cargo --version",
    ];
    if allowed_prefixes
        .iter()
        .any(|prefix| normalized == *prefix || normalized.starts_with(prefix))
    {
        return ("allow", "Recognized low-risk read-only command");
    }

    ("ask", "This command may change files, access the network, or alter system state")
}

#[tauri::command]
async fn ollama_chat(
    base_url: String,
    model: String,
    messages: Vec<ChatMessage>,
) -> Result<String, String> {
    let endpoint = format!("{}/api/chat", base_url.trim_end_matches('/'));
    let response = reqwest::Client::new()
        .post(endpoint)
        .json(&serde_json::json!({
            "model": model,
            "messages": messages,
            "stream": false
        }))
        .send()
        .await
        .map_err(|error| format!("Unable to contact Ollama: {error}"))?;

    let status = response.status();
    let payload: OllamaResponse = response
        .json()
        .await
        .map_err(|error| format!("Invalid Ollama response: {error}"))?;

    if !status.is_success() {
        return Err(payload
            .error
            .unwrap_or_else(|| format!("Ollama returned HTTP {status}")));
    }
    if let Some(error) = payload.error {
        return Err(error);
    }

    Ok(payload
        .message
        .and_then(|message| message.content)
        .unwrap_or_else(|| "No response content.".to_string()))
}

#[tauri::command]
fn list_workspace(workspace: String) -> Result<Vec<WorkspaceEntry>, String> {
    let root = canonical_workspace(&workspace)?;
    let mut entries = Vec::new();
    collect_entries(&root, &root, &mut entries)?;
    Ok(entries)
}

#[tauri::command]
fn read_workspace_file(workspace: String, path: String) -> Result<String, String> {
    let resolved = safe_workspace_path(&workspace, &path)?;
    if !resolved.is_file() {
        return Err("The selected path is not a file".to_string());
    }
    let metadata = fs::metadata(&resolved).map_err(|error| format!("Unable to inspect file: {error}"))?;
    if metadata.len() > 1_000_000 {
        return Err("File is larger than the 1 MB preview limit".to_string());
    }
    fs::read_to_string(resolved).map_err(|error| format!("Unable to read text file: {error}"))
}

#[tauri::command]
fn run_workspace_command(
    workspace: String,
    command: String,
    approved: bool,
) -> Result<CommandResult, String> {
    let root = canonical_workspace(&workspace)?;
    let (decision, reason) = command_policy(&command);

    if decision == "deny" || (decision == "ask" && !approved) {
        return Ok(CommandResult {
            decision: decision.to_string(),
            reason: reason.to_string(),
            executed: false,
            exit_code: None,
            stdout: String::new(),
            stderr: String::new(),
        });
    }

    #[cfg(target_os = "windows")]
    let output = Command::new("cmd")
        .args(["/C", &command])
        .current_dir(&root)
        .output();

    #[cfg(not(target_os = "windows"))]
    let output = Command::new("sh")
        .args(["-lc", &command])
        .current_dir(&root)
        .output();

    let output = output.map_err(|error| format!("Unable to start command: {error}"))?;
    let truncate = |value: Vec<u8>| {
        let mut text = String::from_utf8_lossy(&value).to_string();
        if text.len() > 100_000 {
            text.truncate(100_000);
            text.push_str("\n[output truncated]");
        }
        text
    };

    Ok(CommandResult {
        decision: decision.to_string(),
        reason: reason.to_string(),
        executed: true,
        exit_code: output.status.code(),
        stdout: truncate(output.stdout),
        stderr: truncate(output.stderr),
    })
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![
            ollama_chat,
            list_workspace,
            read_workspace_file,
            run_workspace_command
        ])
        .run(tauri::generate_context!())
        .expect("error while running OmniTerm desktop");
}
