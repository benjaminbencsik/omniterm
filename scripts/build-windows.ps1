$ErrorActionPreference = "Stop"

Write-Host "OmniTerm local Windows build" -ForegroundColor Cyan

function Require-Command($name, $installHint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "Missing required command: $name" -ForegroundColor Red
        Write-Host $installHint -ForegroundColor Yellow
        exit 1
    }
}

Require-Command "node" "Install Node.js LTS from https://nodejs.org or run: winget install OpenJS.NodeJS.LTS"
Require-Command "npm" "npm is installed with Node.js"
Require-Command "cargo" "Install Rust from https://rustup.rs or run: winget install Rustlang.Rustup"

$repoRoot = Split-Path -Parent $PSScriptRoot
$desktopDir = Join-Path $repoRoot "apps\desktop"

if (-not (Test-Path $desktopDir)) {
    throw "Desktop source folder not found: $desktopDir"
}

Set-Location $desktopDir

Write-Host "Installing frontend dependencies..." -ForegroundColor Cyan
npm install

Write-Host "Building OmniTerm desktop installer..." -ForegroundColor Cyan
npm run tauri build

$bundleDir = Join-Path $desktopDir "src-tauri\target\release\bundle"
Write-Host "Build complete." -ForegroundColor Green
Write-Host "Installers are located in:" -ForegroundColor Green
Write-Host $bundleDir

$nsis = Get-ChildItem -Path (Join-Path $bundleDir "nsis") -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
$msi = Get-ChildItem -Path (Join-Path $bundleDir "msi") -Filter "*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($nsis) {
    Write-Host "Windows setup executable:" -ForegroundColor Green
    Write-Host $nsis.FullName
}
if ($msi) {
    Write-Host "Windows MSI installer:" -ForegroundColor Green
    Write-Host $msi.FullName
}

Write-Host "You can now double-click the installer." -ForegroundColor Cyan
