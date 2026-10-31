# Facet Escape 3D — 0.2.0

A native Godot 4.7.2/GDScript Android puzzle game, developed on Fedora. Open `project.godot` and press F5, or:

```bash
./tools/run_desktop.sh
./tools/run_desktop.sh --rendering-method gl_compatibility
./tools/run_tests.sh
./tools/run_tests.sh --stress
./tools/build_android.sh debug
```

Set `GODOT_BIN` when the engine is outside PATH. Drag with one finger (or mouse) to rotate. Pinch with two fingers (or use the wheel) to zoom, up to 3×. There is no panning.

**New face-edge rules:** tap a flat arrow whose head has a clear straight lane to the edge of its current face. The head escapes straight off that face and its tail follows through its existing bends. Bodies can wrap around cube corners; exits never wrap. There are no predefined escape tracks or launch rings. Gold keys unlock matching pearl locks.

The regenerated 100-level campaign grows from guided 5×5 boards to six dense 25×25 faces, with arrows up to 15 cells long. Includes deterministic UTC daily puzzles, solver hints, undo/restart, original flat geometry and soundscape, offline play and local saving. Advertising remains disabled by default.

On the first upgrade from schema 1, the complete old save is archived as `user://progress.json.v1.archive.json` (a numbered name is used if that archive already exists). The new campaign starts at level 1; hints and settings carry over. Old completion times and daily records remain in the archive.

See [implementation status](IMPLEMENTATION_STATUS.md), [architecture](ARCHITECTURE.md), [game design](GAME_DESIGN.md), [testing](docs/TESTING_GUIDE.md), [Fedora setup](docs/FEDORA_SETUP.md), [AdMob setup](docs/ADMOB_SETUP.md), and [release checklist](docs/PLAY_STORE_RELEASE.md). This is not a claim of Google Play release readiness. No signing secrets belong in source control.
