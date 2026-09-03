# Battle Screen UX/UI Reference v0.1

## Purpose
This is the visual source of truth for the first playable mobile-landscape battle prototype.

Visual reference: `docs/ui/battle-screen-v0.1.svg`

## Screen target
- Landscape mobile first.
- Design canvas follows a modern iPhone-wide ratio, approximately 19.6:9.
- The battlefield must dominate the screen.
- Standard battlefield: 7 rows x 10 columns.
- Do not show grid letters or numbers in the normal battle UI.

## Visual priorities
1. Terrain and unit positions are more important than HUD.
2. Height must be readable directly from stepped terrain geometry, not from permanent H0/H1/H2 labels.
3. Reachable movement tiles use a subtle overlay rather than a large modal.
4. Keep persistent HUD minimal.

## Persistent HUD
### Top left — selected unit
Show only:
- Pilot name
- Mech name
- Current weapon
- One overall HP indication

Do not show full numeric part values here.

### Top center — initiative
Compact strip showing only the next few actors.

### Top right — mission
Show:
- Current turn
- One-line mission objective

Avoid secondary mission text unless currently relevant.

### Bottom right — actions
Phase 1 has only:
- Move
- Attack
- Wait

Do not add Orb active-skill buttons. Orbs are passive/proc based.

### Bottom left — part status
Only show while a unit is selected. Use compact bars for:
- Head
- Body
- Left Arm
- Right Arm
- Legs

This panel should be collapsible later if playtesting shows it is unnecessary.

## Battlefield behavior
- 7x10 grid is visible but subdued.
- No permanent coordinates, row letters, column numbers, or debug text in player UI.
- Terrain elevation is communicated through visible stepped geometry.
- Orthogonally adjacent traversable tiles may differ by at most one elevation level.
- Cover must read as a physical object, not just a percentage icon.
- Selection and movement overlays must remain readable across all heights.

## Interaction
- Tap unit to select.
- Reachable tiles appear immediately.
- Tap a reachable tile to move.
- Attack mode highlights valid targets/range.
- Tap empty battlefield space or the selected unit to cancel targeting.
- All essential interactions must work with touch and cannot depend on hover.

## Information hierarchy
Normal battle state should prioritize:
1. Battlefield
2. Active/selected unit
3. Immediate action choices
4. Turn order
5. Mission objective
6. Detailed part state

Detailed formulas, Orb proc rates, exact damage formulas, RNG rolls, and other implementation/debug information belong in debug UI, not the normal battle HUD.

## Phase 1 non-goals
Do not add:
- minimap
- virtual joystick
- permanent grid coordinates
- large skill bars
- inventory shortcuts
- town/progression controls
- gacha/monetization UI
- decorative HUD elements that reduce battlefield space

## Codex implementation note
Treat the SVG as a composition and hierarchy reference, not pixel-perfect final art. The first Godot implementation may use simple panels, shapes, and placeholder circles, but preserve:
- battlefield dominance
- compact HUD
- 7x10 readability
- wide mobile ratio
- only Move / Attack / Wait
- readable elevation

When the code and this UX reference conflict only in presentation, prefer this UX reference. Combat behavior remains governed by `docs/combat-rulebook.md`.
