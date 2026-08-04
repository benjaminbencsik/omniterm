@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title OmniTerm Windows Installer Builder

set "DESKTOP_DIR=%~dp0apps\desktop"
set "OUTPUT_DIR=%DESKTOP_DIR%\src-tauri\target\release\bundle\nsis"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSINSTALLER=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\setup.exe"
set "VS_PATH="
set "VSDEVCMD="
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

call :ensure_cpp_build_tools
if errorlevel 1 goto :failed

call :install_package_if_missing "Microsoft.EdgeWebView2Runtime" "Microsoft Edge WebView2 Runtime"
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

if not defined VSDEVCMD (
  echo ERROR: The Visual Studio C++ build environment could not be located.
  goto :failed
)

echo Loading Microsoft C++ build environment...
call "%VSDEVCMD%" -arch=x64 -host_arch=x64 >nul
if errorlevel 1 (
  echo ERROR: Visual Studio could not initialize its C++ build environment.
  goto :failed
)

where link.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: Microsoft C++ linker link.exe is still unavailable.
  echo Restart Windows, then run this builder again.
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
echo Microsoft linker:
where link.exe
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
winget install --id %~1 --exact --source winget --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo.
  echo ERROR: Windows could not install %~2 automatically.
  exit /b 1
)
exit /b 0

:ensure_cpp_build_tools
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%I"
)

if defined VS_PATH (
  set "VSDEVCMD=%VS_PATH%\Common7\Tools\VsDevCmd.bat"
  if exist "!VSDEVCMD!" (
    echo Visual Studio C++ Build Tools are already installed.
    exit /b 0
  )
)

echo Installing or repairing Visual Studio C++ Build Tools...

if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VS_PATH=%%I"
)

if defined VS_PATH if exist "%VSINSTALLER%" (
  "%VSINSTALLER%" modify --installPath "%VS_PATH%" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart
) else (
  winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --accept-package-agreements --accept-source-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --norestart"
)

if errorlevel 1 (
  echo.
  echo ERROR: Windows could not install the Visual C++ build tools.
  exit /b 1
)

set "VS_PATH="
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%I"
)

if not defined VS_PATH (
  echo.
  echo ERROR: The C++ workload installation did not complete.
  echo Restart Windows and run this builder again.
  exit /b 1
)

set "VSDEVCMD=%VS_PATH%\Common7\Tools\VsDevCmd.bat"
if not exist "!VSDEVCMD!" (
  echo ERROR: VsDevCmd.bat was not found after installation.
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
