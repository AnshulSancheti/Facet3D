# CODEX MASTER PROMPT
# BUILD A COMPLETE COMMERCIAL 3D PUZZLE GAME IN GODOT

**Project:** Facet Escape 3D  
**Target platform:** Android  
**Development OS:** Fedora Linux  
**Game engine:** Godot 4.7.2 Stable  
**Programming language:** GDScript  
**Target outcome:** A polished, monetizable, Google Play-ready Android puzzle game.

---

# 0. YOUR ROLE AND PRIMARY OBJECTIVE

You are an autonomous senior game development team consisting of:

- A Godot game engine specialist.
- A GDScript software engineer.
- A 3D graphics and animation developer.
- An algorithms and procedural generation engineer.
- A mobile UI/UX designer.
- An Android build and release engineer.
- A Google AdMob monetization specialist.
- A QA automation engineer.
- A Google Play compliance engineer.

Your mission is to build **Facet Escape 3D**, a fully functional, original, commercially viable Android 3D puzzle game.

The game is inspired by the general concept of directional arrow-removal puzzles, including Amaze Rush 3D, but must be an original product with independently implemented gameplay, original assets, unique mechanics, original branding, and procedural levels.

**I do not want a prototype, mockup, technical demonstration, or planning document. I want the actual game implemented in this repository.**

You must write GDScript, create Godot scenes, configure project settings, implement gameplay systems, generate content, build the interface, integrate monetization, write tests, and prepare the Android release.

## Non-negotiable rules

1. Use Godot 4.7.2 Stable, standard GDScript edition.
2. The project must work natively on Fedora Linux.
3. Do not use Unity, Unreal Engine, C#, or an unrelated framework.
4. Do not create a web game or HTML simulation as a substitute.
5. Create a native Godot project with real `.gd`, `.tscn`, `.tres`, and `project.godot` files.
6. Implement gameplay before secondary features.
7. Never stop after producing an architecture proposal.
8. Execute all implementation phases that can be completed in the available environment.
9. Run actual verification commands wherever possible.
10. Fix compilation errors, invalid resources, and scene-loading failures.
11. Never claim a feature works unless its implementation exists and its relevant tests have been executed.
12. Maintain an accurate task and implementation status file.
13. Keep all developer credentials configurable.
14. Do not publish to Google Play or create paid external accounts without explicit authorization.
15. If software, credentials, SDKs, or hardware are unavailable, finish the unaffected parts of the project and document the exact blocker.
16. The game must remain playable without an internet connection or functioning advertisement service.
17. Do not omit difficult features silently. Either implement them or mark them clearly as incomplete.

Your output must be a real, launchable game project.

---

# 1. GAME VISION

## 1.1 Basic concept

Facet Escape 3D is a satisfying 3D spatial reasoning puzzle game.

The player sees a three-dimensional geometric structure with many directional arrows embedded on or arranged along its surfaces.

Each arrow follows a specific path that may travel across multiple faces of the structure.

The player can rotate the object using touch gestures, inspect different faces, and tap arrows to remove them.

An arrow can leave only when its escape route is clear.

Other arrows may block its route.

The player must discover a valid order in which to remove the arrows until the entire object is cleared.

The puzzle should feel simple to learn, difficult to master, and visually satisfying to solve.

## 1.2 Differentiation from other games

Create a distinctive identity rather than copying a competitor.

Introduce these original gameplay features:

### Feature A: Key-and-lock arrows

Certain arrows contain keys.

Removing a key arrow unlocks one or more locked arrows.

Locked arrows remain immovable even if their physical exit routes are clear.

Use clear iconography and color coding.

### Feature B: Multi-face paths

Some arrow routes travel around corners from one cube face to another.

Players must rotate the structure to understand the complete route.

### Feature C: Surface variations

The launch version must fully support cube puzzles.

Design a reusable surface-topology interface so additional shapes can be implemented without rewriting the solver.

Implement additional shapes only when their geometry, touch behavior, path generation, and solvability can all be correctly verified.

