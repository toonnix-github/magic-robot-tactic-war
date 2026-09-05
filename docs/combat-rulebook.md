# Combat Rulebook v0.1

Status: Phase 1 prototype source of truth.

These combat rules remain the Phase 2 baseline. See [Phase 2 scope](phase2-scope.md) for build preparation, weapon handedness and Shield-as-off-hand clarification.

## Core Battle Pillars
- Mobile-first landscape tactical RPG.
- Standard battlefield: 7x10 square grid.
- Target battle duration: ~5-10 minutes.
- Typical player deployment: 4 units.
- Depth should come from preparation, positioning, part damage, weapon patterns, terrain and Orb interactions—not from large menus.

## Unit Model
A combat unit is `Pilot + Mech`.

Pilot:
- Provides passive effects only in Phase 1.
- No pilot active-skill menu.

Mech parts:
- Head
- Body
- Left Arm
- Right Arm
- Legs

Each mech part has its own HP and can hold at most one Orb.

## Part Destruction
- Body reaches 0 HP: mech is defeated; pilot ejects; unit leaves normal combat.
- Head reaches 0 HP: Accuracy is reduced significantly.
- Left/Right Arm reaches 0 HP: weapon associated with that arm becomes unusable; Orb installed in that part is disabled.
- Legs reaches 0 HP: Move becomes 0 and Dodge becomes 0; the mech may still attack/counter/use effects that do not require movement.
- Any destroyed part disables the Orb installed in that part.
- Destroyed parts may be restored in battle by expensive repair effects; this should be rare enough that part destruction remains meaningful.
- No permanent pilot death in the base game.

## Turn and Initiative
- Units act individually on an initiative timeline based on Speed.
- Speed is not only ordering: sufficiently fast units may receive turns more frequently than slow units.
- Exact timing formula remains a prototype balance parameter.
- Normal turn economy: Move + 1 Action.
- Phase 1 actions: Attack or Wait. Repair may be represented as a special/support action where needed for testing.

## Movement
- 4-directional movement only; no diagonal movement.
- Base movement target: 3 tiles, modified by leg equipment/stats rather than fixed mech classes.
- There are no Light/Medium/Heavy mech classes in the core rule set.
- Allied units may be moved through but a unit cannot end movement on an occupied tile.
- Opposing units block movement and cannot be moved through.
- Standard combat routes should generally be at least 2 tiles wide. One-tile routes are reserved for deliberate mission gimmicks.

## Terrain and Height
- Terrain may range from H0 upward; prototype includes up to H4.
- Adjacent walkable terrain differs by at most one height level; no arbitrary vertical jumps.
- Moving up/down one height level costs normal movement in v0.1.
- Height modifies Accuracy only as a universal rule:
  - +5% Hit per height level above target, max +15%.
  - -5% Hit per height level below target, max -15%.
- Height does NOT universally add damage, range, defense or dodge.
- Additional height benefits may later come from weapons, pilots, parts or Orbs.

## Cover
Simple cover only; no XCOM-style half/full cover taxonomy in Phase 1.

Prototype effect:
- +10% Dodge
- -10% incoming damage

Terrain/walls/obstacles are the primary line-of-sight blockers.
Normal units do not block ranged line of sight.

## Facing
- No full front/side/rear simulation.
- Back attacks may receive tactical bonuses such as higher Hit or Crit.
- Exact values remain prototype balance parameters.

## Accuracy and RNG
Hit chance is affected by:
- attacker Accuracy
- defender Evasion/Dodge
- position/back attack
- weapon range behavior
- height
- cover
- part damage/status/passives

Critical hits exist.

RNG systems in the combat model include:
- hit/miss
- random hit part according to weapon targeting profile
- critical hit
- Orb proc

Use deterministic seeded RNG for tests and simulations.

## Weapon Identity
Weapons should change the way combat is played, not merely increase ATK.

