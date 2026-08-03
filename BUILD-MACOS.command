#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
chmod +x "scripts/build-macos.sh"
"scripts/build-macos.sh"
echo
echo "Build finished. Press Return to close."
read -r