Prioritize a fully functioning cube game over several broken shape modes.

### Feature D: Daily challenges

Generate a deterministic daily puzzle using a stable date-based seed and recorded generator version.

Every player using the same generator version should receive the same daily puzzle for a particular UTC date.

### Feature E: Procedural level generation

Create original levels from algorithms rather than hand-copying existing puzzles.

Levels must have verified solutions.

## 1.3 Target audience

Casual puzzle players who enjoy spatial reasoning, short gaming sessions, and progressively challenging puzzles.

The gameplay must be intuitive enough for a first-time player to understand, without making unsupported assumptions about the legal age category or intended children's audience.

## 1.4 Product priorities

Prioritize:

1. Correct gameplay.
2. Satisfying interactions.
3. Visually polished design.
4. Smooth Android performance.
5. Stable level progression.
6. Reliable procedural generation.
7. Responsible ad monetization.
8. Replayability.
9. Small download size.
10. Google Play compliance.

---

# 2. TECHNICAL STACK AND PROJECT SETUP

## 2.1 Required technology

Use:

- Godot Engine 4.7.2 Stable.
- GDScript with static typing where practical.
- Godot 3D scene system.
- Godot Mobile rendering backend initially.
- Compatibility renderer fallback if required by lower-end Android devices.
- Godot Control-based UI.
- Godot AnimationPlayer and Tween for animations.
- Godot FileAccess and JSON serialization for saving.
- Godot signals for event communication.
- Official Android SDK and Gradle export system.
- Poing Studios Godot AdMob plugin v5.1.0, subject to installed version compatibility.

Do not require a paid asset pack or commercial software license.

## 2.2 Fedora compatibility

Inspect the existing environment.

Check for:

- Godot executable and version.
- OpenJDK 17.
- Android SDK.
- Android SDK Platform 36.
- Android SDK Build Tools.
- Android Platform Tools.
- Compatible Android NDK.
- Gradle build tooling.
- Godot export templates.
- Available Android device through ADB.

Provide Fedora-specific setup instructions.

Where dependencies are missing, install them only when permitted and feasible.

Do not use distribution-packaged Android SDK components if they are outdated or incompatible. Prefer official Android SDK command-line tools.

Document the exact commands in `docs/FEDORA_SETUP.md`.

## 2.3 Project configuration

Configure the project for:

- Portrait screen orientation.
- Smooth mobile touch interaction.
- Responsive UI scaling.
- Appropriate texture filtering.
- Efficient mobile rendering.
- Android package identifier placeholder: `com.yourstudio.facetescape3d`.
- Application display name: `Facet Escape 3D`.
- Saved progress under the Godot user data directory.
- Versioned gameplay configuration.

Do not use a real developer identity without being given one.

Set the main scene correctly.

Opening the project and pressing F6/F5 as appropriate must produce a functional game, not a missing-resource error.

---

# 3. PROJECT DIRECTORY STRUCTURE

Create a clean, maintainable structure resembling:

```text
FacetEscape3D/
├── project.godot
├── export_presets.cfg
├── README.md
├── IMPLEMENTATION_STATUS.md
├── ARCHITECTURE.md
├── GAME_DESIGN.md
├── CHANGELOG.md
├── .gitignore
│
├── scenes/
│   ├── main/
│   ├── gameplay/
│   ├── puzzles/
│   ├── ui/
│   └── effects/
│
├── scripts/
│   ├── core/
│   ├── puzzle/
│   ├── geometry/
│   ├── generation/
│   ├── solver/
│   ├── gameplay/
│   ├── camera/
│   ├── input/
│   ├── ui/
│   ├── audio/
│   ├── ads/
│   ├── privacy/
│   ├── persistence/
│   └── utilities/
│
├── resources/
│   ├── levels/
│   ├── configurations/
│   └── themes/
│
├── assets/
│   ├── materials/
│   ├── textures/
│   ├── fonts/
│   ├── icons/
│   ├── audio/
│   └── effects/
│
├── addons/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── generation/
│   └── runners/
│
├── tools/
│   ├── generate_levels.gd
│   ├── validate_levels.gd
│   ├── build_android.sh
│   └── run_tests.sh
│
├── docs/
│   ├── FEDORA_SETUP.md
│   ├── ADMOB_SETUP.md
│   ├── PRIVACY_POLICY_DRAFT.md
│   ├── DATA_SAFETY.md
│   ├── PLAY_STORE_RELEASE.md
│   ├── TESTING_GUIDE.md
│   └── LICENSES.md
│
└── release/
    ├── store_listing/
    ├── screenshots/
    ├── icons/
    └── checklists/
```

