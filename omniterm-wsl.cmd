@echo off
setlocal

where wsl.exe >nul 2>nul
if errorlevel 1 (
  echo WSL is not installed or wsl.exe is not available.
  echo Install WSL from an Administrator PowerShell with: wsl --install
  exit /b 1
)

wsl.exe bash -lc "if command -v omniterm >/dev/null 2>&1; then omniterm \"$@\"; elif [ -x \"$HOME/omniterm/.venv/bin/omniterm\" ]; then \"$HOME/omniterm/.venv/bin/omniterm\" \"$@\"; else echo 'OmniTerm is not installed in WSL. Run the WSL installation command from README.md.' >&2; exit 1; fi" -- %*

endlocal
