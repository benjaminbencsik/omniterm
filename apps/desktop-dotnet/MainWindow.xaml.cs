using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using Forms = System.Windows.Forms;

namespace OmniTerm;

public partial class MainWindow : Window
{
    private readonly HttpClient _http = new() { Timeout = TimeSpan.FromMinutes(5) };
    private readonly List<ChatMessage> _messages = [];
    private string? _workspace;

    public MainWindow()
    {
        InitializeComponent();
        AddMessage("assistant", "Welcome to OmniTerm. Choose OpenAI, Anthropic, or Google Gemini, then enter your API key and load models.");
    }

    private string Provider => ((ProviderCombo.SelectedItem as ComboBoxItem)?.Tag as string) ?? "openai";
    private string Endpoint => EndpointBox.Text.Trim().TrimEnd('/');
    private string Model => ModelCombo.Text.Trim();
    private string ApiKey => ApiKeyBox.Password.Trim();

    private void ProviderCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (!IsLoaded) return;

        ModelCombo.Items.Clear();
        ApiKeyBox.Clear();

        switch (Provider)
        {
            case "anthropic":
                EndpointBox.Text = "https://api.anthropic.com/v1";
                ModelCombo.Text = "claude-sonnet-4-5";
                break;
            case "gemini":
                EndpointBox.Text = "https://generativelanguage.googleapis.com/v1beta";
                ModelCombo.Text = "gemini-2.5-flash";
                break;
            default:
                EndpointBox.Text = "https://api.openai.com/v1";
                ModelCombo.Text = "gpt-5-mini";
                break;
        }

