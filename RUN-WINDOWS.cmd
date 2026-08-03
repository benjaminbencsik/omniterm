@echo off
setlocal
cd /d "%~dp0"

if /I not "%~1"=="--persistent" (
  start "OmniTerm Setup and Launcher" cmd.exe /k ""%~f0" --persistent"
  exit /b 0
)

cls
echo ============================================================
echo OmniTerm Windows setup and launcher
echo ============================================================
echo.
echo This window will stay open so you can read any errors.
echo A detailed log will also be saved as omniterm-launch.log.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-windows.ps1"
set "OMNITERM_EXIT=%ERRORLEVEL%"

echo.
if not "%OMNITERM_EXIT%"=="0" (
  echo ============================================================
  echo OmniTerm could not be started. Error code: %OMNITERM_EXIT%
  echo Open omniterm-launch.log in this folder for full details.
  echo ============================================================
) else (
  echo ============================================================
  echo OmniTerm launcher finished successfully.
  echo You may close this window after the app opens.
  echo ============================================================
)
echo.
echo Press any key to close this window.
pause >nul
exit /b %OMNITERM_EXIT%
