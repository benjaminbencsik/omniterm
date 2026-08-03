#!/usr/bin/env bash
set -euo pipefail

command -v node >/dev/null 2>&1 || { echo "Missing Node.js. Install it with: brew install node"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "Missing npm. It is installed with Node.js."; exit 1; }
command -v cargo >/dev/null 2>&1 || { echo "Missing Rust. Install it from https://rustup.rs"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESKTOP_DIR="$REPO_ROOT/apps/desktop"
APP_PATH="$DESKTOP_DIR/src-tauri/target/release/bundle/macos/OmniTerm.app"

if [[ ! -d "$DESKTOP_DIR" ]]; then
  echo "Desktop source folder not found: $DESKTOP_DIR"
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "First launch: building OmniTerm locally..."
  cd "$DESKTOP_DIR"
  npm install
  npm run tauri build
fi

if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="$(find "$DESKTOP_DIR/src-tauri/target/release/bundle/macos" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)"
fi

if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "The OmniTerm app bundle was not found after the build."
  exit 1
fi

echo "Launching OmniTerm..."
open "$APP_PATH"
