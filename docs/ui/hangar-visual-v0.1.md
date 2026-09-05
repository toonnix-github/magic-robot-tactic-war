# Visual Hangar v0.1

Issue #58 replaces the form-like preparation screen with spatial mech editing. The normal preparation entry scene and authoritative build model are unchanged.

## Interaction

- Select a pilot from the header; the assembled mech and overall part stats remain visible on the left.
- Select Head, Body, Right Arm, Left Arm or Legs on the illustration. Arm labels use the mech's anatomical sides in a front view.
- Illustrated alternatives on the right show names, durability and which part is equipped.
- Selecting an alternative previews its silhouette and color without modifying the build. Numeric before/after values show every changed stat; signed differences and colors distinguish improvements from costs.
- Equip commits the candidate. Cancel, another part or another pilot dismisses it. Deployment is disabled while a preview is unresolved.
- Weapon, Shield and the selected part's Orb remain editable below the comparison. Both-arm weapon restrictions are visible. Colored Orb sockets sit on the visible armor of their installed part rather than at the selection-box edge.
- Weapon details show range, attack pattern, required arms, base damage and base hit. Orb details show always-on effects and status activation chances, including the pilot's proc bonus.
- Part-frame totals are separate from effective loadout values. Pilot effects remain a clearly labeled conditional line rather than being hidden in a total.
- Sword, Rifle, Spear, Sniper and Shield placeholders render on the assembled mech and update with the controls.
- Deploy opens a four-mech squad review. The player selects a mission, compares weapons and roles together, then either returns to editing or confirms deployment.

## Assets and Ownership

`assets/hangar/` contains 21 original graybox SVG illustrations: 16 modular part silhouettes plus four weapons and one Shield. Arms are mirrored for anatomical placement. Bulwark uses larger plates and treads, Longview has narrower precision components, Aegis uses balanced armor and Volt uses lightweight components. Guard and Sprinter reuse related family placeholders. These are identity aids, not final production art or new gameplay rules.

`src/ui/mech_assembly_view.gd` owns composition, illustration lookup and spatial selection. `hangar_editor.gd` owns candidate inspection, squad review and confirmation; authoritative profiles, modifiers, deltas and swaps remain in `MechBuildModel`.

## Verification

55 Python tests pass; Godot acceptance and 365/380 (96.1%) function coverage pass. Acceptance covers selection through the part button, nonmutating preview, numeric comparison, equipment explanations and visuals, effective-stat derivation, Cancel, Equip, mission-aware squad review, deployment gating and the existing battle-return flow. Rendered editor and review views at 1280x590 and 844x390 were inspected. The inspector scrolls vertically when the full comparison and equipment controls exceed its height; the mech stays visible.

Reproduce the current loadout and squad-review screenshots with `tools/render_hangar_evidence.gd`. This is automated developer verification; human usability feedback remains open.

![Visual Hangar](../playtest/hangar-visual-desktop.png)

![Part comparison on mobile landscape](../playtest/hangar-visual-preview.png)

![Equipment and effective stats](../playtest/hangar-loadout-1280x590.png)

![Four-mech squad review](../playtest/hangar-squad-review-844x390.png)