You may improve the structure if there is a technically justified reason.

Do not create folders merely to give the appearance of implementation.

Each major gameplay subsystem must contain functional code.

---

# 4. MATHEMATICAL PUZZLE REPRESENTATION

Build the logical puzzle engine first.

The puzzle model must not depend on rendered meshes or camera positions.

## 4.1 Cube representation

Represent the cube using six faces:

- Front
- Back
- Left
- Right
- Top
- Bottom

Each face contains an N × N logical grid.

The resolution should be configurable.

Represent a surface cell using:

- Face identifier.
- Row.
- Column.

Implement conversions between:

- Surface coordinates.
- Face-local coordinates.
- World-space positions.
- World-space normal vectors.

Use correct 3D transformations.

A path crossing an edge must arrive on the correct neighboring face with the correct row, column, and orientation.

Do not simply reuse the same row and column when switching faces.

## 4.2 Surface topology

Create a surface topology module responsible for:

- Neighbor lookup.
- Edge transitions.
- Valid surface movements.
- Coordinate conversion.
- World-space path sampling.
- Orientation changes.
- Detecting out-of-bounds paths.

The topology must be testable without loading a rendered puzzle scene.

## 4.3 Arrow model

Each arrow must have:

- Unique ID.
- Starting position.
- Facing direction.
- Ordered escape path.
- Currently occupied cells or geometry.
- Current movement state.
- Lock state.
- Optional key identifier.
- Optional unlock targets.
- Display material.
- Visual geometry reference.

Represent arrow geometry and movement consistently.

The player must be able to understand the arrow's actual path visually.

## 4.4 Movement rules

Define deterministic movement rules.

An arrow should be removable only when:

1. It exists in the current puzzle state.
2. It has not already been removed.
3. It is not moving.
4. It is not locked.
5. Its full required exit trajectory is valid.
6. Its swept occupied geometry does not intersect any remaining blocking piece.

A valid move must transition to a new logical board state.

An invalid move must leave the logical state unchanged.

## 4.5 Collision validation

Implement logical collision validation independently from the physics engine.

Use Godot's physics system for touch selection and visual raycasting, not as the sole authority on puzzle legality.

Logical collision calculations should support:

- Path intersections.
- Occupied surface cells.
- Arrow footprints.
- Full movement trajectories.
- Corner transitions.
- Current remaining pieces.

A simplistic check of only an arrow's destination cell is insufficient.

Use a consistent geometric model that agrees with the renderer.

Avoid invisible obstacles and visually misleading collisions.

---

# 5. GRAPH ALGORITHMS AND PUZZLE SOLVING

Implement proper algorithms rather than hardcoding valid removal orders.

## 5.1 Dependency graph

Represent arrows as graph vertices.

Represent prerequisite relationships using directed edges.

If arrow A must be removed before arrow B, create a dependency edge from A to B.

Implement:

- Adjacency lists.
- Dependency discovery.
- Kahn's topological sorting.
- Cycle detection.
- Dependency depth.
- Available move detection.
- Lock dependency management.

## 5.2 Dynamic state solver

Some puzzles may have state-dependent legal moves.

Therefore, do not assume a static topological sort solves every possible puzzle.

Implement a general puzzle solver using DFS and backtracking with memoization.

The solver should:

1. Read the current puzzle state.
2. Determine all legal moves.
3. Try each move.
4. Apply the move to a simulated state.
5. Recursively search.
6. Backtrack when necessary.
7. Cache already-examined states.
8. Return a valid solution or report unsolvability.

Use compact, deterministic state serialization for memoization.

Avoid modifying the live rendered game state during simulation.

## 5.3 Solver results

Expose:

- Whether the puzzle is solvable.
- One valid removal sequence.
- Number of immediate legal moves.
- Approximate puzzle complexity.
- Number of explored states.
- Search timeout or budget status.

A search timeout must not be reported as proof that the puzzle is unsolvable.

## 5.4 Hint algorithm

Hints must come from the actual solver.

When requested:

1. Evaluate the current board.
2. Find a valid solution continuation.
3. Highlight the next suitable removable arrow.
4. Avoid mutating game state.
5. Consume the hint only after a valid hint is delivered.

Hints must never point toward an illegal move.

---

# 6. PROCEDURAL LEVEL GENERATION

This is one of the most important features.

The game must support reproducible, procedurally generated puzzles.

## 6.1 Generator architecture

Use an independent generation module.

Input parameters should include:

- Random seed.
- Board size.
- Arrow count.
- Difficulty.
- Target route complexity.
- Desired dependency depth.
- Key-and-lock count.
- Maximum generation attempts.

Output should be a serializable validated level definition.

## 6.2 Reverse-construction algorithm

Implement reverse construction where the established movement rules allow it.

Suggested method:

1. Begin with an empty board.
2. Generate an arrow with a valid route and clear exit.
3. Add the arrow without invalid overlaps.
4. Add another arrow that is currently removable while potentially blocking an earlier arrow.
5. Continue adding arrows in a known reverse-solution order.
6. Introduce key-and-lock relationships consistent with the known removal sequence.
7. Save the intended solution candidate.
8. Independently validate the completed board using the solver.
9. Reject unsolvable or invalid levels.
10. Regenerate using another seed when necessary.

Prove that each accepted generated level has at least one valid removal sequence.

Do not generate arbitrary random arrow layouts and merely hope they are solvable.

## 6.3 Generator constraints

Reject levels containing:

- Overlapping arrow geometry.
- Invalid routes.
- Broken face transitions.
- Permanently locked arrows.
- Unreachable exit trajectories.
- Impossible states.
- Unintended deadlocks.
- Unsupported geometric configurations.

Bound generation attempts and execution time.

Use validated fallback content when necessary.

## 6.4 Difficulty levels

Implement five difficulty tiers:

**Beginner:** 4–8 arrows, short paths, obvious removal order.

**Easy:** 8–15 arrows, simple multi-face interactions.

**Medium:** 15–25 arrows, longer paths and dependencies.

**Hard:** 25–40 arrows, more complex geometry and locks.

**Expert:** 40+ arrows where supported by performance and visual readability.

These are initial design targets, not rigid requirements if the board becomes unreadable.

Measure difficulty using:

- Arrow count.
- Maximum dependency depth.
- Number of initially removable arrows.
- Branching factor.
- Route length.
- Face transition count.
- Lock count.
- Solver effort.
- Spatial density.

A level with many arrows is not automatically difficult.

## 6.5 Level library

Generate at least 100 valid campaign levels.

Organize them into difficulty groups.

Store levels as JSON or Godot resources.

Every level should have:

- Level number.
- Generator version.
- Random seed.
- Difficulty.
- Puzzle definition.
- Known valid solution.
- Validation metadata.

Use reproducible offline generation before shipping the campaign.

## 6.6 Stress testing

Generate and validate at least 1,000 sample levels across different seeds.

Report:

- Attempts.
- Success rate.
- Invalid generations.
- Solver outcomes.
- Maximum generation time.
- Average generation time.
- Worst-case solver state count.

Provide diagnostic output for failures.

Do not suppress failed cases or fabricate performance metrics.

---

# 7. 3D RENDERING

Implement the complete visual puzzle.

## 7.1 Main puzzle scene

