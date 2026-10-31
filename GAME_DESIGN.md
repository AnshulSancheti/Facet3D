# Facet Escape 3D — dense face-edge puzzles

Rotate a ceramic cube and tap flat arrows to clear it. A head can escape if every cell straight ahead on its current face is empty and its lock is open. The body snakes after it through its bends; the head leaves tangentially at the edge rather than traveling onto another face. There are no visible or stored future tracks.

An arrow is one connected, non-branching, self-avoiding chain of 2–15 occupied cells. Generated pieces cannot intersect their own exit lane. Longer straight, L/U/S and zigzag bodies share space without overlapping. After onboarding, 10–20% wrap on small grids and 5–20% on larger grids across one or two cube corners. Gold key and pearl lock symbols carry matching numbers and remain flat on their piece.

| Levels | Face grid | Board occupancy | Maximum length |
|---|---:|---:|---:|
| 1–5 | 5×5 | Guided | 6 |
| 6–20 | 9×9 | 55–65% | 7 |
| 21–40 | 13×13 | 65–75% | 10 |
| 41–60 | 17×17 | 75–82% | 12 |
| 61–80 | 21×21 | 80–87% | 15 |
| 81–100 | 25×25 | 78–83% | 15 |

All six faces are populated after onboarding. Each face must reach at least the tier's lower occupancy target minus ten percentage points. At least 60% of pieces bend. Mature boards require at least 25% long pieces (10–15 cells); the intended distribution is roughly 20% short, 50% medium and 30% long. No single-cell filler pieces are generated. Actual per-level histograms, density, dependencies, legal moves and shape metrics are recorded.

The first five levels teach tapping, rotation/pinch, blocking, bent bodies and keys. Wrapped bodies arrive afterward. Hints come from a verified current-state solution, frame the head face and highlight the whole piece. Undo restores the last arrow and derived lock state without refunding hints. Restart restores the deterministic original definition. Reduced motion suppresses travel/pulsing.

Touch: tap selects any occupied cell, one finger rotates, two fingers pinch to zoom. No pan or mode toggle. The play area clips zoomed geometry before the HUD. Desktop uses mouse drag and wheel. The overview remains large; up to 3× zoom supports precise inspection of dense faces.

UTC daily puzzles are deterministic, 25×25, independent of campaign progression and generated asynchronously. Campaign unlocks the next level; no compulsory account, energy system, network gate or timed failure exists. Existing schema-1 progress is archived; the new campaign starts at 1 with hints/preferences retained.

Difficulty is measured from actual physical blockers: non-tutorial opening choices are capped at 15/10/7/5/4% by tier, with minimum dependency depths of 12/25/40/60/80. Rounded turns at arrowheads let bodies point inward and interlock without overlapping. No hidden blockers or arbitrary waiting rules are added. The first five levels remain short onboarding.