        SetStatus("Provider changed. Enter an API key and load models.");
    }

    private async void LoadModels_Click(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(ApiKey))
        {
            SetStatus("Enter an API key first.");
            return;
        }

        try
        {
            SetBusy("Loading models...");
            ModelCombo.Items.Clear();

            var models = Provider switch
            {
                "anthropic" => await LoadAnthropicModelsAsync(),
                "gemini" => await LoadGeminiModelsAsync(),
                _ => await LoadOpenAiModelsAsync()
            };

            foreach (var model in models) ModelCombo.Items.Add(model);
            if (models.Count > 0) ModelCombo.SelectedIndex = 0;
            SetStatus(models.Count == 0 ? "Connected, but no models were returned." : $"Loaded {models.Count} model(s).");
        }
        catch (Exception ex)
        {
            SetStatus($"Model loading failed: {ex.Message}");
        }
    }

    private async Task<List<string>> LoadOpenAiModelsAsync()
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"{Endpoint}/models");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);
        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        return document.RootElement.GetProperty("data").EnumerateArray()
            .Select(item => item.GetProperty("id").GetString())
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .OrderBy(id => id)
            .ToList();
    }

    private async Task<List<string>> LoadAnthropicModelsAsync()
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"{Endpoint}/models?limit=100");
        request.Headers.Add("x-api-key", ApiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");
        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        return document.RootElement.GetProperty("data").EnumerateArray()
            .Select(item => item.GetProperty("id").GetString())
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Cast<string>()
            .OrderBy(id => id)
            .ToList();
    }

    private async Task<List<string>> LoadGeminiModelsAsync()
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, $"{Endpoint}/models?pageSize=1000");
        request.Headers.Add("x-goog-api-key", ApiKey);
        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        return document.RootElement.GetProperty("models").EnumerateArray()
            .Where(item => item.TryGetProperty("supportedGenerationMethods", out var methods)
                           && methods.EnumerateArray().Any(method => method.GetString() == "generateContent"))
            .Select(item => item.GetProperty("name").GetString()?.Replace("models/", string.Empty, StringComparison.Ordinal))
            .Where(name => !string.IsNullOrWhiteSpace(name))
            .Cast<string>()
            .OrderBy(name => name)
            .ToList();
    }

    private async void Send_Click(object sender, RoutedEventArgs e)
    {
        var prompt = PromptBox.Text.Trim();
        if (string.IsNullOrWhiteSpace(prompt) || string.IsNullOrWhiteSpace(Model)) return;
        if (string.IsNullOrWhiteSpace(ApiKey))
        {
            SetStatus("Enter an API key first.");
            return;
        }

        AddMessage("user", prompt);
        PromptBox.Clear();

        try
        {
            SetBusy("OmniTerm is working...");
            var reply = Provider switch
            {
                "anthropic" => await SendAnthropicChatAsync(),
                "gemini" => await SendGeminiChatAsync(),
                _ => await SendOpenAiChatAsync()
            };
            AddMessage("assistant", reply);
            SetStatus("Ready");
        }
        catch (Exception ex)
        {
            AddMessage("assistant", $"The provider request failed: {ex.Message}");
            SetStatus($"Chat failed: {ex.Message}");
        }
    }

    private async Task<string> SendOpenAiChatAsync()
    {
        var payload = JsonSerializer.Serialize(new
        {
            model = Model,
            messages = _messages.Select(message => new { role = message.Role, content = message.Content })
        });

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{Endpoint}/chat/completions")
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json")
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", ApiKey);

        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        return document.RootElement.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString()
               ?? "OpenAI returned an empty response.";
    }

    private async Task<string> SendAnthropicChatAsync()
    {
        var payload = JsonSerializer.Serialize(new
        {
            model = Model,
            max_tokens = 4096,
            messages = _messages.Select(message => new
            {
                role = message.Role == "assistant" ? "assistant" : "user",
                content = message.Content
            })
        });

        using var request = new HttpRequestMessage(HttpMethod.Post, $"{Endpoint}/messages")
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-api-key", ApiKey);
        request.Headers.Add("anthropic-version", "2023-06-01");

        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        var parts = document.RootElement.GetProperty("content").EnumerateArray()
            .Where(item => item.TryGetProperty("type", out var type) && type.GetString() == "text")
            .Select(item => item.GetProperty("text").GetString())
            .Where(value => !string.IsNullOrWhiteSpace(value));
        return string.Join("\n", parts) is { Length: > 0 } result
            ? result
            : "Anthropic returned an empty response.";
    }

    private async Task<string> SendGeminiChatAsync()
    {
        var contents = _messages.Select(message => new
        {
            role = message.Role == "assistant" ? "model" : "user",
            parts = new[] { new { text = message.Content } }
        });

        var payload = JsonSerializer.Serialize(new { contents });
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{Endpoint}/models/{Uri.EscapeDataString(Model)}:generateContent")
        {
            Content = new StringContent(payload, Encoding.UTF8, "application/json")
        };
        request.Headers.Add("x-goog-api-key", ApiKey);

        using var response = await _http.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException(text);

        using var document = JsonDocument.Parse(text);
        var parts = document.RootElement.GetProperty("candidates")[0]
            .GetProperty("content").GetProperty("parts").EnumerateArray()
            .Where(item => item.TryGetProperty("text", out _))
            .Select(item => item.GetProperty("text").GetString())
            .Where(value => !string.IsNullOrWhiteSpace(value));
        return string.Join("\n", parts) is { Length: > 0 } result
            ? result
            : "Gemini returned an empty response.";
    }

    private void AddMessage(string role, string content)
    {
        _messages.Add(new ChatMessage(role, content));
        var speaker = role == "assistant" ? "OmniTerm" : "You";
        ChatTranscript.AppendText($"{speaker}:\n{content}\n\n");
        ChatTranscript.ScrollToEnd();
    }

    private void ClearChat_Click(object sender, RoutedEventArgs e)
    {
        _messages.Clear();
        ChatTranscript.Clear();
        AddMessage("assistant", "Chat cleared. What would you like to work on?");
    }

    private void ChooseWorkspace_Click(object sender, RoutedEventArgs e)
    {
        using var dialog = new Forms.FolderBrowserDialog
        {
            Description = "Choose a project folder for OmniTerm",
            UseDescriptionForTitle = true,
            ShowNewFolderButton = true
        };
        if (dialog.ShowDialog() != Forms.DialogResult.OK) return;
        _workspace = Path.GetFullPath(dialog.SelectedPath);
        WorkspaceText.Text = _workspace;
        RefreshWorkspaceFiles();
        SetStatus("Workspace connected.");
    }

    private void RefreshWorkspaceFiles()
    {
        FileList.Items.Clear();
        FilePreview.Clear();
        if (_workspace is null) return;

        try
        {
            foreach (var file in Directory.EnumerateFiles(_workspace, "*", SearchOption.AllDirectories).Take(1000))
            {
                var relative = Path.GetRelativePath(_workspace, file);
                FileList.Items.Add(new WorkspaceFile(relative, file));
            }
        }
        catch (Exception ex)
        {
            SetStatus($"Could not list all files: {ex.Message}");
        }
    }

    private async void FileList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (FileList.SelectedItem is not WorkspaceFile selected) return;

        try
        {
            var info = new FileInfo(selected.FullPath);
            if (info.Length > 1_048_576)
            {
                FilePreview.Text = "This file is larger than 1 MB and was not opened.";
                return;
            }
            FilePreview.Text = await File.ReadAllTextAsync(selected.FullPath);
        }
        catch (Exception ex)
        {
            FilePreview.Text = $"Unable to preview this file: {ex.Message}";
        }
    }

    private async void RunCommand_Click(object sender, RoutedEventArgs e)
    {
        if (_workspace is null)
        {
            SetStatus("Choose a workspace first.");
            return;
        }

        var command = CommandBox.Text.Trim();
        if (string.IsNullOrWhiteSpace(command)) return;
        if (IsBlockedCommand(command))
        {
            CommandOutput.Text = "This command was blocked because it appears destructive or privileged.";
            return;
        }

        if (!IsReadOnlyCommand(command))
        {
            var choice = MessageBox.Show($"Allow this command once?\n\n{command}", "OmniTerm approval", MessageBoxButton.YesNo, MessageBoxImage.Warning);
            if (choice != MessageBoxResult.Yes) return;
        }

        try
        {
            SetBusy("Running workspace command...");
            var startInfo = new ProcessStartInfo("cmd.exe", $"/d /s /c \"{command}\"")
            {
                WorkingDirectory = _workspace,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using var process = Process.Start(startInfo) ?? throw new InvalidOperationException("Windows could not start the command.");
            var stdoutTask = process.StandardOutput.ReadToEndAsync();
            var stderrTask = process.StandardError.ReadToEndAsync();
            await process.WaitForExitAsync();
            CommandOutput.Text = $"> {command}\nExit code: {process.ExitCode}\n\n{await stdoutTask}{await stderrTask}";
            RefreshWorkspaceFiles();
            SetStatus("Command finished.");
        }
        catch (Exception ex)
        {
            CommandOutput.Text = $"> {command}\n{ex.Message}";
            SetStatus($"Command failed: {ex.Message}");
        }
    }

    private static bool IsReadOnlyCommand(string command)
    {
        var value = command.TrimStart().ToLowerInvariant();
        string[] safePrefixes = ["git status", "git diff", "git log", "dir", "type ", "where ", "dotnet --info", "dotnet --version"];
        return safePrefixes.Any(value.StartsWith);
    }

    private static bool IsBlockedCommand(string command)
    {
        var value = command.ToLowerInvariant();
        string[] blocked = ["format ", "diskpart", "shutdown", "reboot", "del /s", "rmdir /s", "rd /s", "remove-item -recurse", "runas "];
        return blocked.Any(value.Contains);
    }

    private void SetBusy(string text) => StatusText.Text = text;
    private void SetStatus(string text) => StatusText.Text = text;

    private sealed record ChatMessage(string Role, string Content);
    private sealed record WorkspaceFile(string RelativePath, string FullPath)
    {
        public override string ToString() => RelativePath;
    }
}
