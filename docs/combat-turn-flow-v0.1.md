# Combat Turn Flow v0.1

This document defines the required action-state behavior for the Phase 1 playable prototype.

## Core Rule
A unit gets exactly one activation when it reaches the front of the initiative timeline.

During that activation the unit may:

1. Move once, then Attack once, OR
2. Attack once without moving, OR
3. Move once, then Wait, OR
4. Wait immediately.

A unit may never move more than once during the same activation.
A unit may never attack more than once during the same activation unless a future explicit weapon/passive rule says otherwise.

## Required State Machine

Use an explicit turn-state enum/state machine. Do not infer state only from UI button visibility.

Recommended states:

- `TURN_START`
- `AWAITING_COMMAND`
- `SELECTING_MOVE`
- `MOVE_COMPLETE`
- `SELECTING_ATTACK`
- `ACTION_COMPLETE`
- `TURN_END`

Per-unit activation flags:

- `has_moved: bool`
- `has_attacked: bool`
- `activation_complete: bool`

These flags reset only when that unit begins a new activation from the initiative timeline.

## Turn Start

When a unit becomes active:

- Set `has_moved = false`
- Set `has_attacked = false`
- Set `activation_complete = false`
- Select/focus the active unit
- Refresh reachable tiles and valid commands
- Do not allow the player to control any other unit

## Move

Move is legal only when:

- Active unit belongs to player
- `has_moved == false`
- `activation_complete == false`

After a valid move resolves:

- Set `has_moved = true`
- Clear movement highlights
- Do NOT allow Move again during this activation
- Return to command state with only legal remaining actions

After moving, the player may normally:

- Attack
- Wait

The Move button must be disabled/hidden after movement is committed.

Tapping another reachable tile after movement is complete must NOT move the unit again.

## Attack

Attack is legal only when:

- Active unit belongs to player
- `has_attacked == false`
- `activation_complete == false`

For Phase 1, Attack may be chosen before or after Move.

After a valid attack resolves:

- Set `has_attacked = true`
- Set `activation_complete = true`
- Clear all command/target highlights
- End the unit activation immediately
- Advance the initiative timeline to the next unit

There is no second Move after Attack.
There is no second Attack after Attack.

## Wait

Wait is legal whenever the current activation is not complete.

When Wait is confirmed:

- Set `activation_complete = true`
- Clear highlights
- End activation immediately
- Advance initiative timeline

## Initiative Order

The initiative strip is functional state, not decorative UI.

Requirements:

- Only the unit currently at the front of the initiative timeline is controllable.
- After Attack or Wait completes an activation, advance to the next scheduled unit.
- Player cannot manually select another ally to take its turn early.
- Enemy activation is resolved when an enemy reaches the front.
- When the current unit finishes, schedule its next activation based on Speed.
- Faster units may eventually receive more activations over time, but never multiple simultaneous activations.

For the first implementation, use deterministic initiative math and expose the ordered upcoming list for debugging.

## UI Command Availability

At activation start:

- Move: enabled
- Attack: enabled if at least one valid target exists
- Wait: enabled

After Move:

- Move: disabled
- Attack: enabled if valid target exists
- Wait: enabled

After Attack:

- All commands disabled while the turn advances

After Wait:

- All commands disabled while the turn advances

## Selection Rules

- Tapping another allied unit while it is not their activation may show read-only information, but MUST NOT transfer control.
- Movement range belongs only to the active unit.
- Attack targeting belongs only to the active unit.

## Acceptance Tests

1. Start Arlen activation. Move Arlen once. Attempt to move again: rejected.
2. Move Arlen, then Attack: attack resolves and next initiative unit becomes active.
3. Attack without moving: next initiative unit becomes active immediately.
4. Move, then Wait: next initiative unit becomes active.
5. Wait without moving: next initiative unit becomes active.
6. Tap Mira during Arlen activation: Mira must not become controllable.
7. Finish a full initiative cycle: each unit acts only when scheduled.
8. When Arlen receives a future activation, `has_moved` and `has_attacked` reset for that new activation only.

## UX Principle

The player should always understand one question:

> What can the currently active unit still do this activation?

Never allow UI state and combat simulation state to disagree.