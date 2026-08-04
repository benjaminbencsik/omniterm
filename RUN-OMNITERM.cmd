@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title OmniTerm Launcher

set "LOG=%~dp0OMNITERM-ERROR.txt"
>"%LOG%" echo OmniTerm launcher log
>>"%LOG%" echo Started: %date% %time%
>>"%LOG%" echo Folder: %CD%
>>"%LOG%" echo.

echo ============================================================
echo OmniTerm Launcher
echo ============================================================
echo.

if not exist "apps\desktop-dotnet\OmniTerm.csproj" (
  call :fail "The OmniTerm project was not found. Extract the entire ZIP before running this file."
)

where dotnet >>"%LOG%" 2>&1
if errorlevel 1 (
  echo .NET 8 SDK was not found. Installing it now...
  >>"%LOG%" echo .NET SDK not found on PATH.

  where winget >>"%LOG%" 2>&1
  if errorlevel 1 (
    call :fail "Windows Package Manager (winget) is unavailable. Install Microsoft App Installer from the Microsoft Store, then run this file again."
  )

  winget install --id Microsoft.DotNet.SDK.8 --exact --source winget --accept-package-agreements --accept-source-agreements >>"%LOG%" 2>&1
  if errorlevel 1 call :fail "The .NET 8 SDK installation failed."

  set "PATH=%ProgramFiles%\dotnet;%PATH%"
)

echo Checking .NET...
dotnet --info >>"%LOG%" 2>&1
if errorlevel 1 call :fail "dotnet is installed but could not start. Restart Windows and run this file again."

echo Restoring OmniTerm...
dotnet restore "apps\desktop-dotnet\OmniTerm.csproj" >>"%LOG%" 2>&1
if errorlevel 1 call :fail "Project restore failed."

echo Building OmniTerm...
dotnet build "apps\desktop-dotnet\OmniTerm.csproj" --configuration Release --no-restore >>"%LOG%" 2>&1
if errorlevel 1 call :fail "Project build failed."

echo Starting OmniTerm...
dotnet run --project "apps\desktop-dotnet\OmniTerm.csproj" --configuration Release --no-build >>"%LOG%" 2>&1
if errorlevel 1 call :fail "OmniTerm built but failed while starting."

del "%LOG%" >nul 2>&1
exit /b 0

:fail
echo.
echo ============================================================
echo OMNITERM DID NOT START
echo ============================================================
echo %~1
echo.
echo The complete error was saved here:
echo %LOG%
echo.
>>"%LOG%" echo.
>>"%LOG%" echo FINAL ERROR: %~1
start "" notepad.exe "%LOG%"
pause
exit /b 1
