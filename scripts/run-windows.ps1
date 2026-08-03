$ErrorActionPreference = "Stop"

function Require-Command($name, $installHint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "Missing required command: $name" -ForegroundColor Red
        Write-Host $installHint -ForegroundColor Yellow
        exit 1
    }
}

Require-Command "node" "Install Node.js LTS: winget install OpenJS.NodeJS.LTS"
Require-Command "npm" "npm is installed with Node.js"
Require-Command "cargo" "Install Rust: winget install Rustlang.Rustup"

$repoRoot = Split-Path -Parent $PSScriptRoot
$desktopDir = Join-Path $repoRoot "apps\desktop"
$exePath = Join-Path $desktopDir "src-tauri\target\release\omniterm-desktop.exe"

if (-not (Test-Path $desktopDir)) {
    throw "Desktop source folder not found: $desktopDir"
}

if (-not (Test-Path $exePath)) {
    Write-Host "First launch: building OmniTerm locally..." -ForegroundColor Cyan
    Set-Location $desktopDir
    npm install
    npm run tauri build
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
