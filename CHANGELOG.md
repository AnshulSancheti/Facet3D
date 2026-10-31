# Changelog

## 0.2.2 — clearer cube edges and finer arrows

- Replaced rounded cube geometry with sharp corners, flat face normals, subtle face-tone separation and a fine contrasting rim.
- Reduced arrow body width about 30%, arrowhead span about 21% and head stroke about 18%. Moving arrows use the same thinner body width.
- Adapted flat ink projection across sharp seams; retained selection footprints, all puzzle definitions and generation behavior.
- 196,431 logic checks, full campaign replay/DFS, 3,750 grid picks, geometry and portrait UI checks pass; native viewport/zoom render inspected.


## 0.2.1 — larger interlocking boards

- Expanded progression to 9/13/17/21/25 cells per face after the five onboarding levels.
- Reoriented bodies and rounded head bends to create physical dependency chains; reject boards with too many opening moves or shallow dependencies.
- Expert campaign now has 339–379 arrows, 1–13 opening moves and dependency depths of 80–137. Independent geometry replay and DFS verify all 100 boards.
- Generator and Daily records versioned independently; existing campaign progress/settings/hints remain intact.
- 1,000 stress seeds passed; native-resolution Android debug build 0.2.1/version-code3 installed and profiled on CPH2487 at roughly 59.6–60 FPS in short 355-arrow Daily samples. Device evidence recorded in IMPLEMENTATION_STATUS.md.


## 0.2.0 — dense face-edge overhaul
- Removed escape tracks/launch points; heads now leave straight off their own face when clear.
- Long bent/wrapped flat arrows, dense 15×15 faces and 100 newly validated campaign boards.
- Indexed blocker graph, independent occupancy replay and 1,000-seed stress validation.
- One mesh per arrow, one selection collider, incremental undo/removal, clipped central viewport and 3× pinch zoom.
- Async deterministic daily generation with a validated fallback; no panning.
- Schema2 exact-byte old-save archive; new campaign starts at 1 with hints/settings retained.
- Continuous bend joins and physical-resolution viewport; physical-resolution viewport shipped with the subsequent 0.2.1 update.
- Bounded debug frame/memory probe and updated docs/tests.


## Flat 2D arrows — 2026-10-22
- Replaced raised arrow meshes, rings and special-piece symbols with flat surface markings.
- Face-aligned identifiers and surface-conforming corner strokes; removal uses flat ribbons.
- Preserved generous invisible touch targets and unchanged puzzle logic/progression.
- Added flat-geometry regression tests; rebuilt, audited and installed the debug APK on the phone.

## Moonlit ceramic redesign — 2026-10-22
- Continuous beveled ceramic sculpture, moonlit gradient/light pool and softer lighting.
- Serif branding, consistent secondary screens, original line icons and full portrait layout.
- Corner-aware camera fitting and distinct luminous pieces versus escape guides.
- Original 48-second ambient arrangement, glass/drop effects and lifecycle music fades.
- Expanded presentation tests; debug APK built, audited, installed and smoke-tested on CPH2487.
- Fixed phone-only black surface patches by using a matte standard material with specular/MSAA disabled.

## Calm atmospheric redesign — 2026-10-22
- Thin luminous routes, subtle nodes/chevrons, matte slate cube and midnight palette.
- Larger portrait framing, compact HUD, quiet menu and emission-based highlights.
- Screen-axis drag rotation, optional inversion and aspect-aware camera distance.
- Cached glass/drop effects and seamless ambient music; puzzle rules/content preserved.
- Added drag-direction and cube/UI clearance regression checks.

## 0.1.0 — initial implementation
- Native Godot project, cube topology, swept-route movement and key/lock rules.
- Independent graph analysis, bounded DFS, reverse construction and 100 campaign puzzles.
- 3D pieces, route guides, picking, rotation/zoom and route-following removal.
- Menus, progression, daily mode, undo, restart, solver hints, settings and local save recovery.
- Original synthesized audio, local analytics, disabled-by-default native AdMob integration.
- Automated logic, generation, persistence, ads and gameplay integration checks.
- Android export workflow and draft release/privacy documents.
