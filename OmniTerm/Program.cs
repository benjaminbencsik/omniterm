using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Windows.Forms;

namespace OmniTerm;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.ThreadException += (_, args) => ShowFatalError(args.Exception);
        AppDomain.CurrentDomain.UnhandledException += (_, args) =>
            ShowFatalError(args.ExceptionObject as Exception ?? new Exception("Unknown fatal error."));
        Application.Run(new MainForm());
    }

    private static void ShowFatalError(Exception exception)
    {
        try
        {
            var path = Path.Combine(AppContext.BaseDirectory, "OmniTerm-error.log");
            File.AppendAllText(path, $"[{DateTimeOffset.Now:O}]\r\n{exception}\r\n\r\n");
            MessageBox.Show(
                $"OmniTerm encountered an unexpected error.\r\n\r\n{exception.Message}\r\n\r\nA log was saved to:\r\n{path}",
                "OmniTerm",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
        catch
        {
            MessageBox.Show(exception.ToString(), "OmniTerm", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}

internal sealed class MainForm : Form
{
    private const string OpenAi = "OpenAI";
    private const string Anthropic = "Anthropic";
    private const string Gemini = "Google Gemini";

    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromMinutes(5) };
    private readonly List<ChatEntry> _history = new();
    private readonly Dictionary<string, string> _sessionKeys = new(StringComparer.Ordinal);

    private readonly ComboBox _provider = new();
    private readonly TextBox _apiKey = new();
    private readonly ComboBox _model = new();
    private readonly Button _loadModels = new();
    private readonly Button _clear = new();
    private readonly RichTextBox _transcript = new();
    private readonly TextBox _prompt = new();
    private readonly Button _send = new();
    private readonly Label _status = new();

    private string _lastProvider = OpenAi;

    public MainForm()
    {
        Text = "OmniTerm";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(850, 600);
        Size = new Size(1100, 760);
        BackColor = Color.FromArgb(17, 24, 39);
        ForeColor = Color.White;
        Font = new Font("Segoe UI", 10F);

        BuildInterface();
        ConfigureEvents();
        ApplyProviderDefaults(OpenAi);
        AppendMessage("OmniTerm", "Welcome. Choose OpenAI, Anthropic, or Google Gemini, enter your API key, and send a message.");
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _http.Dispose();
        }
        base.Dispose(disposing);
    }

    private void BuildInterface()
    {
        var header = new Panel
        {
            Dock = DockStyle.Top,
            Height = 112,
            Padding = new Padding(16, 12, 16, 8),
            BackColor = Color.FromArgb(31, 41, 55)
        };

        var title = new Label
        {
            Text = "OmniTerm",
            AutoSize = true,
            Font = new Font("Segoe UI", 20F, FontStyle.Bold),
            Location = new Point(16, 10)
        };

        _status.AutoSize = false;
        _status.Text = "Ready";
        _status.ForeColor = Color.LightSkyBlue;
        _status.TextAlign = ContentAlignment.MiddleRight;
        _status.Anchor = AnchorStyles.Top | AnchorStyles.Right;
        _status.Location = new Point(header.Width - 430, 18);
        _status.Size = new Size(400, 28);

        var controls = new FlowLayoutPanel
        {
            Location = new Point(16, 58),
            Size = new Size(1040, 44),
            Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right,
            WrapContents = false,
            AutoScroll = true,
            BackColor = Color.Transparent
        };

        _provider.DropDownStyle = ComboBoxStyle.DropDownList;
        _provider.Width = 145;
        _provider.Items.AddRange(new object[] { OpenAi, Anthropic, Gemini });
        _provider.SelectedIndex = 0;

        _apiKey.Width = 330;
        _apiKey.UseSystemPasswordChar = true;
        _apiKey.AccessibleName = "API key";

        _model.Width = 240;
        _model.DropDownStyle = ComboBoxStyle.DropDown;

        _loadModels.Text = "Load models";
        _loadModels.AutoSize = true;

        _clear.Text = "New chat";
        _clear.AutoSize = true;

        controls.Controls.Add(CreateLabel("Provider"));
        controls.Controls.Add(_provider);
        controls.Controls.Add(CreateLabel("API key"));
        controls.Controls.Add(_apiKey);
        controls.Controls.Add(CreateLabel("Model"));
        controls.Controls.Add(_model);
        controls.Controls.Add(_loadModels);
        controls.Controls.Add(_clear);

        header.Controls.Add(title);
        header.Controls.Add(_status);
        header.Controls.Add(controls);
        header.Resize += (_, _) => _status.Left = Math.Max(400, header.ClientSize.Width - _status.Width - 16);

        _transcript.Dock = DockStyle.Fill;
        _transcript.ReadOnly = true;
        _transcript.BorderStyle = BorderStyle.None;
        _transcript.BackColor = Color.FromArgb(17, 24, 39);
        _transcript.ForeColor = Color.White;
        _transcript.Font = new Font("Segoe UI", 11F);
        _transcript.DetectUrls = true;
        _transcript.Padding = new Padding(14);

        var composer = new Panel
        {
            Dock = DockStyle.Bottom,
            Height = 128,
            Padding = new Padding(16, 10, 16, 16),
            BackColor = Color.FromArgb(31, 41, 55)
        };

        _send.Text = "Send";
        _send.Dock = DockStyle.Right;
        _send.Width = 110;

        _prompt.Multiline = true;
        _prompt.AcceptsReturn = true;
        _prompt.ScrollBars = ScrollBars.Vertical;
        _prompt.Dock = DockStyle.Fill;
        _prompt.BackColor = Color.FromArgb(249, 250, 251);
        _prompt.ForeColor = Color.Black;
        _prompt.Font = new Font("Segoe UI", 11F);

        var hint = new Label
        {
            Text = "Ctrl+Enter to send",
            Dock = DockStyle.Bottom,
            Height = 24,
            ForeColor = Color.Silver,
            TextAlign = ContentAlignment.MiddleLeft
        };

        composer.Controls.Add(_prompt);
        composer.Controls.Add(_send);
        composer.Controls.Add(hint);

        Controls.Add(_transcript);
        Controls.Add(composer);
        Controls.Add(header);
    }

    private static Label CreateLabel(string text) => new()
    {
        Text = text,
        AutoSize = true,
        ForeColor = Color.Gainsboro,
        Margin = new Padding(8, 8, 4, 0)
    };

    private void ConfigureEvents()
    {
        _provider.SelectedIndexChanged += (_, _) => ProviderChanged();
        _loadModels.Click += async (_, _) => await LoadModelsAsync();
        _send.Click += async (_, _) => await SendAsync();
        _clear.Click += (_, _) => ClearConversation();
        _prompt.KeyDown += async (_, args) =>
        {
            if (args.Control && args.KeyCode == Keys.Enter)
            {
                args.SuppressKeyPress = true;
                await SendAsync();
            }
        };
    }

    private string SelectedProvider => _provider.SelectedItem?.ToString() ?? OpenAi;

    private void ProviderChanged()
    {
        _sessionKeys[_lastProvider] = _apiKey.Text.Trim();
        _lastProvider = SelectedProvider;
        _apiKey.Text = _sessionKeys.TryGetValue(_lastProvider, out var key) ? key : string.Empty;
        ApplyProviderDefaults(_lastProvider);
        SetStatus("Enter an API key, then load models or type a model name.");
    }

    private void ApplyProviderDefaults(string provider)
    {
        _model.Items.Clear();
        var defaultModel = provider switch
        {
            Anthropic => "claude-sonnet-4-5",
            Gemini => "gemini-3.5-flash",
            _ => "gpt-5-mini"
        };
        _model.Items.Add(defaultModel);
        _model.Text = defaultModel;
    }

    private async Task LoadModelsAsync()
    {
        var key = _apiKey.Text.Trim();
        if (string.IsNullOrWhiteSpace(key))
        {
            ShowMessage("Enter the API key for the selected provider first.", MessageBoxIcon.Information);
            return;
        }

        SetBusy(true, "Loading models...");
        try
        {
            var models = SelectedProvider switch
            {
                Anthropic => await LoadAnthropicModelsAsync(key),
                Gemini => await LoadGeminiModelsAsync(key),
                _ => await LoadOpenAiModelsAsync(key)
            };

            var previous = _model.Text.Trim();
            _model.BeginUpdate();
            _model.Items.Clear();
            foreach (var item in models.Distinct(StringComparer.Ordinal).OrderBy(item => item, StringComparer.Ordinal))
            {
                _model.Items.Add(item);
            }
            _model.EndUpdate();

            if (models.Contains(previous, StringComparer.Ordinal))
            {
                _model.Text = previous;
            }
            else if (_model.Items.Count > 0)
            {
                _model.SelectedIndex = 0;
            }

            SetStatus($"Loaded {_model.Items.Count} models.");
        }
        catch (Exception exception)
        {
            ShowMessage(exception.Message, MessageBoxIcon.Error);
            SetStatus("Could not load models.");
        }
        finally
        {
            SetBusy(false);
        }
    }

    private async Task SendAsync()
    {
        if (!_send.Enabled)
        {
            return;
        }

        var text = _prompt.Text.Trim();
        var key = _apiKey.Text.Trim();
        var model = _model.Text.Trim();

        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }
        if (string.IsNullOrWhiteSpace(key))
        {
            ShowMessage("Enter the API key for the selected provider first.", MessageBoxIcon.Information);
            return;
        }
        if (string.IsNullOrWhiteSpace(model))
        {
            ShowMessage("Choose or enter a model name first.", MessageBoxIcon.Information);
            return;
        }

        _history.Add(new ChatEntry("user", text));
        AppendMessage("You", text);
        _prompt.Clear();
        SetBusy(true, "Waiting for a response...");

        try
        {
            var reply = SelectedProvider switch
            {
                Anthropic => await SendAnthropicAsync(key, model),
                Gemini => await SendGeminiAsync(key, model),
                _ => await SendOpenAiAsync(key, model)
            };

            if (string.IsNullOrWhiteSpace(reply))
            {
                reply = "The provider returned an empty response.";
            }

            _history.Add(new ChatEntry("assistant", reply));
            AppendMessage("OmniTerm", reply);
            SetStatus("Ready");
        }
        catch (Exception exception)
        {
            if (_history.Count > 0 && _history[^1].Role == "user")
            {
                _history.RemoveAt(_history.Count - 1);
            }
            AppendMessage("Error", exception.Message);
            SetStatus("Request failed.");
        }
        finally
        {
            SetBusy(false);
            _prompt.Focus();
        }
    }

    private async Task<List<string>> LoadOpenAiModelsAsync(string key)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "https://api.openai.com/v1/models");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);
        return document.RootElement.GetProperty("data").EnumerateArray()
            .Select(item => item.TryGetProperty("id", out var id) ? id.GetString() : null)
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .ToList();
    }

    private async Task<List<string>> LoadAnthropicModelsAsync(string key)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "https://api.anthropic.com/v1/models?limit=1000");
        AddAnthropicHeaders(request, key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);
        return document.RootElement.GetProperty("data").EnumerateArray()
            .Select(item => item.TryGetProperty("id", out var id) ? id.GetString() : null)
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .ToList();
    }

    private async Task<List<string>> LoadGeminiModelsAsync(string key)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000");
        request.Headers.Add("x-goog-api-key", key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);

        var result = new List<string>();
        foreach (var item in document.RootElement.GetProperty("models").EnumerateArray())
        {
            if (!item.TryGetProperty("supportedGenerationMethods", out var methods) ||
                !methods.EnumerateArray().Any(method => method.GetString() == "generateContent"))
            {
                continue;
            }

            if (item.TryGetProperty("name", out var name))
            {
                var value = name.GetString();
                if (!string.IsNullOrWhiteSpace(value))
                {
                    result.Add(value.StartsWith("models/", StringComparison.Ordinal) ? value[7..] : value);
                }
            }
        }
        return result;
    }

    private async Task<string> SendOpenAiAsync(string key, string model)
    {
        var input = _history.Select(message => new { role = message.Role, content = message.Content }).ToArray();
        var payload = JsonSerializer.Serialize(new { model, input });

        using var request = CreateJsonRequest(HttpMethod.Post, "https://api.openai.com/v1/responses", payload);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key);
        using var response = await _http.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        if (response.IsSuccessStatusCode)
        {
            var text = ParseOpenAiResponse(body);
            if (!string.IsNullOrWhiteSpace(text))
            {
                return text;
            }
        }
        else if (response.StatusCode is not HttpStatusCode.BadRequest and not HttpStatusCode.NotFound)
        {
            throw CreateApiException(response.StatusCode, body);
        }

        return await SendOpenAiChatFallbackAsync(key, model);
    }

    private async Task<string> SendOpenAiChatFallbackAsync(string key, string model)
    {
        var messages = _history.Select(message => new { role = message.Role, content = message.Content }).ToArray();
        var payload = JsonSerializer.Serialize(new { model, messages });
        using var request = CreateJsonRequest(HttpMethod.Post, "https://api.openai.com/v1/chat/completions", payload);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);
        return document.RootElement.GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? string.Empty;
    }

    private async Task<string> SendAnthropicAsync(string key, string model)
    {
        var messages = _history.Select(message => new
        {
            role = message.Role == "assistant" ? "assistant" : "user",
            content = message.Content
        }).ToArray();
        var payload = JsonSerializer.Serialize(new { model, max_tokens = 4096, messages });

        using var request = CreateJsonRequest(HttpMethod.Post, "https://api.anthropic.com/v1/messages", payload);
        AddAnthropicHeaders(request, key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);

        return string.Join("\n", document.RootElement.GetProperty("content").EnumerateArray()
            .Where(item => item.TryGetProperty("type", out var type) && type.GetString() == "text")
            .Select(item => item.TryGetProperty("text", out var text) ? text.GetString() : null)
            .Where(text => !string.IsNullOrWhiteSpace(text)));
    }

    private async Task<string> SendGeminiAsync(string key, string model)
    {
        var contents = _history.Select(message => new
        {
            role = message.Role == "assistant" ? "model" : "user",
            parts = new[] { new { text = message.Content } }
        }).ToArray();
        var payload = JsonSerializer.Serialize(new { contents });
        var escapedModel = Uri.EscapeDataString(model);

        using var request = CreateJsonRequest(
            HttpMethod.Post,
            $"https://generativelanguage.googleapis.com/v1beta/models/{escapedModel}:generateContent",
            payload);
        request.Headers.Add("x-goog-api-key", key);
        using var response = await _http.SendAsync(request);
        var body = await ReadSuccessfulBodyAsync(response);
        using var document = JsonDocument.Parse(body);

        if (!document.RootElement.TryGetProperty("candidates", out var candidates) || candidates.GetArrayLength() == 0)
        {
            return string.Empty;
        }

        return string.Join("\n", candidates[0].GetProperty("content").GetProperty("parts").EnumerateArray()
            .Select(part => part.TryGetProperty("text", out var text) ? text.GetString() : null)
            .Where(text => !string.IsNullOrWhiteSpace(text)));
    }

    private static HttpRequestMessage CreateJsonRequest(HttpMethod method, string uri, string json) => new(method, uri)
    {
        Content = new StringContent(json, Encoding.UTF8, "application/json")
    };

    private static void AddAnthropicHeaders(HttpRequestMessage request, string key)
    {
        request.Headers.Add("x-api-key", key);
        request.Headers.Add("anthropic-version", "2023-06-01");
    }

    private static async Task<string> ReadSuccessfulBodyAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
        {
            throw CreateApiException(response.StatusCode, body);
        }
        return body;
    }

    private static Exception CreateApiException(HttpStatusCode statusCode, string body)
    {
        var message = TryExtractApiError(body);
        return new InvalidOperationException($"API request failed ({(int)statusCode} {statusCode}).\r\n{message}");
    }

    private static string TryExtractApiError(string body)
    {
        try
        {
            using var document = JsonDocument.Parse(body);
            var root = document.RootElement;
            if (root.TryGetProperty("error", out var error))
            {
                if (error.ValueKind == JsonValueKind.String)
                {
                    return error.GetString() ?? body;
                }
                if (error.TryGetProperty("message", out var message))
                {
                    return message.GetString() ?? body;
                }
            }
        }
        catch
        {
            // Fall through to the raw response.
        }
        return string.IsNullOrWhiteSpace(body) ? "The provider returned no error details." : body;
    }

    private static string ParseOpenAiResponse(string body)
    {
        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;
        if (root.TryGetProperty("output_text", out var directText) && directText.ValueKind == JsonValueKind.String)
        {
            return directText.GetString() ?? string.Empty;
        }

        if (!root.TryGetProperty("output", out var output))
        {
            return string.Empty;
        }

        var parts = new List<string>();
        foreach (var item in output.EnumerateArray())
        {
            if (!item.TryGetProperty("content", out var content))
            {
                continue;
            }
            foreach (var part in content.EnumerateArray())
            {
                if (part.TryGetProperty("type", out var type) && type.GetString() == "output_text" &&
                    part.TryGetProperty("text", out var text) && !string.IsNullOrWhiteSpace(text.GetString()))
                {
                    parts.Add(text.GetString()!);
                }
            }
        }
        return string.Join("\n", parts);
    }

    private void ClearConversation()
    {
        _history.Clear();
        _transcript.Clear();
        AppendMessage("OmniTerm", "New chat started.");
        SetStatus("Ready");
        _prompt.Focus();
    }

    private void AppendMessage(string speaker, string text)
    {
        _transcript.SelectionStart = _transcript.TextLength;
        _transcript.SelectionFont = new Font(_transcript.Font, FontStyle.Bold);
        _transcript.SelectionColor = speaker == "Error" ? Color.LightCoral : Color.LightSkyBlue;
        _transcript.AppendText($"{speaker}\r\n");
        _transcript.SelectionFont = _transcript.Font;
        _transcript.SelectionColor = Color.White;
        _transcript.AppendText($"{text}\r\n\r\n");
        _transcript.SelectionStart = _transcript.TextLength;
        _transcript.ScrollToCaret();
    }

    private void SetBusy(bool busy, string? status = null)
    {
        _send.Enabled = !busy;
        _loadModels.Enabled = !busy;
        _provider.Enabled = !busy;
        _model.Enabled = !busy;
        if (status is not null)
        {
            SetStatus(status);
        }
        UseWaitCursor = busy;
    }

    private void SetStatus(string text) => _status.Text = text;

    private void ShowMessage(string text, MessageBoxIcon icon) =>
        MessageBox.Show(this, text, "OmniTerm", MessageBoxButtons.OK, icon);

    private sealed record ChatEntry(string Role, string Content);
}
