use serde::{Deserialize, Serialize};

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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![ollama_chat])
        .run(tauri::generate_context!())
        .expect("error while running OmniTerm desktop");
}
