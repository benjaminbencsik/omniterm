@echo off
setlocal
cd /d "%~dp0"
title OmniTerm Launcher

if not exist "OmniTerm.ps1" (
  echo ERROR: OmniTerm.ps1 was not found.
  echo Download and extract the complete repository ZIP.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0OmniTerm.ps1"
if errorlevel 1 (
  echo.
  echo OmniTerm could not start.
  echo Error code: %errorlevel%
  pause
)
