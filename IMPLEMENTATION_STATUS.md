# Implementation status — Facet Escape 3D 0.2.2

Updated 2026-10-22. Active ruleset: `face_edge_snake_v2`; generator: `facet-edge-2.1.0`. This status supersedes the previous track-based game. The source and debug APK implement the overhaul; Google Play release approval remains pending.

## Implemented

| Subsystem | Current behavior |
|---|---|
| Movement | No stored/drawn escape tracks or launch rings. Heads require a clear straight lane to their current face edge and leave tangentially. Tails follow their bent/wrapped bodies. Neighbor-face arrows do not block departure; wrapped body cells block any head lane they occupy. |
| Geometry and validation | Ordered tail-to-head cells, explicit visible head direction, including rounded terminal quarter turns, no overlaps/branches/repeated cells/self-crossing exit lanes. Arrows up to 15 cells; occasional bodies cross up to two seams. All visible pieces remain flat ink. Continuous miter joins replace disconnected bend segments. Version0.2.2 uses sharp cube faces and fine contrasting rims; arrow bodies are about 30% thinner, head spans about 21% narrower. |
| Solver | Indexed static blocker/key dependencies; Kahn solve/cycle/depth analysis; retained memoized budgeted DFS. Independent occupancy replay validates every accepted solution. Invalid definitions, budgets and unsolvability are distinct. |
| Generation | Deterministic reverse packing, proof-preserving tail growth and legal-schedule orientation weaving. Physical blockers determine every dependency. Bounds on layouts/candidates/extensions. Explicit errors for failure. Non-tutorial opening-move caps 15/10/7/5/4%; minimum dependency depths 12/25/40/60/80 by tier. No short-piece filler workaround. Per-level density, length histograms, bending/wrapping and dependency metrics recorded. |
| Campaign | 100 regenerated boards. 5×5 onboarding, then 9/13/17/21/25 grids. Expert levels contain 339–379 arrows at 80.4–82.6% coverage. At least 60% of non-tutorial arrows bend; 5–20% wrap on large grids. At least 25% of mature arrows are 10–15 cells long. Opening choices and dependency depth are acceptance criteria. |
| Daily | UTC/version deterministic, dense 25×25 generation on a worker, fixed operation budgets, stale-result cancellation/cache, marked validated deterministic fallback. No timing-dependent puzzle output. Daily records are namespaced and never change campaign current/unlocks. |
| Rendering | Cached sharp ceramic cube with flat face normals and vertex-colored face/rim contrast, one combined mesh per arrow, clipped transparent central 3D viewport, no segment colliders, incremental remove/undo/lock recoloring. Phone-safe matte standard material; specular/MSAA disabled. Latest build renders the central viewport at physical pixel resolution. |
| Input | One-finger rotation, two-finger pinch 1–3×, mouse drag/wheel; no panning. Pinches suppress taps and residual rotation. Cube raycast plus face/grid ownership selects pieces, including wrapped portions. HUD remains outside zoomed rendering. |
| Progress | Schema2 archives exact old schema1 bytes before replacement. New campaign begins at 1; hints/preferences retained. Old results/times/daily/statistics remain archived. Archives never overwritten; temporary-file/backup recovery and field sanitation retained. |
| Presentation | Ceramic/navy atmosphere, original flat icons, Noto fonts/OFL notices, original sparse ambient score and soft effects, reduced motion, independent audio/background behavior. UI tutorials/preview/docs updated to new rules. |
| Ads and privacy | Existing disabled-by-default AdMob abstraction/native plugin/UMP/reward policy unchanged. Offline play remains independent. Local events bounded; optional debug performance sampling bounded to 12 windows and absent in release. |
| Android package | 0.2.2/version-code4 debug APK built and signed with existing debug key. Target36/ARM64. Static signature, manifest/badging, ELF16KiB and zip alignment audit pass. |

## Verification executed

- **196,431 logic checks, zero failures**, including topology through size25, new collisions, edges, locks, cycle detection, graph/DFS agreement, determinism, forced daily fallback and JSON validation.
- **100 packaged campaign boards** independently solved with DFS; recorded, DFS and reverse-construction orders occupancy-replayed.
- **1,000 stress seeds, 200/tier:** 1,000 accepted, 1,683 layout attempts (683 rejected/retried layouts included); zero generation failures, invalid accepted layouts or solver/replay failures. Average generation **406.451 ms**, maximum **5343.733 ms**, worst solver states **395** on this desktop run. All tier-specific opening/depth constraints enforced. Report: `tests/generation/edge_v21_stress_results.json`. Historical v2.0 metrics remain separately labeled.
- Save tests: exact legacy archive, first-level reset, retained preferences/hints, non-overwriting archives, no repeat reset, versioned daily records, corruption recovery/sanitation.
- Scene tests: actual level5 solve/animation, hint charge, undo/restart/interrupted animation, four drag directions, physical/grid picking, menu/audio lifecycle and responsive layouts.
- Dense integration: **3,750 face/grid picks**, one collider and one mesh per arrow, no whole-board rebuild on removal/undo, pinch suppression, async daily cancellation and campaign isolation.
- Flat ink checks: face-plane thickness, surface-conforming seams, shared miter vertices, no volumetric static or moving arrow meshes.
- Portrait overview and close zoom tested at 360×800, 540×960 and 720×1280. Dedicated native-resolution capture verifies physical pixel width and 2.25× zoom clipped before the HUD. Mobile Vulkan and Compatibility desktop captures inspected; the final native TextureRect presentation also has its own capture test.
- Latest complete build/test log: `/tmp/facet-v21-build.log`. Native render log: `/tmp/facet-v21-native-capture.log`; final Compatibility capture: `/tmp/facet-v21-compatibility.log`.

