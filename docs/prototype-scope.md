# Phase 1 Prototype Scope

Historical Phase 1 baseline. Current preparation and HUD scope is defined in [Phase 2 scope](phase2-scope.md); its explicit extensions supersede the battle-only UI restriction below.

## Goal
Prove that the core combat loop is fun on a mobile landscape screen before building progression, town, story or monetization systems.

Core loop under test:
`Prepare -> Battle -> Result -> Retry with different build`

## Acceptance Question
After playing the same prototype battle around 10 times with different builds, does the player still want an 11th run?

## In Scope
### Battlefield
- 7x10 square grid
- 4-direction movement
- elevation H0-H4
- simple cover
- terrain/wall line-of-sight blocking
- mobile landscape camera/UI

### Units
Four player prototype pilots/mechs:
- Arlen: melee/part-damage passive identity
- Mira: accuracy/sniper identity
- Sera: elemental-proc identity
- Brann: shield/repair identity

Enemy roster only needs enough archetypes to test the systems:
- melee blade
- spear
- rifle
- sniper
- shield guard
- commander/objective target

### Mech Parts
- Head
- Body
- Left Arm
- Right Arm
- Legs
- independent HP and destruction effects
- one Orb slot per part

### Weapons
Exactly these five weapon identities first:
1. Sword
2. Spear
3. Rifle
4. Sniper
5. Shield

Do not add axe, cannon, dual guns, staff, bows, launchers or other weapons until Phase 1 tests justify them.

### Orbs
Elements:
- Fire
- Water
- Lightning
- Earth

Create only enough sample Orbs to prove rarity and build diversity, e.g. N/SR/SSR examples. Orbs are passive/proc-based only.

### Prototype Maps
Implement these three missions first.

#### 1. Ancient Ruins
Purpose: baseline combat test.
- Standard mixed terrain
- 4 player units vs ~5 enemies
- objective: defeat commander
- tests movement, part damage, shield, melee/ranged and initiative

#### 2. Crystal Quarry
Purpose: farm/auto test.
- simple open routes
- small H0-H1 elevation variation
- ~4 enemies
- objective: defeat enemies
- target duration: 3-5 minutes
- rewards auto-collected; no pickup interaction

#### 3. Ascending Ridge
Purpose: height stress test.
- one side starts near H0, opposite side near H4
- every adjacent walkable elevation changes at most 1 level
- use ridges/valleys rather than a perfectly uniform staircase where practical
- objective: defeat commander
- tests universal +/-5% Hit per level capped at +/-15%

## UI Scope
Battle HUD only.

Required:
- current/next initiative units
- selected unit
- movement highlight
- target highlight
- Move / Attack / Wait
- attack preview with Hit %, weapon pattern and key target status
- visible destroyed/disabled part status
- concise Orb proc feedback
- mission objective

Not required:
- town screen
- inventory management UI
- gacha screens
- story dialogue system
- character relationship UI
- polished mech customization screen

## Auto Simulation
Provide a deterministic debug/auto mode so the team can run battles rapidly and inspect:
- actions to mission completion
- part destruction events
- Orb procs
- damage received
- wasted turns
- movement congestion

## Balance Targets
These are targets, not fixed laws:
- normal story/prototype battle: 5-10 minutes
- farm battle: 3-5 minutes
- player units: normally 4
- standard opening should reach meaningful combat quickly
- normal main routes should be >=2 tiles wide
- no single weapon should dominate damage, disable, safety and range simultaneously

## Explicitly Out of Scope
- town/base development
- crafting economy
- pilot recruitment/collection
- full mech inventory progression
- story campaign
- relationship system
- PvP
- co-op
- multiplayer
- monetization/gacha implementation
- live events
- polished final art
- cinematic animation
- large content roster
- more elements beyond the initial four

## Phase 1 Exit Criteria
Phase 1 is complete when:
1. all three prototype maps are playable end-to-end;
2. the five weapon types have visibly different tactical roles;
3. part destruction changes combat capability correctly;
4. Shield interception works and breaks correctly mid-volley;
5. Orb passives/procs work and disable when their part is destroyed;
6. elevation changes Hit chance as specified;
7. two different player builds produce meaningfully different battle behavior;
8. auto results improve when the team is better prepared;
9. there are no common wasted turns caused by allied movement congestion;
10. the team has enough playtest evidence to decide whether the core combat deserves Phase 2.
