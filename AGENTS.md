# AGENTS.md

## Project
Magic Robot Tactic War is a mobile-first landscape tactical RPG combining modular mechs, pilots, elemental Orbs, part-based damage, and short grid battles.

## Current Goal
Build ONLY the Phase 1 graybox combat prototype and its final readability/presentation fixes. Do not add town building, story systems, gacha, crafting, account systems, multiplayer, monetization, polished art, or live-service features.

Phase 1 core combat implementation and closure through issue #29 are complete. The current focus is final Phase 1 presentation polish: issues #30 and #31.

## Technology
- Engine: Godot 4.x
- Language: GDScript
- Target: mobile landscape first; desktop is acceptable for development/testing.
- Standard battle map: 7 rows x 10 columns.
- Prefer data-driven definitions for maps, weapons, units, Orbs, and missions.

## Ticket Execution and Parallel Work
`docs/phase1-closure-roadmap.md` remains the historical Phase 1 closure roadmap. Current post-closure fixes are tracked directly by issue.

Every new implementation ticket must include an **Execution / Dependency** section that explicitly states:
- functional dependencies on other tickets, if any;
- whether the ticket can be developed independently;
- whether it is safe for a separate sub-agent / AI worker to implement in parallel;
- expected shared-file or merge-conflict risk;
- any integration step that must happen after another ticket lands.

Independent tickets do NOT need to be artificially serialized. They may be developed in parallel when both are true:
1. there is no functional dependency; and
2. they are unlikely to make overlapping edits to the same monolithic files or shared state.

If tickets are functionally independent but both substantially modify the same file, mark them as **parallel-limited** rather than fully parallel-safe. Do not hide merge-risk from the user.

For each ticket:
1. Read this file, the ticket body, relevant roadmap/design docs, and referenced tickets before coding.
2. Implement only the current ticket scope. Do not pull unrelated future gameplay into the change unless a tiny shared abstraction is strictly necessary.
3. **MANDATORY TDD:** You MUST use strict Test-Driven Development (Red-Green-Refactor). Write the failing Python static tests and Godot acceptance tests FIRST, run them to verify they fail, and ONLY THEN write the implementation code to make them pass.
4. Run the Godot project/tests and fix regressions.
5. Ensure the GitHub Regression workflow remains green.
6. Commit with the issue number in the commit message.
7. Push completed work only to the ticket's dedicated work branch.
8. Open a Pull Request back to the current phase/integration branch; do not integrate by direct push.
9. Do not silently invent a new game rule when requirements conflict; preserve the source-of-truth design and surface the conflict.
10. When working in parallel, keep changes narrowly scoped and avoid opportunistic refactors that increase merge conflicts.

## Mandatory Git Workflow
`docs/git-workflow.md` is mandatory for all coding, test, refactor, tooling, and significant documentation work.

Rules:
- Never develop directly on `main`, `prototype/combat-v01`, or any future shared phase/integration branch.
- Every ticket / coherent task gets its own short-lived branch before editing begins.
- Use branch names such as `feature/<issue>-<name>`, `fix/<issue>-<name>`, `refactor/<issue>-<name>`, or `test/<issue>-<name>`.
- One branch should normally correspond to one issue or one tightly scoped change.
- Parallel AI/sub-agent workers must use separate branches. Two workers must not share the same mutable feature branch.
- PRs target the current phase/integration branch, not automatically `main`.
- Required regression/CI must be green before merge.
- Resolve conflicts on the work branch and re-run CI before merging.
- Never force-push a shared integration branch.
- After integrating parallel branches, run the full regression suite again on the integration branch.
- Large refactors must be isolated from gameplay feature changes whenever practical.

Direct push to a shared branch is allowed only when the user explicitly requests a named emergency direct fix. An AI must never infer this exception on its own.

## Design Source of Truth
Read these before implementing or changing combat behavior or battle presentation:
1. `docs/combat-rulebook.md`
2. `docs/combat-turn-flow-v0.1.md`
3. `docs/prototype-scope.md`
4. `docs/ui/battle-screen-v0.1.md`
5. `docs/ui/battle-screen-v0.1.svg`
6. `docs/phase1-ticket-roadmap.md` for historical core implementation order
7. `docs/phase1-closure-roadmap.md` for historical closure work
8. `docs/git-workflow.md` for mandatory branch/PR integration rules
9. Current open GitHub issues for post-closure changes

If implementation conflicts with those files, the docs win unless they are intentionally updated in the same change.

## Turn Flow Source of Truth
`docs/combat-turn-flow-v0.1.md` is mandatory for Phase 1 turn behavior.

