# Phase 1 Closure Roadmap

Phase 1 core combat implementation is complete through issue #16 and the regression workflow is green. The remaining work is focused on battle readability, deliberate player decision-making, completing the Orb/Pilot identity, and collecting enough playtest evidence to make a Go/Iterate decision before Phase 2.

## Execution Order

Work these issues in order unless the user explicitly changes priority:

1. **#18 — Enemy movement presentation and activation readability**
   - Make enemy turns visible instead of teleporting simulation state.

2. **#19 — Combat attack presentation, damage feedback and part-hit readability**
   - Show attacker, target, hit/miss, damage amount, affected part, Shield interception and destruction consequences.

3. **#20 — Attack range overlay and target legality explanation**
   - Show the weapon's attackable area, legal targets and reasons for invalid targets.

4. **#21 — Movement preview with confirm and cancel**
   - Destination selection becomes preview-only until the player explicitly confirms movement.

5. **#22 — Enemy inspection panel during target selection**
   - Let the player compare target part HP, weapon, status, terrain and attack preview before committing.

6. **#23 — Numeric HP values on mech parts and Shield**
   - Add current/max values to the existing HP bars.

7. **#24 — Default Orb loadouts, visible proc feedback and one real status effect**
   - Make Orb gameplay observable during normal battles; implement one real deterministic status effect such as Burn.

8. **#25 — Pilot passive identities**
   - Arlen, Mira, Sera and Brann gain data-driven passive identities only; no active pilot buttons.

9. **#26 — Spear part-weighting correction and weapon-data validation**
   - Remove guaranteed Body targeting and validate weapon part-weight data.

10. **#27 — Mission selector, Auto toggle and Phase 1 debug controls**
    - Human playtesters can launch all required scenarios without changing code.

11. **#28 — Phase 1 build-quality Auto benchmark and replay evidence**
    - Compare sensible vs mismatched builds using identical seeds and enemy setup.

12. **#29 — Phase 1 closure: UX stabilization, regression and playtest sign-off**
    - Final technical + human playtest gate; document `GO to Phase 2` or `ITERATE Phase 1`.

## Priority Principle

The immediate problem is not missing combat rules. The game now needs to clearly communicate what happened and give the player enough information and confirmation to make tactical decisions.

The desired battle experience is:

`Observe -> Inspect -> Plan -> Preview -> Confirm -> Resolve -> Understand outcome`

Do not collapse this into instant state changes during normal manual play.

## Presentation vs Simulation

- Simulation remains authoritative and deterministic.
- Animation/presentation must never change legal actions, RNG outcomes, damage values or initiative order.
- Normal manual play presents movement and attacks in a readable sequence.
- Debug/fast Auto simulation may skip presentation entirely.
- Player input that could mutate combat state must be blocked while enemy/action presentation is resolving.

## Phase 1 Scope Guardrail

Do not add:
- town/base systems
- crafting economy
- gacha/recruitment
- story campaign
- account progression
- multiplayer
- polished final art
- new weapon families
- new elemental systems beyond what is needed to prove the existing Orb design

Phase 1 ends only when the core combat is both technically stable and understandable enough for repeated human playtesting.