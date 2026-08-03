@echo off
setlocal
cd /d "%~dp0"

echo OmniTerm Windows launcher
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-windows.ps1"

if errorlevel 1 (
  echo.
  echo OmniTerm could not be started. Review the message above.
  pause
  exit /b 1
)

exit /b 0
