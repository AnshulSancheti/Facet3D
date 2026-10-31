#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${GODOT_BIN:-}" ]]; then
  godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null; then
  godot_bin="$(command -v godot)"
elif [[ -x '/home/intelligentape/Downloads/Godot_v4.7.2-stable_linux (4).x86_64' ]]; then
  godot_bin='/home/intelligentape/Downloads/Godot_v4.7.2-stable_linux (4).x86_64'
else
  echo 'Godot 4.7.2 required. Set GODOT_BIN.' >&2; exit 1
fi
"$godot_bin" --version | grep -q '^4\.7\.2\.stable' || { echo 'Godot version mismatch' >&2; exit 1; }
"$godot_bin" --headless --path . --script tests/runners/run_all.gd -- "$@"
"$godot_bin" --headless --path . --script tools/validate_levels.gd
"$godot_bin" --headless --path . --script tests/unit/test_ads.gd
"$godot_bin" --headless --path . --script tests/unit/test_save.gd
"$godot_bin" --headless --path . --script tests/integration/game_smoke.gd

"$godot_bin" --headless --path . --script tests/integration/calm_redesign.gd

"$godot_bin" --headless --path . --script tests/integration/ceramic_presentation.gd

"$godot_bin" --headless --path . --script tests/integration/flat_routes.gd

"$godot_bin" --headless --path . --script tests/integration/edge_gameplay.gd
