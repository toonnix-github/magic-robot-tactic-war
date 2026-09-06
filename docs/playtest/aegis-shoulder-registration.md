# Aegis shoulder registration (#70)

The separate Aegis arm images now connect to the visible torso shoulder sockets. Their previous atlas coordinates produced a roughly 33-pixel gap in the 600 x 650 assembly coordinate space. The corrected placement moves the right arm approximately 18 pixels inward and 28 pixels upward, and the left arm 16 pixels inward and 29 pixels upward.

`image_anchor` and `image_sockets` in `assets/hangar/detailed/modules.json` are normalized coordinates on the complete standalone PNGs. The UI art library includes centered aspect-fit padding when mapping these points into the assembly. If an artist changes the image crop, these image coordinates must be recalibrated. Existing atlas coordinates remain available for fallback and other part combinations.

Only Aegis arms on the Aegis torso use this correction. Head, legs, Bulwark and mixed-family placement keep their existing calculation. The current cropped Aegis arm PNGs are included as runtime assets so the fix also works without the local output directory. The existing standalone image loader and aspect-preserving button rendering are included as prerequisites.

## Validation

- Python metadata test and Godot rendered-joint checks failed before implementation; the Godot checks measured 33.45/33.06-pixel shoulder gaps at design size.
- Corrected visible joints align within 0.5 pixels at 600 x 650, 446 x 497 and 280 x 300 assembly sizes.
- Full Python regression: 61 tests passed. Full Godot milestone acceptance passed.
- Staged files were validated in a clean temporary checkout without local output assets: 61 Python tests passed and full Godot acceptance passed under coverage; 387/402 GDScript functions covered (96.3%).
- Rendered Hangar checked at desktop and mobile landscape sizes.

## Execution / Dependency

- Follow-up to #70 / PR #71; depends on the Hangar art library and the user's separate Aegis PNGs.
- Independent of combat, build data and weapon work; parallel-limited with other art-library or assembly-view edits.
- Read-only joint calibration/review ran in parallel. All implementation remains on one dedicated fix branch.
- Shared-file risk: the art manifest, UI art library and Hangar acceptance tests. No simulation or main-scene implementation changes.
- Integrate through a PR to `phase2/build-your-mech` after regression passes; PR #71 is the preceding art integration.
