#!/usr/bin/env bash
set -euo pipefail

printf '\nOmniTerm local macOS build\n\n'

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1"
    echo "$2"
    exit 1
  fi
}

require_command node "Install Node.js LTS from https://nodejs.org or with Homebrew: brew install node"
require_command npm "npm is installed with Node.js"
require_command cargo "Install Rust from https://rustup.rs"
require_command xcode-select "Install Xcode Command Line Tools with: xcode-select --install"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
desktop_dir="$repo_root/apps/desktop"

cd "$desktop_dir"

echo "Installing frontend dependencies..."
npm install

echo "Building OmniTerm desktop application..."
npm run tauri build

bundle_dir="$desktop_dir/src-tauri/target/release/bundle"

echo
echo "Build complete. Packages are located in:"
echo "$bundle_dir"

if compgen -G "$bundle_dir/dmg/*.dmg" >/dev/null; then
  echo
echo "macOS DMG:"
  ls -1 "$bundle_dir"/dmg/*.dmg
fi

if compgen -G "$bundle_dir/macos/*.app" >/dev/null; then
  echo
echo "macOS app bundle:"
  ls -1d "$bundle_dir"/macos/*.app
fi
