# Verification

Use Godot 4.7.2 standard and `./tools/run_tests.sh`. `GODOT_BIN` overrides engine detection. `--stress` additionally generates, solves and independently replays 1,000 fixed seeds (200 per tier). Actual report: `tests/generation/edge_v21_stress_results.json`.

The rule suite covers chart seams for grids through 25×25, visible quarter-turn heads and seam transport, straight face-only exit lanes, blocked middle cells, wrapped blockers, neighboring-face non-blockers, keys, self-intersection/overlap rejection, edge heads, cycles, immutable invalid moves, JSON decoding, graph/DFS agreement and budget exhaustion. Daily generation and its forced-failure fallback are deterministic and replayable.

`tools/validate_levels.gd` reads all 100 packaged JSON levels, independently solves them with DFS, and occupancy-replays the stored solution, the DFS solution and the constructive reverse order. `tools/generate_levels.gd` regenerates the campaign using the current generator version.

`generate_config` supports seed, difficulty (0–4), level_number (0 disables tutorials), board_size (3–25), max_length (2–15), min_density/max_density and max_attempts (1–32). Ordinary play uses calibrated campaign tiers. Candidates are bounded to max(40,000, 240 × grid width squared) per layout plus 15 finite tail-extension sweeps. Unsupported settings or unmet coverage/shape/proof requirements return an error; failed layouts are never silently accepted. The runtime daily uses eight attempts and a marked deterministic packaged fallback.

Save tests verify exact-byte migration archives, level-1 reset, retained hints/settings, non-overwriting archives, daily ruleset namespacing, backup recovery and type sanitation. Ads facade checks remain separate from actual SDK/hardware validation.

Scene tests exercise controller completion/animation, hints, undo, restart during animation, menu navigation, four drag directions and portrait bounds. `edge_gameplay.gd` additionally checks all 1,350 visible cell picks, one collider per dense board, one mesh per arrow, incremental removal/undo, pinch tap/rotation suppression and asynchronous daily cancellation/isolation. Flat-ink geometry tests and ceramic/audio/background lifecycle checks remain included.

Real renderer captures use `visual_capture.gd` or `responsive_capture.gd`; these require a display and must be inspected. Desktop/headless results do not establish Android frame pacing, thermal behavior, hardware multitouch, subjective audio or native-ad correctness.
