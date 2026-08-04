@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title OmniTerm Windows Installer Builder v4

set "BUILDER_VERSION=4"
set "DESKTOP_DIR=%~dp0apps\desktop"
set "OUTPUT_DIR=%DESKTOP_DIR%\src-tauri\target\release\bundle\nsis"
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSSETUP=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\setup.exe"
set "VS_PATH="
set "VSDEVCMD="
set "LINK_EXE="

echo ============================================================
echo OmniTerm Windows Installer Builder
echo Builder version %BUILDER_VERSION%
echo ============================================================
echo.
echo This developer tool installs missing build requirements and
echo compiles the real OmniTerm Windows setup EXE.
echo.
echo Windows may show an administrator permission prompt.
echo.

if not exist "%DESKTOP_DIR%\package.json" (
  echo ERROR: The OmniTerm desktop project was not found.
  echo.
  echo Do not run this file from inside a ZIP preview window.
  echo Right-click the ZIP, choose Extract All, then run this file
  echo from the extracted omniterm-main folder.
  goto :failed
)

where winget >nul 2>&1
if errorlevel 1 (
  echo ERROR: Windows Package Manager ^(winget^) is missing.
  echo Install or update App Installer from the Microsoft Store.
  goto :failed
)

call :install_command_if_missing node OpenJS.NodeJS.LTS "Node.js LTS"
if errorlevel 1 goto :failed

set "PATH=%ProgramFiles%\nodejs;%USERPROFILE%\.cargo\bin;%PATH%"
call :install_command_if_missing cargo Rustlang.Rustup "Rust"
if errorlevel 1 goto :failed
set "PATH=%ProgramFiles%\nodejs;%USERPROFILE%\.cargo\bin;%PATH%"

call :find_linker
if not defined LINK_EXE (
  echo Microsoft C++ tools are missing.
  echo Installing Desktop development with C++ now...
  echo.
  call :install_cpp_workload
  if errorlevel 1 goto :failed
  call :find_linker
)

if not defined LINK_EXE (
  echo ERROR: The C++ workload installer finished, but link.exe
  echo still could not be found.
  echo.
  echo Open Visual Studio Installer and confirm that
  echo "Desktop development with C++" shows as installed.
  goto :failed
)

for %%D in ("%LINK_EXE%") do set "LINK_DIR=%%~dpD"
set "PATH=%LINK_DIR%;%PATH%"
set "CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=%LINK_EXE%"

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
  echo ERROR: The installer output folder was not found:
  echo %OUTPUT_DIR%
  goto :failed
)

set "INSTALLER_FOUND="
for %%F in ("%OUTPUT_DIR%\*-setup.exe") do if exist "%%~fF" set "INSTALLER_FOUND=%%~fF"

if not defined INSTALLER_FOUND (
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

:install_command_if_missing
where %~1 >nul 2>&1
if not errorlevel 1 (
  echo %~3 is already installed.
  exit /b 0
)
echo Installing %~3...
winget install --id %~2 --exact --source winget --accept-package-agreements --accept-source-agreements --silent
if errorlevel 1 (
  echo ERROR: Windows could not install %~3 automatically.
  exit /b 1
)
exit /b 0

:find_linker
set "LINK_EXE="
set "VS_PATH="
set "VSDEVCMD="
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%I"
)
if defined VS_PATH (
  set "VSDEVCMD=!VS_PATH!\Common7\Tools\VsDevCmd.bat"
  if exist "!VSDEVCMD!" call "!VSDEVCMD!" -arch=x64 -host_arch=x64 >nul 2>&1
)
for /f "delims=" %%L in ('where link.exe 2^>nul') do if not defined LINK_EXE set "LINK_EXE=%%L"
if not defined LINK_EXE (
  for /f "delims=" %%L in ('dir /b /s "%ProgramFiles%\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" 2^>nul') do if not defined LINK_EXE set "LINK_EXE=%%L"
)
if not defined LINK_EXE (
  for /f "delims=" %%L in ('dir /b /s "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\*\VC\Tools\MSVC\*\bin\Hostx64\x64\link.exe" 2^>nul') do if not defined LINK_EXE set "LINK_EXE=%%L"
)
exit /b 0

:install_cpp_workload
set "VS_PATH="
if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do set "VS_PATH=%%I"
)

if defined VS_PATH if exist "%VSSETUP%" (
  echo Updating the existing Visual Studio Build Tools installation...
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath '%VSSETUP%' -Verb RunAs -Wait -PassThru -ArgumentList @('modify','--installPath','%VS_PATH%','--add','Microsoft.VisualStudio.Workload.VCTools','--includeRecommended','--passive','--norestart'); if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { exit $p.ExitCode }"
  if errorlevel 1 (
    echo ERROR: Visual Studio Installer could not add the C++ workload.
    exit /b 1
  )
) else (
  echo Installing Visual Studio Build Tools with C++ support...
  winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --accept-package-agreements --accept-source-agreements --override "--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
  if errorlevel 1 (
    echo ERROR: Windows could not install Visual Studio C++ Build Tools.
    exit /b 1
  )
)

echo C++ workload installation finished.
exit /b 0

:failed
echo.
echo ============================================================
echo BUILD STOPPED
echo ============================================================
echo.
echo Confirm that this window shows Builder version 4.
echo.
pause >nul
exit /b 1
