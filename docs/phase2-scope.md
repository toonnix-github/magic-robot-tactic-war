# Phase 2: Build Your Mech

Current integration branch: `phase2/build-your-mech`. Issues #35-#42 define the implemented feature contracts; #43 defines evidence and closure. Phase 1 documents remain the combat baseline. This document supersedes their Phase 1-only preparation and HUD scope where explicitly stated below.

## In Scope

- A fixed curated catalog of parts, weapons, off-hand equipment and passive/proc Orbs.
- Hangar inspection, part swaps with stat deltas, weapon and Orb changes, build summary and squad deployment.
- Normal entry is `scenes/preparation_flow.tscn`; the native editor uses the existing Hangar build model. Completed battles return to the same prepared squad for another edit/deploy cycle.
- Sword/Rifle are one-handed; Spear/Sniper require both arms. Shield is left-arm off-hand equipment, not a primary weapon. Destruction disables equipment requiring that arm.
- One Orb per part; destruction disables its effects.
- Current Unit HUD follows initiative; Inspected Unit HUD follows inspection without transferring control. Numeric part/Shield HP and equipment state support tactical decisions.
- Existing movement preview/Confirm/Cancel and visible Manual/Auto resolution remain mandatory; Fast Simulation is only for explicit simulation/debug use.
- Loop: Prepare -> Battle -> Result -> Retry with different build.

## Exclusions

No progression, XP, crafting, economy, town, gacha, skill trees, account services, multiplayer, build preset system or expanded content roster. Phase 1 historical future ideas do not authorize these features.

## Closure Evidence

Run `python -m unittest discover`, Godot's `tests/godot/battle_milestone_test.gd`, and `python tools/gdscript_function_coverage.py --fail-under 80`. Generate the dedicated report with `tools/run_phase2_validation.gd`; preserve Phase 1 historical reports. CI checks report reproducibility on Phase 2 PRs and integration pushes.

The report must record exact squads, mission, seeds, per-run outcomes and metric definitions. Automated evidence verifies integration and deterministic differences; a human must assess build clarity, visible Manual/Auto readability and desire to retry. See `playtest/phase2-human-playtest.md`. Do not close #43 solely because the generator ran or tests passed.

## Execution / Dependency

Review fixes belong to #43 and depend on integrated #35-#42. They are parallel-limited because validation entry points, acceptance tests and shared docs overlap. Integrate through a dedicated PR after Regression passes; final product sign-off follows recorded human review.

## Repository Metadata

Ignore `.godot/` cache. Track stable GDScript `.uid` files and asset `.import` settings to preserve resource identity and import configuration; they are not equivalent to the generated cache. Do not delete local metadata just to clean status.