Use appropriate Godot nodes such as:

- `Node3D`
- `MeshInstance3D`
- `Camera3D`
- `DirectionalLight3D`
- `WorldEnvironment`
- `StaticBody3D`
- `Area3D`
- `CollisionShape3D`

Prefer procedurally generated geometry for the first version.

## 7.2 Visual arrows

Arrows must look like physical, polished puzzle pieces.

Use:

- Clean geometry.
- Rounded-looking edges where feasible.
- Directional arrowheads.
- Clear separation from the board.
- Soft highlights.
- Different materials for special pieces.
- Smooth curved transitions around cube edges.

Build a reusable arrow renderer that follows a list of world-space path samples.

The renderer must match the logical model.

## 7.3 Materials

Use a cohesive, original visual style.

Suggested colors:

- Background: `#10182B`
- Slate: `#273958`
- Teal: `#33D6C5`
- Amber: `#FFBE63`
- Foreground: `#F4F7FC`

Use slightly reflective materials, pleasant lighting, and restrained highlights.

Avoid excessive bloom or shader effects that cause overheating on mobile devices.

## 7.4 Animations

Implement:

- Arrow removal animations.
- Arrow following its actual escape route.
- Corner transition animations.
- Invalid tap response.
- Key unlocking effects.
- Cube entrance animation.
- Level completion effects.
- Menu transitions.
- Button feedback.

Use easing and short durations.

Animations must be interrupt-safe.

A level restart must cancel or safely resolve active animations.

## 7.5 Camera

Implement:

- One-finger rotation.
- Pinch-to-zoom.
- Mouse drag in the editor.
- Mouse wheel zoom in the editor.
- Smooth camera movement.
- Minimum and maximum zoom.
- Object framing.
- Inertia and sensitivity limits.

Ensure that the cube cannot disappear or become impossible to inspect.

---

# 8. MOBILE TOUCH CONTROLS

Use Godot's native input system.

Handle:

- `InputEventScreenTouch`
- `InputEventScreenDrag`
- Mouse input for desktop testing.
- Multitouch pinch gestures.

## 8.1 Input differentiation

A tap should select an arrow.

A drag should rotate the puzzle.

Use a movement threshold to distinguish these gestures.

Do not trigger a selection after a rotation gesture.

## 8.2 Arrow selection

Use a camera ray and physics query to identify the tapped piece.

Each arrow must have a logical ID linked to its selectable visual geometry.

When touched:

1. Identify the arrow.
2. Query the puzzle controller.
3. Attempt a legal move.
4. Animate the result.
5. Update gameplay state.

## 8.3 Input robustness

Prevent:

- Double removals.
- Multiple move commits from one tap.
- Interaction during unsafe state transitions.
- Selecting already removed arrows.
- Starting another level while the previous level is unloading.

Include a reduced-motion option.

---

# 9. FULL USER INTERFACE

The UI must look like a commercial mobile game.

Do not create an interface made of default Godot gray buttons.

Use a consistent theme with polished panels, typography, spacing, icons, and transitions.

## 9.1 Splash screen

Include:

- Original game logo or wordmark.
- Brief loading transition.
- Smooth entry into the main menu.

Do not force an ad on startup.

## 9.2 Main menu

Required buttons:

- PLAY
- CONTINUE
- LEVEL SELECT
- DAILY CHALLENGE
- SETTINGS

Display the current progression level.

Use an animated 3D puzzle object as a subtle background if performance permits.

## 9.3 Gameplay HUD

Include:

- Current level number.
- Undo.
- Restart.
- Hint.
- Pause.
- Progress display.

Place controls where they are comfortable to use in portrait mode.

Avoid obscuring the puzzle.

## 9.4 Level complete screen

Show:

- Victory animation.
- Level completed message.
- Moves made.
- Time taken.
- Next Level button.
- Optional challenge summary.

Use restrained confetti or original particle effects.

## 9.5 Level selection

Create a scrollable grid.

Show:

- Completed levels.
- Current level.
- Locked levels.
- Difficulty grouping.

