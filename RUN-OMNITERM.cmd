@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title OmniTerm .NET Launcher

echo ============================================================
echo OmniTerm .NET Launcher
echo ============================================================
echo.

if not exist "apps\desktop-dotnet\OmniTerm.csproj" (
  echo ERROR: The OmniTerm .NET project was not found.
  echo Extract the full repository ZIP before running this file.
  echo.
  pause
  exit /b 1
)

where dotnet >nul 2>&1
if errorlevel 1 (
  echo .NET 8 SDK is not installed.
  echo Installing it now with Windows Package Manager...
  echo.

  where winget >nul 2>&1
  if errorlevel 1 (
    echo ERROR: winget is not available.
    echo Install or update App Installer from the Microsoft Store,
    echo then run this file again.
    echo.
    pause
    exit /b 1
  )

  winget install --id Microsoft.DotNet.SDK.8 --exact --source winget --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo.
    echo ERROR: The .NET 8 SDK installation failed.
    pause
    exit /b 1
  )

  set "PATH=%ProgramFiles%\dotnet;%PATH%"
)

echo Checking .NET...
dotnet --version
if errorlevel 1 (
  echo.
  echo ERROR: dotnet is still not available.
  echo Close this window and run RUN-OMNITERM.cmd again.
  pause
  exit /b 1
)

echo.
echo Restoring OmniTerm...
dotnet restore "apps\desktop-dotnet\OmniTerm.csproj"
if errorlevel 1 goto :failed

echo.
echo Building OmniTerm...
dotnet build "apps\desktop-dotnet\OmniTerm.csproj" --configuration Release --no-restore
if errorlevel 1 goto :failed

echo.
echo Starting OmniTerm...
dotnet run --project "apps\desktop-dotnet\OmniTerm.csproj" --configuration Release --no-build
exit /b %errorlevel%

:failed
echo.
echo ============================================================
echo OMNITERM COULD NOT BUILD
echo ============================================================
echo.
echo Copy the error lines above and send them back for repair.
echo.
pause
exit /b 1
