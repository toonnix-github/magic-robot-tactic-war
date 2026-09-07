# Fantasy character building screen — #76

This preparation prototype implements the user-approved fantasy pivot. At the user's request it is now the default F5 entry point. It does not change the existing mech combat or Phase 2 closure requirements; the legacy preparation scene remains directly runnable.

## Scope

Five human job entries (Knight, Warrior, Ranger, Mage, Healer), a static layered character illustration, nine equipment slots, six unique assignable fairies, computed stat totals and item comparisons. Follow Job / Stay Safe is saved as a preparation preference only. No battle entry, battle rules, progression, rarity, or acquisition implementation.

Equipment slots: headgear, right hand, left hand, armor, shoes, cape, accessory 1, accessory 2, fairy. Job/hand restrictions are authoritative in the build model. Two-handed weapons block the left hand. Fairies are unique: assigning an occupied fairy explicitly transfers it and leaves the previous hero's fairy slot empty. The UI identifies that consequence before the transfer.

Level 1 stats and all equipment numbers are provisional preview values. Stat point costs were explicitly deferred by the user, so allocation/progression are not implemented in this screen. All items are unlocked; repeated gear copies are allowed. Builds persist locally in a versioned save, with invalid saved entries ignored. Resetting the party requires confirmation.

## Execution / Dependency

- Dependencies: current `phase2/build-your-mech` project shell; no dependency on unfinished #70 art or #43 sign-off.
- Independently developable: yes, through a standalone Godot scene.
- Parallel-safe for neighboring combat/UI work: new fantasy data/model/view files; only Regression workflow and milestone test runner integration are shared.
- Shared-file conflict risk: milestone runner, Regression workflow and asset import in the coverage runner. Cold test copies must import the raster atlas before loading the screen.
- Integration: PR into `phase2/build-your-mech`; switch the default entry to the fantasy builder at the user's request and expose a dedicated fantasy launcher. Preserve legacy scenes.

## Acceptance

- All five jobs can be selected; each retains its own equipment and order.
- Selecting a slot shows legal candidates, current equipment, stat deltas and ability descriptions.
- Invalid equipment and illegal off-hand combinations cannot enter the model.
- Swaps update totals and visible illustration layers; accessories are represented by slots.
- Six fairy choices show element, bonuses and fixed abilities with no rarity.
- An occupied fairy requires an explicit transfer action and never duplicates ownership.
- Saves round-trip and malformed save data cannot crash or invalidate the party.
- Usable landscape layout at 1280x590 and 844x390; scrollable choices and accessible buttons.
- New Python boundary tests and Godot behavioral/UI acceptance tests start red, then pass; existing regression stays green.

## Run

Open this checkout's `project.godot` in Godot and press F5, or use `launch-fantasy-builder.cmd`. The launcher discovers GODOT_BIN, PATH or portable Godot. Its quoted project path ends in `.` to avoid a trailing backslash escaping the closing quote on Windows. Launch errors stay visible. Run `scenes/preparation_flow.tscn` with F6 for the old mech loop.

## Verification — 2026-09-07

- Red: the three new Python contracts failed for the missing catalog/model/scene; Godot acceptance failed for the missing model before implementation.
- Green: `python -m unittest discover` — 65 tests passed, including default F5 entry and Windows path quoting.
- `godot --headless --path . -s res://tests/godot/battle_milestone_test.gd` — GODOT TESTS PASSED, including new equipment restrictions, previews without mutation, stat stacking, unique fairy transfer, local save round-trip, malformed save rejection and UI interaction checks.
- `python tools/gdscript_function_coverage.py --godot <Godot executable> --fail-under 80` — 420/435 functions, 96.6%.
- Existing Phase 2 evidence generator reproduced its committed report without a content diff.
- Rendered 1280×590 and 844×390 layouts using `tools/capture_fantasy_builder.gd`, with isolated in-memory builds. Evidence is under `docs/playtest/fantasy/`.
- Only the static screen is implemented. Ability descriptions and numbers are provisional preparation data, not functioning fantasy combat. Stat allocation remains deferred. Some gear variants share illustration layers; accessories have no body layer. Narrow screens use scrollable equipment, candidates and descriptions.
- Launch correction: new Python and Godot default-entry tests were red before the fix. `cmd /c launch-fantasy-builder.cmd --quit-after 8` then imported assets and ran the default scene successfully (exit 0). Visible editor and game windows were opened and verified responsive.

## Manual review

Run the standalone scene. Select Knight → Armor → Scout leathers and compare HP/DEF/Speed before equipping. Inspect the changed illustration. Select Healer → Fairy → Zephyr; read the transfer warning, then transfer and check Knight's empty fairy slot. Equip Bloom on Healer to inspect the full-HP healing buff concept. Use Build effects to see the combined job/equipment/fairy descriptions. Restart the scene to verify local persistence. Reset party restores defaults after confirmation.

Whether building is enjoyable and the character presentation suits the pivot remains the user's product judgment.
