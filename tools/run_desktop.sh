#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/home/intelligentape/Downloads/Godot_v4.7.2-stable_linux (4).x86_64}"
exec "$GODOT_BIN" --path . "$@"
