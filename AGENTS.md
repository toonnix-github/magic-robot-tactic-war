# AGENTS.md

## Project
Magic Robot Tactic War is a mobile-first landscape tactical RPG combining modular mechs, pilots, elemental Orbs, part-based damage, and short grid battles.

## Current Goal
Build ONLY the Phase 1 graybox combat prototype. Do not add town building, story systems, gacha, crafting, account systems, multiplayer, monetization, polished art, or live-service features.

## Technology
- Engine: Godot 4.x
- Language: GDScript
- Target: mobile landscape first; desktop is acceptable for development/testing.
- Standard battle map: 7 rows x 10 columns.
- Prefer data-driven definitions for maps, weapons, units, Orbs, and missions.

## Design Source of Truth
Read these before implementing or changing combat behavior or battle presentation:
1. `docs/combat-rulebook.md`
2. `docs/combat-turn-flow-v0.1.md`
3. `docs/prototype-scope.md`
4. `docs/ui/battle-screen-v0.1.md`
5. `docs/ui/battle-screen-v0.1.svg`

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
The Phase 1 battle composition must follow `docs/ui/battle-screen-v0.1.svg` and its companion Markdown guidance.

Key constraints:
- mobile landscape, approximately modern iPhone-wide ratio
- battlefield visually dominates the screen
- 7x10 grid is readable without permanent row/column labels
- terrain elevation is shown through stepped geometry rather than H0/H1/H2 text in normal player UI
- compact selected-unit panel at top left
- compact initiative strip near top center
- compact mission/turn panel at top right
- part status is contextual rather than a permanent stat wall
- primary action bar contains only Move / Attack / Wait in Phase 1
- no minimap, virtual joystick, giant skill bar, or decorative HUD that steals battlefield space

Treat the SVG as a hierarchy/composition reference rather than final art. Graybox shapes and placeholder unit markers are expected during Phase 1.

## Phase 1 UX
Keep the battle UI minimal:
- Select unit
- Move
- Attack
- Wait
- Basic target preview: Hit %, weapon pattern, target part status
- Orb effects are passive/proc-based; no Orb active-skill buttons.

## Engineering Principles
- Separate simulation state from presentation/animation.
- Combat rules must be testable without rendering.
- Use deterministic RNG seeds in automated tests and debug simulations.
- Prefer small composable systems over large scene scripts.
- Avoid hard-coding map-specific logic into core combat systems.
- Keep all balance numbers easy to edit in data files/resources.

## Suggested Structure
- `src/combat/` simulation, actions, initiative, damage, targeting
- `src/grid/` coordinates, movement, height, line of sight
- `src/data/` resource/data definitions and loaders
- `src/ui/` battle HUD and input
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

## Scope Guardrail
If a requested feature is not required to prove that the core loop is fun, record it as a future idea instead of implementing it in Phase 1.
