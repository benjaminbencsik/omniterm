@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title OmniTerm Windows Installer Builder

set "DESKTOP_DIR=%~dp0apps\desktop"
set "OUTPUT_DIR=%DESKTOP_DIR%\src-tauri\target\release\bundle\nsis"
set "NEEDS_RESTART=0"

echo ============================================================
echo OmniTerm Windows Installer Builder
echo ============================================================
echo.
echo This developer tool installs the build requirements and then
echo compiles the real OmniTerm Windows setup EXE.
echo.
echo Windows may ask for permission while installing required tools.
echo.

if not exist "%DESKTOP_DIR%\package.json" (
  echo ERROR: The OmniTerm desktop project was not found.
  echo.
  echo Do not run this file from inside the ZIP preview window.
  echo Right-click the downloaded ZIP, choose Extract All, open the
  echo extracted omniterm-main folder, and run this file there.
  echo.
  echo Expected project folder:
  echo %DESKTOP_DIR%
  goto :failed
)

where winget >nul 2>&1
if errorlevel 1 (
  echo ERROR: Windows Package Manager ^(winget^) was not found.
  echo.
  echo Install or update "App Installer" from the Microsoft Store,
  echo restart Windows, and run this builder again.
  goto :failed
)

call :install_if_missing node "OpenJS.NodeJS.LTS" "Node.js LTS"
if errorlevel 1 goto :failed

call :install_if_missing cargo "Rustlang.Rustup" "Rust"
if errorlevel 1 goto :failed

call :install_package_if_missing "Microsoft.VisualStudio.2022.BuildTools" "Visual Studio 2022 Build Tools" "--override \"--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended\""
if errorlevel 1 goto :failed

call :install_package_if_missing "Microsoft.EdgeWebView2Runtime" "Microsoft Edge WebView2 Runtime" ""
if errorlevel 1 goto :failed

rem Refresh PATH for tools installed during this run.
set "PATH=%ProgramFiles%\nodejs;%USERPROFILE%\.cargo\bin;%PATH%"

where node >nul 2>&1
if errorlevel 1 (
  echo ERROR: Node.js was installed, but Windows has not made it available yet.
  set "NEEDS_RESTART=1"
)

where npm >nul 2>&1
if errorlevel 1 (
  echo ERROR: npm was installed, but Windows has not made it available yet.
  set "NEEDS_RESTART=1"
)

where cargo >nul 2>&1
if errorlevel 1 (
  echo ERROR: Rust was installed, but Windows has not made it available yet.
  set "NEEDS_RESTART=1"
)

if "%NEEDS_RESTART%"=="1" (
  echo.
  echo Restart Windows, then double-click this builder again.
  goto :failed
)

echo.
echo Build tools ready:
echo.
echo Node.js:
node --version
echo npm:
call npm --version
echo Rust:
cargo --version
echo.

echo Installing OmniTerm desktop dependencies...
pushd "%DESKTOP_DIR%"
call npm install
if errorlevel 1 (
  popd
  echo.
  echo ERROR: npm install failed.
  goto :failed
)

echo.
echo Building the Windows installer...
call npm run tauri build
if errorlevel 1 (
  popd
  echo.
  echo ERROR: The OmniTerm Windows build failed.
  echo.
  echo Restart Windows and try the builder one more time if the
  echo Visual Studio Build Tools were installed during this run.
  goto :failed
)
popd

if not exist "%OUTPUT_DIR%" (
  echo.
  echo ERROR: The build finished, but the installer folder was not found:
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
echo Your real OmniTerm installer is:
echo %INSTALLER_FOUND%
echo.
echo File Explorer will open the installer folder now.
start "" explorer.exe "%OUTPUT_DIR%"
echo.
echo Double-click the setup EXE to install and test OmniTerm.
echo.
pause
exit /b 0

:install_if_missing
where %~1 >nul 2>&1
if not errorlevel 1 (
  echo %~3 is already installed.
  exit /b 0
)

echo Installing %~3...
winget install --id %~2 --exact --source winget --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo.
  echo ERROR: Windows could not install %~3 automatically.
  exit /b 1
)
exit /b 0

:install_package_if_missing
winget list --id %~1 --exact >nul 2>&1
if not errorlevel 1 (
  echo %~2 is already installed.
  exit /b 0
)

echo Installing %~2...
if "%~3"=="" (
  winget install --id %~1 --exact --source winget --accept-package-agreements --accept-source-agreements --silent
) else (
  winget install --id %~1 --exact --source winget --accept-package-agreements --accept-source-agreements --silent %~3
)
if errorlevel 1 (
  echo.
  echo ERROR: Windows could not install %~2 automatically.
  exit /b 1
)
exit /b 0

:failed
echo.
echo ============================================================
echo BUILD STOPPED
echo ============================================================
echo Review the message above, then press any key to close this window.
echo.
pause >nul
exit /b 1
