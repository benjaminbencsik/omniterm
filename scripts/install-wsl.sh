#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/benjaminbencsik/omniterm.git"
INSTALL_DIR="${OMNITERM_HOME:-$HOME/omniterm}"

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install system packages." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip curl

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  rm -rf "$INSTALL_DIR"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

python3 -m venv "$INSTALL_DIR/.venv"
"$INSTALL_DIR/.venv/bin/python" -m pip install --upgrade pip
"$INSTALL_DIR/.venv/bin/pip" install -e "$INSTALL_DIR[dev]"

mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/omniterm" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/.venv/bin/omniterm" "\$@"
EOF
chmod +x "$HOME/.local/bin/omniterm"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo
echo "OmniTerm installed in: $INSTALL_DIR"
echo "Restart WSL or run: source ~/.bashrc"
echo "Then test with: omniterm --help"