Opening unlocked levels must work correctly.

## 9.6 Pause menu

Include:

- Resume.
- Restart.
- Settings.
- Main menu.

## 9.7 Settings

Include:

- Sound on/off.
- Music on/off.
- Haptics on/off.
- Camera sensitivity.
- Reduced motion.
- Privacy Policy.
- Privacy Options where required.
- Credits.

Save all settings persistently.

## 9.8 Daily challenge

Display:

- Today's challenge.
- Puzzle difficulty.
- Completion status.
- Local best completion time.

Daily challenge progress must not overwrite campaign progress.

## 9.9 Safe areas

Support common Android screen sizes.

Respect:

- Status bars.
- Camera cutouts.
- Navigation areas.
- Display aspect ratios.

Test responsive UI at multiple simulated resolutions.

---

# 10. TUTORIAL AND ONBOARDING

Design the first five levels as guided onboarding.

### Level 1: First arrow

Teach the player to tap an available arrow.

### Level 2: Rotate the puzzle

Teach touch dragging.

### Level 3: Blocked arrows

Show why some arrows must be removed first.

### Level 4: Cross-face movement

Introduce paths wrapping around a cube corner.

### Level 5: Keys and locks

Introduce the game's signature mechanic.

Tutorial messages should appear contextually.

Avoid blocking progress behind long explanations.

The tutorial must work without internet access or ads.

---

# 11. PLAYER PROGRESSION

Implement persistent local save data.

Store:

- Highest unlocked level.
- Completed levels.
- Current level.
- Best level times.
- Hint balance.
- Daily challenge results.
- Preferences.
- Basic local gameplay statistics.

Use JSON with versioned schemas and `FileAccess`.

Implement safe saving with temporary files and appropriate replacement handling where feasible.

Detect corrupted saves.

Recover to sensible defaults without crashing.

Handle application pause, backgrounding, and termination appropriately.

No backend is required for version 1.

Do not add compulsory account creation.

---

# 12. HINTS, UNDO, AND RESTART

## 12.1 Hints

Provide initial free hints.

When the player uses a hint:

- Check availability.
- Call the solver.
- Identify a valid move.
- Visually highlight it.
- Decrement the balance only after successful delivery.

## 12.2 Undo

Implement state history or reversible commands.

Undo must restore:

- Removed pieces.
- Lock states.
- Board occupancy.
- Relevant gameplay state.

Avoid consuming hints or duplicating unlock rewards because of undo.

## 12.3 Restart

Restart the current puzzle from its original deterministic definition.

Cancel animations and outstanding input safely.

Restore initial positions and locks.

---

# 13. SOUND AND HAPTICS

Include original lightweight effects:

- UI tap.
- Successful removal.
- Invalid tap.
- Unlock.
- Hint.
- Victory.

Use procedural or appropriately licensed audio.

Implement Android haptics only when supported and enabled.

Sound and haptic effects should enhance feedback without becoming intrusive.

Do not require an external music subscription or copyrighted tracks.

---

# 14. GOOGLE ADMOB MONETIZATION

Integrate Google AdMob for Android.

Use the maintained Poing Studios Godot AdMob plugin, targeting a verified compatible stable release.

Official project:

https://github.com/poingstudios/godot-admob-plugin

Documentation:

https://poingstudios.github.io/godot-admob-plugin/

## 14.1 Architecture

Never couple gameplay progression directly to the AdMob SDK.

Implement an ad-service abstraction.

Suggested components:

```text
AdsService
MockAdsService
AdMobAdapter
RewardedAdController
InterstitialAdController
ConsentManager
AdConfiguration
```

The game must compile and run even when the native advertising plugin is unavailable.

Use feature detection or conditional integration.

The mock service must not be mistaken for real monetization.

## 14.2 Rewarded advertisements

Allow the player to voluntarily watch an advertisement to obtain a hint.

Flow:

