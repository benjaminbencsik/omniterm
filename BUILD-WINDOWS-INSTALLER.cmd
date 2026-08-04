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
set "NEEDS_REOPEN=0"

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
  echo reopen this folder, and run this builder again.
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

set "PATH=%ProgramFiles%\nodejs;%USERPROFILE%\.cargo\bin;%PATH%"

where node >nul 2>&1
if errorlevel 1 set "NEEDS_REOPEN=1"
where npm >nul 2>&1
if errorlevel 1 set "NEEDS_REOPEN=1"
where cargo >nul 2>&1
if errorlevel 1 set "NEEDS_REOPEN=1"

if "%NEEDS_REOPEN%"=="1" (
  echo.
  echo One or more tools were installed but are not visible in this window yet.
  echo Close this builder and double-click it again. A PC restart is not required.
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
  echo ERROR: Microsoft C++ linker link.exe is unavailable.
  echo.
  echo Open Visual Studio Installer, choose Modify for Build Tools 2022,
  echo check "Desktop development with C++", then run this builder again.
  echo A Windows restart is not required.
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

:find_vs_environment
set "VS_PATH="
set "VSDEVCMD="

if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_PATH=%%I"
)

if not defined VS_PATH if exist "%VSWHERE%" (
  for /f "usebackq tokens=*" %%I in (`"%VSWHERE%" -latest -products * -property installationPath`) do (
    if exist "%%I\Common7\Tools\VsDevCmd.bat" set "VS_PATH=%%I"
  )
)

if defined VS_PATH set "VSDEVCMD=%VS_PATH%\Common7\Tools\VsDevCmd.bat"
exit /b 0

:ensure_cpp_build_tools
call :find_vs_environment

if defined VSDEVCMD if exist "!VSDEVCMD!" (
  call "!VSDEVCMD!" -arch=x64 -host_arch=x64 >nul 2>&1
  where link.exe >nul 2>&1
  if not errorlevel 1 (
    echo Visual Studio C++ Build Tools are already installed.
    exit /b 0
  )
)

echo Installing or repairing Visual Studio C++ Build Tools...
set "INSTALL_EXIT=0"

if defined VS_PATH if exist "%VSINSTALLER%" (
  "%VSINSTALLER%" modify --installPath "%VS_PATH%" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart
  set "INSTALL_EXIT=!errorlevel!"
) else (
  winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --source winget --accept-package-agreements --accept-source-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --norestart"
  set "INSTALL_EXIT=!errorlevel!"
)

rem Exit code 3010 means installation succeeded and Windows suggests a restart.
rem We do not require one; we verify the compiler directly below.
if not "!INSTALL_EXIT!"=="0" if not "!INSTALL_EXIT!"=="3010" (
  echo Visual Studio installer returned code !INSTALL_EXIT!.
  echo Checking whether the C++ tools were installed anyway...
)

call :find_vs_environment
if defined VSDEVCMD if exist "!VSDEVCMD!" (
  call "!VSDEVCMD!" -arch=x64 -host_arch=x64 >nul 2>&1
  where link.exe >nul 2>&1
  if not errorlevel 1 (
    echo Visual Studio C++ Build Tools are ready.
    exit /b 0
  )
)

echo.
echo ERROR: The C++ workload is still missing.
echo.
echo No restart is needed. Open Visual Studio Installer now, choose
 echo Modify for Build Tools 2022, check "Desktop development with C++",
echo and let it finish. Then run this builder again.
start "" "%VSINSTALLER%"
exit /b 1

:failed
echo.
echo ============================================================
echo BUILD STOPPED
echo ============================================================
echo Review the message above, then press any key to close this window.
echo.
pause >nul
exit /b 1
