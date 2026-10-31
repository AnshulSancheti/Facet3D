# Verification

Use Godot **4.7.2 standard**. `GODOT_BIN` may override detection.

- `tools/run_tests.sh`: topology/rules/solver/generator checks, 100 serialized campaign solutions, ad facade, persistence, and actual scene integration.
- `tools/run_tests.sh --stress`: additionally regenerate and solve 1,000 fixed seeds, 200 per tier. Actual report: `tests/generation/edge_v21_stress_results.json`. Do not compare timing across machines as a benchmark.
- `godot --headless --path . --script tests/integration/game_smoke.gd`: creates the main scene, starts level five, solves it using animated actual controller moves, exercises hints/undo/restart and menus. Uses a separate test save.
- `godot --path . --rendering-method gl_compatibility --script tests/integration/visual_capture.gd`: real desktop-rendered captures in `/tmp/facet-menu.png` and `/tmp/facet-game.png`.

Manual desktop: tap versus drag threshold, behind-board picking, all six faces, wheel bounds, menu navigation, no double removal, pause/restart during animation, continue after restarting app, sound/music settings, missing/failed advertisements and corrupted-save backup recovery.

- Actual desktop Mobile Vulkan launch/render capture also passed; this used the laptop NVIDIA GPU and does not measure Android performance.
- `tests/integration/responsive_capture.gd` checks menu/HUD button bounds at360×800,540×960,720×1280 using real rendered windows.

Basic testing on the connected CPH2487 is recorded in IMPLEMENTATION_STATUS.md. Before release, still test broader hardware multitouch, display cutouts/navigation insets, process death, subjective audio/haptics, real AdMob test-only callbacks, sustained memory/heat and 16KB hardware/emulator compatibility. Desktop tests establish no phone performance claim.

## Ceramic presentation regression checks

`tests/integration/ceramic_presentation.gd` checks the continuous mesh envelope,
rotated camera framing at three portrait ratios, minimum touch targets, menu bounds,
and independent audio preferences/background/resume. It is included in run_tests.sh.

Run visual_capture.gd with the Mobile renderer and again with
`--rendering-method gl_compatibility`; inspect the /tmp/facet-*.png captures.

On the Android phone, inspect the home and gameplay surface across several rotations.
The Adreno 730 exhibited solid-black surface patches with the initial rendering
configuration despite clean logs. Do not accept only a successful launch/log check.
For this specific regression, run `python tools/check_render_capture.py CAPTURE.png`
on actual gameplay screenshots. It checks for near-black pixel clusters in the central
region; it complements rather than replaces visual review. Black navigation bars are
excluded. Pillow is a development-only dependency.


## Dense face-edge rules (0.2.0)

See tests/README.md for the new model and generator checks. There must be no stored
or drawn escape guides. Manually inspect a 25×25 board, long/bent/wrapped pieces,
and head exits on all four face boundaries. Verify that an occupied middle cell
blocks a head lane, while an arrow on the next face does not block escape.

The play area is a separate clipped 3D viewport. At 3× zoom, confirm one-finger
rotation, two-finger pinch without unintended selection, and unobscured HUD controls.
Record screenshots in overview and close-up. Save migration must archive the old
schema-1 bytes and reset the new campaign to 1 while retaining hints/settings.

Debug builds collect bounded local 8-second frame windows after a 2-second warmup,
recording screen, board size/count, median/p95 frame interval, FPS, Godot static heap,
draw calls and the renderer's memory counter to user://performance_report.json.
This probe is absent in release builds. It does not replace Android PSS measurement,
a sustained thermal test or a GPU profiler. Frame pacing must be measured while a
dense puzzle is visible, not inferred from an idle menu or wrapper ViewRoot stats.
