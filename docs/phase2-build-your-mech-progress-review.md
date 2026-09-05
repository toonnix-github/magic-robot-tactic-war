# Phase 2 Progress Review and Fixes

Review date: 2026-09-05. Integration: `phase2/build-your-mech`. Closure issue: #43.

## Status

Issues #35-#42 are merged, but their API-level acceptance did not establish a usable end-to-end UI. Phase 2 remains pending product sign-off.

## Findings Addressed

| Finding | Resolution |
| --- | --- |
| Missing dedicated report | `playtest/phase2-build-fun-validation-report.md` records both complete squads and five paired seeds. |
| Unsupported sign-off claims | Generator describes automated evidence only; human judgment remains pending. |
| Validation ownership in main | Scenario setup, metrics and report belong to `src/testing/phase2_build_validation.gd`; main orchestrates an isolated scene. |
| Validation resets player state | A separate simulation scene preserves the caller's battle, loadouts and presentation state. |
| Invalid damage parser | Read actual damage events, exclude un-attributable delayed damage from dealt totals and count Burn taken once. Unit tests cover Shield, Burn and attack boundaries. |
| Missing Phase 2 CI triggers | Regression runs on Phase 2 integration pushes and targeted PRs; also verifies report reproducibility. |
| Stale scope documents | `phase2-scope.md` defines current scope; AGENTS and historical design docs point to it. |
| Missing exact configuration | Report includes complete squads, mission, sides, seeds, activation cap and per-run outcomes. |
| Generated metadata | Ignore .godot cache; track stable .uid and asset .import settings intentionally. Phase 1 report is unchanged in this PR. |

## Evidence

Godot 4.7.2: acceptance suite passed. Python: 53 tests passed. Function coverage: 337/351 (96.0%). Coverage now rejects Godot script errors even if the engine exits zero and prints a success marker. [GitHub Regression passed](https://github.com/toonnix-github/magic-robot-tactic-war/actions/runs/33965982996) for implementation commit `85adda7`, including report reproducibility. Changes are submitted in [PR #57](https://github.com/toonnix-github/magic-robot-tactic-war/pull/57).

Across the five paired seeds both builds won and Mira survived. Precision averaged 49.0 activations and 187.6 direct damage; Rifle/Shield averaged 40.8 activations and 202.6 direct damage. Rifle/Shield took more damage (62.0 versus 23.6), and Mira intercepted zero attacks in both builds. These observations do not prove Shield interception benefits or universal superiority. They also do not prove human enjoyment.

## UI Integration Gap

Inspection of the actual entry scene found no consumer of the Hangar deploy signal and no interactive equipment selectors. The original API tests therefore overstated playable integration. Fixed with a native-control editor and a preparation flow coordinator. The entry scene now permits unit, part, weapon, Shield and Orb selection; Deploy transfers the squad to battle; Victory/Defeat returns to the preserved Hangar.

Acceptance tests activate the native controls, check their resulting build, deploy, complete a battle, return and edit again. Rendered screenshots at 1280x590 and 844x390 were inspected by the agent; Hangar uses vertical scrolling for full build/squad details. This is automated developer verification, not human playtesting. Reproduce captures with `tools/capture_phase2_flow.gd`; images are saved to Godot's user data directory.

Work was isolated at `D:/a/magic-mecha-phase2-review` because concurrent edits were observed in the original checkout. That checkout and its pre-existing Phase 1 report edits were preserved.

## Remaining Human Review

Follow `playtest/phase2-human-playtest.md`. No human session or subjective fun/readability judgment has been claimed. Keep #43 open until a human evaluates the working loop, records blockers or acceptance, and Regression is green.
