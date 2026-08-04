@echo off
setlocal
cd /d "%~dp0"
title OmniTerm Launcher

if not exist "OmniTerm.ps1" (
  echo ERROR: OmniTerm.ps1 was not found.
  echo Download and extract the complete repository ZIP.
  echo.
  pause
  exit /b 1
)

del /q "OMNITERM-ERROR.txt" >nul 2>&1

echo Starting OmniTerm...
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0OmniTerm.ps1"
set "RESULT=%ERRORLEVEL%"

if not "%RESULT%"=="0" (
  echo.
  echo OmniTerm could not start.
  echo Error code: %RESULT%
  echo.
  if exist "OMNITERM-ERROR.txt" (
    echo Opening OMNITERM-ERROR.txt...
    start "" notepad.exe "%~dp0OMNITERM-ERROR.txt"
  ) else (
    echo No error log was created.
  )
  echo.
  pause
  exit /b %RESULT%
)

exit /b 0