### Sword
- Range: 1.
- One heavy hit.
- Concentrated damage to one randomly selected valid mech part.
- Primary role: finisher / single-part burst.

### Spear
- Attacks the first two tiles directly in front of the attacker.
- Tile 1 target: 100% normal damage.
- Tile 2 target: prototype target 75% damage.
- May hit enemies occupying both tiles in one attack.
- Primary role: formation punishment / lane control.

### Rifle
- Mid-range; exact range varies by weapon.
- Multi-hit attack, typically 3-5 hits.
- Each successful hit may independently land on different mech parts.
- Primary role: reliable distributed part damage.

### Sniper
- Long range; prototype range 4-6.
- Minimum range: 2.
- One precision hit; missing wastes the attack.
- Primary role: disable important parts, not kill Body directly.
- Prototype part weighting:
  - Head 30%
  - Body 10%
  - Left Arm 20%
  - Right Arm 20%
  - Legs 20%
- Damage should not exceed Sword as a general rule.

### Shield
A shield is equipment with its own HP.

When the shield wielder is directly attacked by a blockable attack:
- hits are weighted toward the shield rather than normal mech parts;
- prototype shield hit weight: ~55%; remaining hits use normal part targeting;
- this is intentionally not 100%, so normal parts can still be damaged before the shield breaks.

Shield Guard / Intercept:
- a shield-equipped mech may protect an adjacent ally when positioned between attacker and ally in the protected direction;
- a blockable ranged attack targeting that protected ally is redirected to the shield mech;
- intercepted hits go to the Shield first;
- if a multi-hit volley breaks the Shield mid-volley, remaining hits continue to the original target;
- once Shield HP reaches 0, interception is disabled.

Shield identity: formation anchor / protection, not merely +DEF.

## Magic and Orbs
There is no Staff or dedicated magic weapon in the current design.

Magic belongs to the mech through Orbs.

Orb rules:
- one Orb maximum per mech part;
- Orbs have an Element;
- Orbs provide passive modifiers and/or chance-based proc effects;
- Orbs do not provide manually activated battle skills in the current design;
- example passive: Fire Damage +10%;
- example proc: chance to Burn or trigger an automatic elemental effect;
- if the part holding an Orb is destroyed, that Orb stops functioning immediately.

Orb rarity prototype:
- N: ~1 effect
- R: ~2 effects
- SR: ~3 effects
- SSR: ~4-5 simultaneous passive/proc effects

Higher rarity should enable richer synergy, not merely invalidate every lower-rarity Orb through larger numbers.

Initial elements for Phase 1:
- Fire
- Water
- Lightning
- Earth

Initial elemental model:
- elemental advantage/disadvantage
- elemental status effects

Terrain-reaction systems may be explored later but are not required for Phase 1.

## Friendly Fire
- No friendly fire in the base prototype.

## Counterattacks
- Counterattack is not universal.
- It must come from a pilot passive/build/equipment rule where explicitly defined.

## Mission Rules
Win/loss conditions depend on the mission.
Examples:
- defeat commander
- destroy target/beacon
- defeat all enemies
- reach/extract/protect objectives later

A mission ends immediately when its primary success condition is satisfied unless explicitly designed otherwise.

## Farm Missions
- Designed for ~3-5 minute sessions.
- Auto-friendly.
- No manual resource pickup on map.
- Rewards are granted automatically after mission completion.
- Avoid unnecessary gimmicks and long approach phases.

## Auto Battle Philosophy
Auto-battle should test preparation.

Auto quality should strongly reflect:
- pilot passives
- mech parts
- weapons
- Orb configuration
- team composition
- deployment/formation

A well-built team should auto more reliably than a poorly built team. Manual play should retain an advantage in complex tactical situations.

## Battle Design Principle
`Build first, command second.`

The game should reward:
1. building the right mech;
2. building a complementary team;
3. tactical positioning and timing during battle.
