$ErrorActionPreference = 'Stop'
$logPath = Join-Path $PSScriptRoot 'OMNITERM-ERROR.txt'

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'OmniTerm'
    $form.Size = New-Object System.Drawing.Size(1000,700)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = [System.Drawing.Color]::FromArgb(17,24,39)
    $form.ForeColor = [System.Drawing.Color]::White

    $provider = New-Object System.Windows.Forms.ComboBox
    $provider.Location = New-Object System.Drawing.Point(20,20)
    $provider.Size = New-Object System.Drawing.Size(200,30)
    $provider.DropDownStyle = 'DropDownList'
    [void]$provider.Items.AddRange(@('OpenAI','Anthropic','Google Gemini'))
    $provider.SelectedIndex = 0

    $keyBox = New-Object System.Windows.Forms.TextBox
    $keyBox.Location = New-Object System.Drawing.Point(240,20)
    $keyBox.Size = New-Object System.Drawing.Size(300,30)
    $keyBox.UseSystemPasswordChar = $true

    $model = New-Object System.Windows.Forms.ComboBox
    $model.Location = New-Object System.Drawing.Point(560,20)
    $model.Size = New-Object System.Drawing.Size(220,30)
    $model.DropDownStyle = 'DropDown'

    $loadModels = New-Object System.Windows.Forms.Button
    $loadModels.Location = New-Object System.Drawing.Point(800,18)
    $loadModels.Size = New-Object System.Drawing.Size(150,34)
    $loadModels.Text = 'Load models'

    $chat = New-Object System.Windows.Forms.RichTextBox
    $chat.Location = New-Object System.Drawing.Point(20,70)
    $chat.Size = New-Object System.Drawing.Size(930,500)
    $chat.ReadOnly = $true
    $chat.BackColor = [System.Drawing.Color]::FromArgb(31,41,55)
    $chat.ForeColor = [System.Drawing.Color]::White
    $chat.Font = New-Object System.Drawing.Font('Segoe UI',11)

    $prompt = New-Object System.Windows.Forms.TextBox
    $prompt.Location = New-Object System.Drawing.Point(20,590)
    $prompt.Size = New-Object System.Drawing.Size(800,55)
    $prompt.Multiline = $true
    $prompt.ScrollBars = 'Vertical'

    $send = New-Object System.Windows.Forms.Button
    $send.Location = New-Object System.Drawing.Point(840,590)
    $send.Size = New-Object System.Drawing.Size(110,55)
    $send.Text = 'Send'

    $status = New-Object System.Windows.Forms.Label
    $status.Location = New-Object System.Drawing.Point(20,650)
    $status.Size = New-Object System.Drawing.Size(930,20)
    $status.Text = 'Ready'
    $status.ForeColor = [System.Drawing.Color]::LightBlue

    $form.Controls.AddRange(@($provider,$keyBox,$model,$loadModels,$chat,$prompt,$send,$status))

    $history = New-Object System.Collections.ArrayList

    function Set-DefaultModels {
        $model.Items.Clear()
        switch ($provider.SelectedItem) {
            'Anthropic' { [void]$model.Items.AddRange(@('claude-sonnet-4-5','claude-opus-4-1','claude-haiku-4-5')) }
            'Google Gemini' { [void]$model.Items.AddRange(@('gemini-2.5-flash','gemini-2.5-pro','gemini-2.0-flash')) }
            default { [void]$model.Items.AddRange(@('gpt-5-mini','gpt-5','gpt-4.1-mini')) }
        }
        $model.SelectedIndex = 0
    }

    function Add-ChatLine([string]$speaker,[string]$text) {
        $chat.AppendText("${speaker}:`r`n${text}`r`n`r`n")
        $chat.SelectionStart = $chat.Text.Length
        $chat.ScrollToCaret()
    }

    function Invoke-OpenAI([string]$apiKey,[string]$modelName) {
        $messages = @($history | ForEach-Object { @{ role = $_.role; content = $_.content } })
        $body = @{ model = $modelName; messages = $messages } | ConvertTo-Json -Depth 8
        $headers = @{ Authorization = "Bearer $apiKey" }
        $result = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -ContentType 'application/json' -Body $body
        return [string]$result.choices[0].message.content
    }

    function Invoke-Anthropic([string]$apiKey,[string]$modelName) {
        $messages = @($history | ForEach-Object { @{ role = $(if ($_.role -eq 'assistant') {'assistant'} else {'user'}); content = $_.content } })
        $body = @{ model = $modelName; max_tokens = 4096; messages = $messages } | ConvertTo-Json -Depth 8
        $headers = @{ 'x-api-key' = $apiKey; 'anthropic-version' = '2023-06-01' }
        $result = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $headers -ContentType 'application/json' -Body $body
        return (($result.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n")
    }

    function Invoke-Gemini([string]$apiKey,[string]$modelName) {
        $contents = @($history | ForEach-Object { @{ role = $(if ($_.role -eq 'assistant') {'model'} else {'user'}); parts = @(@{ text = $_.content }) } })
        $body = @{ contents = $contents } | ConvertTo-Json -Depth 10
        $headers = @{ 'x-goog-api-key' = $apiKey }
        $uri = "https://generativelanguage.googleapis.com/v1beta/models/$modelName`:generateContent"
        $result = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ContentType 'application/json' -Body $body
        return (($result.candidates[0].content.parts | ForEach-Object { $_.text }) -join "`n")
    }

    $provider.Add_SelectedIndexChanged({ Set-DefaultModels })
    $loadModels.Add_Click({ Set-DefaultModels; $status.Text = 'Models loaded.' })

    $send.Add_Click({
        $text = $prompt.Text.Trim()
        $apiKey = $keyBox.Text.Trim()
        $modelName = $model.Text.Trim()
        if (-not $text) { return }
        if (-not $apiKey) { [System.Windows.Forms.MessageBox]::Show('Enter an API key first.','OmniTerm'); return }
        if (-not $modelName) { [System.Windows.Forms.MessageBox]::Show('Choose or enter a model.','OmniTerm'); return }

        [void]$history.Add([pscustomobject]@{ role = 'user'; content = $text })
        Add-ChatLine 'You' $text
        $prompt.Clear()
        $send.Enabled = $false
        $status.Text = 'Working...'
        $form.Refresh()

        try {
            switch ($provider.SelectedItem) {
                'Anthropic' { $reply = Invoke-Anthropic $apiKey $modelName }
                'Google Gemini' { $reply = Invoke-Gemini $apiKey $modelName }
                default { $reply = Invoke-OpenAI $apiKey $modelName }
            }
            if (-not $reply) { $reply = 'The provider returned an empty response.' }
            [void]$history.Add([pscustomobject]@{ role = 'assistant'; content = $reply })
            Add-ChatLine 'OmniTerm' $reply
            $status.Text = 'Ready'
        }
        catch {
            $message = $_.Exception.Message
            Add-ChatLine 'Error' $message
            $status.Text = 'Request failed.'
        }
        finally { $send.Enabled = $true }
    })

    Set-DefaultModels
    Add-ChatLine 'OmniTerm' 'Welcome. Choose OpenAI, Anthropic, or Google Gemini, enter your API key, and send a message.'
    [void]$form.ShowDialog()
}
catch {
    $details = @(
        'OmniTerm failed to start.'
        ''
        $_.Exception.ToString()
        ''
        $_.ScriptStackTrace
    ) -join "`r`n"
    $details | Set-Content -Path $logPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("OmniTerm could not start.`r`n`r`nThe error was saved to:`r`n$logPath", 'OmniTerm startup error', 'OK', 'Error') | Out-Null
    exit 1
}
