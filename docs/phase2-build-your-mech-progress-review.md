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
| Weapon and Orb choices were names only | Hangar now shows range, attack pattern, base damage/hit, required arms, Orb effects and final proc chance after pilot bonuses. Dormant defense/dodge Orb data is labeled as inactive instead of presented as a working bonus. |
| Build stats mixed unlike values | The editor separates part-frame totals from effective loadout values and lists pilot conditional effects independently. Effective hit includes weapon base hit, part accuracy and active Orb hit bonuses; Shield HP includes the pilot passive. |
| Deployment had no squad decision | Deploy opens an opaque squad review with the selected mission, objective, all four mechs, weapons, Shields, roles, armor and movement. Back returns without deploying; Confirm transfers that mission and all loadouts into battle. |
| Equipment was absent from the mech | Original graybox silhouettes for Sword, Rifle, Spear, Sniper and Shield now render attached to the appropriate arms and update immediately with equipment changes. |

## Evidence

Godot 4.7.2: acceptance suite passed. Python: 55 tests passed. Function coverage: 365/380 (96.1%). Coverage rejects Godot script errors even if the engine exits zero and prints a success marker. The Phase 2 foundation remains in [PR #57](https://github.com/toonnix-github/magic-robot-tactic-war/pull/57); visual Hangar and preparation fixes are submitted in [PR #59](https://github.com/toonnix-github/magic-robot-tactic-war/pull/59).

Across the five paired seeds both builds won and Mira survived. Precision averaged 49.0 activations and 187.6 direct damage; Rifle/Shield averaged 40.8 activations and 202.6 direct damage. Rifle/Shield took more damage (62.0 versus 23.6), and Mira intercepted zero attacks in both builds. These observations do not prove Shield interception benefits or universal superiority. They also do not prove human enjoyment.

## UI Integration Gap

Inspection of the actual entry scene found no consumer of the Hangar deploy signal and no interactive equipment selectors. The original API tests therefore overstated playable integration. Fixed with a native-control editor and a preparation flow coordinator. The entry scene now permits unit, part, weapon, Shield and Orb selection; Deploy transfers the squad to battle; Victory/Defeat returns to the preserved Hangar.

Acceptance tests activate the native controls, check their resulting build, review a mission, deploy, complete a battle, return and edit again. Rendered screenshots at 1280x590 and 844x390 were inspected by the agent; Hangar uses vertical scrolling for full equipment details. This is automated developer verification, not human playtesting. Reproduce tracked captures with `tools/render_hangar_evidence.gd`.

Work was isolated at `D:/a/magic-mecha-phase2-review` because concurrent edits were observed in the original checkout. That checkout and its pre-existing Phase 1 report edits were preserved.

## Remaining Human Review

Follow `playtest/phase2-human-playtest.md`. No human session or subjective fun/readability judgment has been claimed. Keep #43 open until a human evaluates the working loop, records blockers or acceptance, and Regression is green.

Detailed per-mech battle result analytics are deferred from Phase 2 at the user's direction. The current Victory/Defeat return flow is sufficient for this phase; closure should focus on understandable preparation, accurate deployment and build differences in battle.

The preparation-side UX findings are now implemented. Remaining closure work is human playtest judgment and integration evidence, not another Hangar feature requirement.
