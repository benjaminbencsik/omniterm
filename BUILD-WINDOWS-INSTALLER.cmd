@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title OmniTerm Windows Installer Builder v3

set "BUILDER_VERSION=3"
set "DESKTOP_DIR=%~dp0apps\desktop"
set "OUTPUT_DIR=%DESKTOP_DIR%\src-tauri\target\release\bundle\nsis"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VS_PATH="
set "VSDEVCMD="
set "LINK_EXE="

echo ============================================================
echo OmniTerm Windows Installer Builder
echo Builder version %BUILDER_VERSION%
echo ============================================================
echo.
echo This developer tool compiles the real OmniTerm setup EXE.
echo It is not the OmniTerm application itself.
echo.

if not exist "%DESKTOP_DIR%\package.json" (
  echo ERROR: The OmniTerm desktop project was not found.
  echo.
  echo Do not run this file from inside a ZIP preview window.
  echo Right-click the ZIP, choose Extract All, then run this file
  echo from the extracted omniterm-main folder.
  echo.
  echo Expected project folder:
  echo %DESKTOP_DIR%
  goto :failed
)

where node >nul 2>&1
if errorlevel 1 (
  echo ERROR: Node.js is missing.
  echo Install Node.js LTS, then run this builder again.
  goto :failed
)

where npm >nul 2>&1
if errorlevel 1 (
  echo ERROR: npm is missing.
  echo Reinstall Node.js LTS, then run this builder again.
  goto :failed
)

set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
where cargo >nul 2>&1
if errorlevel 1 (
  echo ERROR: Rust is missing.
  echo Install Rust with rustup, then run this builder again.
  goto :failed
)

rem Find Visual Studio using vswhere when available.
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%I"
)

if defined VS_PATH (
  set "VSDEVCMD=%VS_PATH%\Common7\Tools\VsDevCmd.bat"
  if exist "!VSDEVCMD!" (
    echo Loading Microsoft C++ build environment...
    call "!VSDEVCMD!" -arch=x64 -host_arch=x64 >nul 2>&1
  )
)

rem First try the linker exposed by the Visual Studio environment.
for /f "delims=" %%L in ('where link.exe 2^>nul') do if not defined LINK_EXE set "LINK_EXE=%%L"

rem If PATH was not populated, search common Visual Studio locations directly.
if not defined LINK_EXE (
  for /f "delims=" %%L in ('dir /b /s "%ProgramFiles%\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" 2^>nul') do set "LINK_EXE=%%L"
)
if not defined LINK_EXE (
  for /f "delims=" %%L in ('dir /b /s "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" 2^>nul') do set "LINK_EXE=%%L"
)

if not defined LINK_EXE (
  echo ERROR: Microsoft C++ linker link.exe was not found.
  echo.
  echo Open Visual Studio Installer, choose Modify for Build Tools,
  echo and install "Desktop development with C++".
  echo No computer restart is required after installation finishes.
  goto :failed
)

for %%D in ("%LINK_EXE%") do set "LINK_DIR=%%~dpD"
set "PATH=%LINK_DIR%;%PATH%"
set "CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=%LINK_EXE%"

if not exist "%LINK_EXE%" (
  echo ERROR: The detected linker path does not exist:
  echo %LINK_EXE%
  goto :failed
)

echo Node.js:
node --version
echo npm:
call npm --version
echo Rust:
cargo --version
echo Microsoft linker:
echo %LINK_EXE%
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
start "" explorer.exe "%OUTPUT_DIR%"
echo Double-click the setup EXE to install and test OmniTerm.
echo.
pause
exit /b 0

:failed
echo.
echo ============================================================
echo BUILD STOPPED
echo ============================================================
echo.
echo IMPORTANT: The current builder must show:
echo   Builder version 3
echo.
echo If that line is missing, you are running an older downloaded copy.
echo.
pause >nul
exit /b 1
