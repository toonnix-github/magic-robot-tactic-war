# Phase 1 Ticket Roadmap

This file defines the required execution order for the Phase 1 playable combat prototype.

## Working rule for Codex
Work on one ticket at a time, in the order below. Do not skip dependencies or implement future-ticket scope early unless a tiny shared abstraction is strictly required for the current ticket.

For every ticket:
1. Read `AGENTS.md`, the ticket body, and all referenced design docs first.
2. Implement only the ticket scope.
3. Add or update deterministic tests for the ticket acceptance criteria.
4. Run the Godot project/tests and fix regressions.
5. Commit with the issue number in the commit message.
6. Push to `prototype/combat-v01`.
7. Only then continue to the next ticket.

If a ticket exposes a design conflict, preserve the current source-of-truth docs and record the conflict instead of silently inventing a new game rule.

## Ordered tickets

### #2 — P1-02: Initiative turn ownership and activation flow
Lock active-unit ownership, Move/Attack/Wait consumption and deterministic initiative progression.

### #3 — P1-03: Basic attack targeting and resolution pipeline
Create the reusable target-selection, preview, resolve and activation-ending attack flow.

### #4 — P1-04: Mech part HP and destruction consequences
Add Head, Body, Left Arm, Right Arm and Legs HP plus destruction consequences and Orb disable hooks.

### #5 — P1-05: Sword weapon — concentrated single-part burst
Implement range-1 single-hit concentrated part damage.

### #6 — P1-06: Spear weapon — two-tile line attack
Implement straight-line two-tile formation punishment with reduced second-tile damage.

### #7 — P1-07: Rifle weapon — multi-hit distributed part damage
Implement configurable multi-shot volleys with independent hit and part rolls.

### #8 — P1-08: Sniper weapon — precision disable with low Body weight
Implement long-range single-shot precision targeting with 10% Body weight.

### #9 — P1-09: Shield equipment — interception and shield HP
Implement shield HP, adjacent-ally interception, and mid-volley shield break behavior.

### #10 — P1-10: Terrain height, cover, LOS and hit modifiers
Implement H0-H4 traversal, +/-5% Hit per level capped at +/-15%, simple cover and terrain LOS.

### #11 — P1-11: Orb framework — element, rarity, passives and proc effects
Implement one Orb per mech part, N/R/SR/SSR rarity, passive/proc effects, and 4-5-effect SSR support without active Orb buttons.

### #12 — P1-12: Enemy AI and deterministic Auto battle
Run player/enemy teams through the same legal combat rules and support deterministic Auto simulation.

### #13 — P1-13: Ancient Ruins — standard combat mission
Create the normal-battle benchmark with commander objective and balanced terrain.

### #14 — P1-14: Crystal Quarry — short farm mission with automatic loot
Create a short Auto-friendly farm stage. Rewards are automatic after victory; no battlefield pickup interaction.

### #15 — P1-15: Ascending Ridge — H0 to H4 slope stress-test mission
Create the high-vs-low terrain benchmark with natural stepwise elevation and uphill/downhill comparison.

### #16 — P1-16: Phase 1 stabilization, battle UX, debug tools and replay test
Finish battle readability, deterministic logs/tests, replay comparisons and the Phase 1 Go/Iterate evaluation.

## Phase 1 scope boundary
Do not add these before Phase 1 is accepted:
- town/base building
- story campaign systems
- gacha
- crafting
- account progression
- monetization
- multiplayer
- polished final art

The purpose of Phase 1 is to prove the core loop:

`Prepare -> Battle -> Result -> Retry with a different build`

The product question remains: after repeated runs, is the combat and build interaction interesting enough to want another run?