## Current 0.2.2 visual update

Changed `scripts/presentation/ceramic_sculpture.gd`, `scripts/presentation/flat_ink.gd`, `scripts/gameplay/puzzle_view.gd`, the sharp-normal check in `tests/integration/ceramic_presentation.gd`, project/export versions and docs. All existing automated suites passed (196,431 logic checks; 3,750 grid picks), as did native overview/zoom capture and black-render checks. Build/test log `/tmp/facet-v22-build.log`; captures `release/screenshots/sharp-v22/`. No puzzle content, rules or generation changes. Installed v0.2.2/version-code4 on the connected CPH2487 after explicit approval to restart the current Daily. Campaign progress/settings/hints retained. APK SHA256: `093afd358c43c5439481be8b5c77328343c031d3796e0908ee2e2a2fa49bfe15`. Phone home and 355-arrow Daily visually inspected; no black surfaces or HUD collision. Short eight-second sample measured about 60 FPS at 1240×2124, not a sustained thermal benchmark. Current device state is recorded in `release/verification/edge-v2-device-status.json`; prior version evidence is separately labeled.

## Previous 0.2.1 Android device verification

Installed and launched the final **0.2.1/version-code3** native-resolution debug APK on CPH2487 (Android16/API36, Adreno730). Inspected home, 25×25 Daily and a drag-rotated view; no black-surface regression or HUD collision. Current campaign level/unlocks remain intact, and the original schema1 archive still matches byte for byte. The first five levels remain onboarding; the harder generated campaign begins at level6. Daily offers a 25×25 board immediately.

On a **355-arrow 25×25 Daily** with all 355 arrows present and a **1240×2124** central viewport, short eight-second debug windows measured about **59.6–60 FPS**, median/p95 frame intervals **16.67 ms**, Godot static heap **149 MB decimal**, renderer memory **137 MB decimal**. Android PSS snapshot **412,920 KB**. These samples cover idle and a drag, not sustained thermal behavior or lower-end phones. Current process log contained no script errors or fatal exceptions.

APK SHA256: `1366e20cff8ae98aed1fb4a368fc3f2a192e4542b12f8cf639cdbd547f48706f`.
Machine-readable device status: `release/verification/edge-v2-device-status.json`.
Screenshots: `release/screenshots/difficulty-v21/`.
Performance and PSS evidence: `release/verification/difficulty-v21-device-*`.
Earlier logical-resolution evidence remains separately labeled and is historical.

## Remaining release work

- Human playtesting of arrowhead/long-body readability, difficulty and hints; sustained Android frame pacing/heat/battery, physical multitouch coverage, process death and broader cutout/device testing.
- Subjective speaker/headphone audio and haptic testing; real AdMob/UMP callbacks remain device-unverified.
- Production identity/contact, hosted policies, real publisher/unit configuration, signing and Play declarations remain owner work. No production credentials generated and nothing published.

## Primary source changes in 0.2.1

`scripts/generation/level_generator.gd`, `scripts/puzzle/puzzle_rules.gd`, `scripts/gameplay/puzzle_view.gd`, `scripts/gameplay/game.gd`, `scripts/persistence/save_store.gd`, `resources/levels/campaign.json`, project/export version files, generation/grid-picking tests and canonical docs. Difficulty measurement: `release/verification/difficulty-v21-campaign.json`. Pre-difficulty campaign/generator preserved in `/tmp/facet-difficulty-before/`.

## Original overhaul source changes

Replaced movement/generation/solver/renderer behavior; added `compiled_board.gd` and a debug performance probe. Updated game viewport/input/daily orchestration, schema2 migration, topology-based selection, flat-ink joining, all campaign data, tests and authoring/validation tooling. Project/export version and canonical README/architecture/design/testing docs updated. Previous project sources/content were preserved outside the active project at `/home/intelligentape/Projects/Facet3D-backups/edge-v2-before/`.