1. Player requests a hint.
2. Check free hint balance.
3. If free hints exist, use one.
4. Otherwise show an optional rewarded-ad offer.
5. Confirm that an ad is available.
6. Show the ad after a deliberate user action.
7. Wait for the legitimate reward callback.
8. Credit the player once.
9. Allow the player to use the hint.

If the ad fails:

- Do not freeze the game.
- Do not fake a successful advertisement.
- Do not remove anything from the player.
- Provide a clear nonblocking response.

Never award a reward multiple times because of repeated callbacks.

## 14.3 Interstitial advertisements

Only display interstitial ads at natural gameplay transitions.

Initial configuration:

- No interstitial ads during the first five levels.
- An interstitial may be shown after every fourth completed level.
- At least 180 seconds between interstitials.
- No interstitial while solving a puzzle.
- No startup interstitial.
- No interstitial after tapping Restart.
- No interstitial that unexpectedly interrupts a level.

Implement these as configurable defaults.

Ads must never prevent the player from reaching the next level.

## 14.4 Consent management

Use the supported UMP consent features.

The implementation must:

- Request updated consent information at app launch.
- Display consent forms when required.
- Respect whether ads may be requested.
- Provide privacy options when required.
- Handle error states.
- Avoid unnecessary repeated initialization.
- Respect applicable age-related advertising requirements.

Do not assume advertising consent is always required or always unnecessary. Follow the SDK's documented jurisdiction-aware flow.

## 14.5 Test ads

Use Google's official Android test ad unit IDs during development.

Never test by repeatedly loading or clicking actual live ads.

Provide a clear switch between:

- Development test mode.
- Production mode.
- Ads disabled mode.

Production mode must remain disabled unless valid real AdMob configuration is supplied.

## 14.6 Ad configuration

Externalize:

- AdMob Android App ID.
- Interstitial ad unit ID.
- Rewarded ad unit ID.
- Test mode.
- Interstitial cooldown.
- Level frequency.
- Consent configuration.

Do not confuse AdMob App IDs with ad unit IDs.

Do not invent real publisher IDs.

## 14.7 Native Android integration

Use the plugin's documented Android installation steps.

Configure:

- Android Gradle build template.
- Native Android plugin support.
- Required advertisement dependencies.
- AdMob application ID.
- Android manifest entries where required.
- Permission declarations.
- UMP consent integration.

Pin compatible dependency versions.

Verify all native dependencies and generated Android manifests.

Do not write imaginary plugin APIs. Read the plugin's installed source and documentation before implementing the adapter.

## 14.8 app-ads.txt

Create an `app-ads.txt` template.

Document:

- Publisher ID configuration.
- Developer website association.
- File hosting.
- File URL verification.
- AdMob readiness checks.

Do not fabricate the publisher ID.

## 14.9 Invalid traffic prevention

Never:

- Automatically click advertisements.
- Simulate ad impressions.
- Force users to interact with ads.
- Use invisible advertisements.
- Generate artificial traffic.
- Mislabel buttons that trigger ads.

Gameplay must remain genuinely usable without watching advertisements.

---

# 15. GAME ANALYTICS

Implement a lightweight analytics event layer.

Events:

- App launch.
- Session start.
- Level start.
- Level complete.
- Level restart.
- Hint used.
- Rewarded ad requested.
- Rewarded ad completed.
- Interstitial displayed.
- Ad load failed.
- Daily challenge completed.

Use local logging initially.

External analytics should be optional and disabled until properly configured.

Do not collect unnecessary personal information.

Prepare the system to measure:

- Average play session.
- Level completion rate.
- Retry frequency.
- Day 1 retention.
- Day 7 retention.
- Ad impressions per active user.
- Rewarded ad opt-in rate.

Actual revenue statistics should come from AdMob, not fabricated local estimates.

---

# 16. PERFORMANCE REQUIREMENTS

Optimize for Android devices, not a desktop gaming PC.

Targets:

- Aim for 60 FPS on capable mid-range and high-end phones.
- Maintain a playable 30 FPS fallback on less powerful devices.
- Keep memory consumption reasonable.
- Avoid long loading stalls.
- Keep installation size small where practical.
- Reduce unnecessary battery usage.