Key rules:
- only the unit currently at the front of initiative is controllable
- one activation allows Move once + Attack once, Attack only, Move once + Wait, or Wait
- after a committed Move, Move cannot be used again until that unit receives a future activation
- Attack ends the activation immediately
- Wait ends the activation immediately
- selecting another ally never transfers control outside initiative order
- turn/action legality must be enforced in simulation state, not only by hiding/disabling UI buttons

## UX Source of Truth
The Phase 1 battle composition must follow `docs/ui/battle-screen-v0.1.svg` and its companion Markdown guidance, plus the active presentation issues.

Key constraints:
- mobile landscape, approximately modern iPhone-wide ratio
- battlefield visually dominates the screen
- 7x10 grid is readable without permanent row/column labels
- terrain elevation is shown through stepped geometry rather than H0/H1/H2 text in normal player UI
- primary action bar contains only Move / Attack / Wait in Phase 1
- no minimap, virtual joystick, giant skill bar, or decorative HUD that steals battlefield space
- normal manual play must visibly present enemy movement and attack outcomes instead of teleporting state
- movement destination selection must support preview + explicit Confirm/Cancel before consuming Move
- Attack mode must visualize the weapon's attack area and legal/illegal targeting reasons
- target inspection must expose enough enemy detail for deliberate tactical choice
- visible HP bars must include numeric current/max values where required
- Auto Battle means AI-controlled visible play; Fast Simulation is the explicit presentation-skipping mode
- attack impact feedback should communicate hit/miss, damage, affected part, destruction and triggered effects without requiring debug logs

Treat the SVG as a hierarchy/composition reference rather than final art. Graybox shapes and placeholder unit markers are expected during Phase 1.

## Phase 1 Interaction Model
Keep the primary battle commands minimal:
- Move
- Attack
- Wait

But the decision flow should be readable and deliberate:
`Observe -> Inspect -> Plan -> Preview -> Confirm -> Resolve -> Understand outcome`

Supporting inspection, preview, confirmation and combat feedback are not additional combat actions and must not create extra initiative opportunities.

## Presentation vs Simulation
- Separate simulation state from presentation/animation.
- Simulation is authoritative and deterministic.
- Presentation timing must never alter RNG, legal actions, damage values or initiative order.
- Normal manual play presents movement and attacks in a readable sequence before advancing.
- Auto Battle with Fast Simulation OFF also presents movement and attacks visibly.
- Fast Simulation may skip presentation for benchmarks/debugging.
- Block state-changing player input while enemy/action/Auto presentation is resolving.

## Engineering Principles
- Combat rules must be testable without rendering.
- Use deterministic RNG seeds in automated tests and debug simulations.
- Prefer small composable systems over large scene scripts.
- Avoid hard-coding map-specific logic into core combat systems.
- Keep all balance numbers easy to edit in data files/resources.
- Reduce shared-file contention before scaling parallel AI development.

## Suggested Structure
- `src/combat/` simulation, actions, initiative, damage, targeting
- `src/grid/` coordinates, movement, height, line of sight
- `src/data/` resource/data definitions and loaders
- `src/ui/` battle HUD and input
- `src/presentation/` movement playback, attack feedback, floating combat text, event feed
- `scenes/` Godot scenes
- `data/maps/`, `data/weapons/`, `data/orbs/`, `data/units/`
- `tests/` deterministic combat tests

## Prototype Acceptance Tests
Before Phase 1 is considered complete, the game should support:
- 7x10 battle map with H0-H4 elevation
- 4-direction movement
- allies can move through allies but cannot end on the same tile
- enemies cannot move through opponents
- unit bodies do not normally block ranged line of sight
- initiative timeline based on Speed; sufficiently fast units can act more often
- Head, Body, Left Arm, Right Arm, Legs HP
- part destruction consequences
- Sword, Spear, Rifle, Sniper, Shield
- passive/proc Orb effects
- simple cover and height accuracy modifiers
- at least 3 playable prototype missions
- deterministic auto-battle simulation for testing
- visible enemy movement and attack resolution
- visible Auto battle playback when Fast Simulation is OFF
- attack range visualization and targeting explanation
- movement preview + confirmation
- enemy inspection for target decisions
- numeric part/Shield HP values
- default Orb loadouts and at least one real status effect
- data-driven pilot passives
- concise impact feedback / floating damage / triggered-effect event text
- benchmark evidence that preparation/build quality matters in Auto
- green regression workflow at Phase 1 head

## Scope Guardrail
If a requested feature is not required to prove that the core loop is fun, record it as a future idea instead of implementing it in Phase 1.
