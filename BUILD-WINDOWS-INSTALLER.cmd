@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title OmniTerm Windows Installer Builder

set "DESKTOP_DIR=%~dp0apps\desktop"
set "OUTPUT_DIR=%DESKTOP_DIR%\src-tauri\target\release\bundle\nsis"

echo ============================================================
echo OmniTerm Windows Installer Builder
echo ============================================================
echo.
echo This developer tool compiles the real OmniTerm setup EXE.
echo It is not the OmniTerm application itself.
echo.

if not exist "%DESKTOP_DIR%\package.json" (
  echo ERROR: Desktop project not found:
  echo %DESKTOP_DIR%
  goto :failed
)

where node >nul 2>&1
if errorlevel 1 (
  echo ERROR: Node.js was not found.
  echo Install Node.js 20 or newer, reopen this folder, and try again.
  goto :failed
)

where npm >nul 2>&1
if errorlevel 1 (
  echo ERROR: npm was not found.
  echo Reinstall Node.js, reopen this folder, and try again.
  goto :failed
)

where cargo >nul 2>&1
if errorlevel 1 (
  echo ERROR: Rust was not found.
  echo Install Rust from https://rustup.rs, reopen this folder, and try again.
  goto :failed
)

echo Node.js:
node --version
echo npm:
call npm --version
echo Rust:
cargo --version
echo.

echo Installing desktop dependencies...
pushd "%DESKTOP_DIR%"
call npm install
if errorlevel 1 (
  popd
  echo.
  echo ERROR: npm install failed.
  goto :failed
)

echo.
echo Building the Windows NSIS installer...
call npm run tauri build
if errorlevel 1 (
  popd
  echo.
  echo ERROR: The Tauri build failed.
  echo.
  echo Confirm that Microsoft Visual Studio Build Tools is installed with:
  echo   Desktop development with C++
  echo.
  echo Also confirm that Microsoft Edge WebView2 Runtime is installed.
  goto :failed
)
popd

if not exist "%OUTPUT_DIR%" (
  echo.
  echo ERROR: Build completed, but the NSIS output folder was not found:
  echo %OUTPUT_DIR%
  goto :failed
)

set "INSTALLER_FOUND="
for %%F in ("%OUTPUT_DIR%\*-setup.exe") do (
  if exist "%%~fF" set "INSTALLER_FOUND=%%~fF"
)

if not defined INSTALLER_FOUND (
  echo.
  echo ERROR: No setup executable was found in:
  echo %OUTPUT_DIR%
  goto :failed
)

echo.
echo ============================================================
echo BUILD SUCCEEDED
echo ============================================================
echo.
echo Installer:
echo %INSTALLER_FOUND%
echo.
echo File Explorer will open the installer folder now.
start "" explorer.exe "%OUTPUT_DIR%"
echo.
echo Test the setup EXE before uploading it to GitHub Releases.
echo.
pause
exit /b 0

:failed
echo.
echo ============================================================
echo BUILD FAILED
echo ============================================================
echo Review the error above, then press any key to close this window.
echo.
pause >nul
exit /b 1
