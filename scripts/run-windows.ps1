$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$desktopDir = Join-Path $repoRoot "apps\desktop"
$logPath = Join-Path $repoRoot "omniterm-launch.log"
$exePath = Join-Path $desktopDir "src-tauri\target\release\omniterm-desktop.exe"

Start-Transcript -Path $logPath -Append | Out-Null

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $cargoPath = Join-Path $env:USERPROFILE ".cargo\bin"
    $env:Path = "$machinePath;$userPath;$cargoPath"
}

function Require-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "Windows Package Manager (winget) is required. Install 'App Installer' from the Microsoft Store, then run RUN-WINDOWS.cmd again."
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Name,
        [string[]]$ExtraArguments = @()
    )

    Write-Host "Installing $Name..." -ForegroundColor Cyan
    $arguments = @(
        "install",
        "--id", $Id,
        "--exact",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--silent"
    ) + $ExtraArguments

    & winget @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name installation failed with exit code $LASTEXITCODE. See $logPath for details."
    }

    Refresh-Path
}

function Test-VCTools {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        return $false
    }

    $installationPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    return -not [string]::IsNullOrWhiteSpace($installationPath)
}

try {
    Write-Host "OmniTerm Windows launcher" -ForegroundColor Cyan
    Write-Host "A log is being written to: $logPath" -ForegroundColor DarkGray

    if (-not (Test-Path $desktopDir)) {
        throw "Desktop source folder not found: $desktopDir"
    }

    Require-Winget
    Refresh-Path

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Install-WingetPackage -Id "OpenJS.NodeJS.LTS" -Name "Node.js LTS"
    }

    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Install-WingetPackage -Id "Rustlang.Rustup" -Name "Rust"
        $rustup = Join-Path $env:USERPROFILE ".cargo\bin\rustup.exe"
        if (Test-Path $rustup) {
            & $rustup default stable
            if ($LASTEXITCODE -ne 0) {
                throw "Rust stable toolchain setup failed."
            }
        }
        Refresh-Path
    }

    if (-not (Test-VCTools)) {
        Install-WingetPackage `
            -Id "Microsoft.VisualStudio.2022.BuildTools" `
            -Name "Microsoft C++ Build Tools" `
            -ExtraArguments @(
                "--override",
                "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
            )
    }

    $webViewRegistry = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F1E7E2FA-AD07-4305-9F31-8BC6A0C5A9D5}"
    if (-not (Test-Path $webViewRegistry)) {
        Install-WingetPackage -Id "Microsoft.EdgeWebView2Runtime" -Name "Microsoft Edge WebView2 Runtime"
    }

    Refresh-Path

    foreach ($command in @("node", "npm", "cargo")) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "$command was installed but is not available yet. Restart Windows, then run RUN-WINDOWS.cmd again."
        }
    }

    if (-not (Test-Path $exePath)) {
        Write-Host "Building OmniTerm for the first time..." -ForegroundColor Cyan
        Set-Location $desktopDir

        & npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed with exit code $LASTEXITCODE."
        }

        & npm run tauri build
        if ($LASTEXITCODE -ne 0) {
            throw "OmniTerm build failed with exit code $LASTEXITCODE."
        }
    }

    if (-not (Test-Path $exePath)) {
        $candidate = Get-ChildItem -Path (Join-Path $desktopDir "src-tauri\target\release") -Filter "*.exe" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.DirectoryName -notmatch "bundle" } |
            Select-Object -First 1
        if ($candidate) {
            $exePath = $candidate.FullName
        }
    }

    if (-not (Test-Path $exePath)) {
        throw "The OmniTerm executable was not found after the build."
    }

    Write-Host "Launching OmniTerm..." -ForegroundColor Green
    Start-Process -FilePath $exePath -WorkingDirectory $desktopDir
    Write-Host "OmniTerm started successfully." -ForegroundColor Green
}
catch {
    Write-Host "" 
    Write-Host "OmniTerm could not be started:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "" 
    Write-Host "Full details are saved in: $logPath" -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    exit 1
}

Stop-Transcript | Out-Null