Implement:

- Efficient meshes.
- Shared materials.
- Object pooling where useful.
- Limited particle systems.
- Efficient selection raycasts.
- Minimal per-frame allocations.
- Bounded procedural generation.
- Simple lighting when possible.
- Performance-friendly shaders.

Do not regenerate all puzzle geometry every frame.

Reuse resources appropriately.

Provide graphics quality settings if testing demonstrates a need.

Measure performance on actual hardware before claiming targets have been met.

---

# 17. ANDROID EXPORT

Prepare a complete Android export workflow for Fedora.

## 17.1 Required build output

Support:

- Debug APK for local testing.
- Signed release Android App Bundle (`.aab`) for Google Play.

Use Godot's Gradle-based Android export workflow where needed.

## 17.2 Android settings

Configure:

- Correct Android package identifier.
- ARM64 architecture.
- Portrait orientation.
- Supported minimum SDK based on the engine and plugin requirements.
- Target API 36 or higher.
- Current compatible Android SDK.
- Current compatible build tools.
- 16 KB memory page-size compatibility.
- Valid adaptive launcher icons.
- Incrementing app version code.
- Proper release signing.

Verify requirements against current official Google Play documentation rather than assuming defaults remain compliant.

## 17.3 Build automation

Create `tools/build_android.sh`.

The script should:

1. Detect the Godot executable.
2. Verify its version.
3. Validate required SDK paths.
4. Check export templates.
5. Run a project import.
6. Execute available automated tests.
7. Stop if critical checks fail.
8. Build a development APK when requested.
9. Build a release AAB when signing information is supplied.
10. Save build logs.
11. Print output locations and errors.

Never hardcode signing passwords.

Support credentials supplied through environment variables or another secure mechanism.

## 17.4 Signing

Document secure keystore generation.

Ensure:

- Keys are not committed.
- Passwords are not committed.
- `.gitignore` excludes sensitive artifacts.
- Release signing settings are documented.
- Google Play App Signing is explained.

Do not generate actual production credentials without permission.

## 17.5 16 KB compatibility

Audit the final Android package for compatibility with 16 KB memory page sizes.

Check both Godot's native libraries and native libraries introduced by plugins.

If a plugin is incompatible, do not declare the release ready.

Document required dependency updates or replacements.

---

# 18. GOOGLE PLAY POLICY REQUIREMENTS

Prepare for Google Play publication from the beginning.

## 18.1 Originality

The game must not be a direct copy of Amaze Rush 3D.

Use:

- Original gameplay implementation.
- Original UI design.
- Original branding.
- Original puzzle generation.
- Original graphics.
- Original sounds.
- Meaningfully distinctive key-and-lock mechanics.

Do not reproduce another game's level database, screenshots, names, icons, or distinctive artwork.

## 18.2 Repetitive content

The game must provide genuine gameplay value.

Do not create multiple nearly identical game packages merely to increase store presence.

Keep the first release focused on one polished game.

## 18.3 Privacy policy

Draft a privacy policy based on the actual application.

Cover:

- Advertising SDKs.
- Data collected or shared by those SDKs.
- Consent.
- Device identifiers where applicable.
- Developer contact details.
- Third-party services.
- Data retention and deletion.
- Applicable user privacy rights.

Use placeholders for unknown developer information.

Do not claim that no data is collected merely because gameplay progress is stored locally.

## 18.4 Play Console Data Safety

Create a data inventory.

Review every included SDK and identify:

- Data collected.
- Data shared.
- Purpose.
- Encryption.
- Retention.
- Optional collection.
- User controls.

Produce a draft declaration checklist, not invented legal assertions.

## 18.5 Target audience

Prepare appropriate target-audience declarations.

Do not assume that a colorful puzzle game must target children.

If the intended audience includes children, evaluate additional Google Play Families advertising and privacy requirements before release.

## 18.6 Testing

