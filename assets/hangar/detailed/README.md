# Hangar sample integration (#70)

The two original generated master images and background come from the user-requested art sample. No weapon art is added. Aegis/Bulwark catalog entries use these masters; other entries retain their SVG illustrations.

## Attachment contract

Both master images are 1254 x 1254. Preserve this canvas and the robot geometry when replacing the background with transparency. The background is 1672 x 941. Do not resize, recenter, rotate or repaint a module during transparency cleanup without updating its registration data.

`modules.json` contains source-pixel crop regions and anchors, design-space rectangles, and torso socket coordinates. Head anchors meet the neck; anatomical right and left arms meet their matching shoulder sockets; the lower assembly meets the waist. Head/arms/lower assembly positions are derived from the currently equipped torso, so swapping the torso also repositions its attached modules. Anatomy is from the robot's point of view (right arm appears on the viewer's left).

| Family | Neck | Right shoulder | Left shoulder | Waist |
|---|---|---|---|---|
| Aegis torso (source pixels) | 625,242 | 466,305 | 786,305 | 625,510 |
| Bulwark torso (source pixels) | 625,200 | 432,265 | 820,265 | 625,510 |

Per-part `anchor` values identify the matching point in that part's source image. Arms include the outer shoulder armor; the torso owns the central shoulder sockets. The lower assembly owns pelvis armor. Aegis has walking legs; Bulwark has treads.

## Rendering

AtlasTexture selects each module from its master. Authored SVG silhouettes and a canvas shader clip the baked backgrounds without changing the source pixels. These are provisional masks: transparency/edge cleanup is explicitly being handled by the user. Keep the silhouette masks after cleanup because they also exclude neighboring modules from a crop. This is a fixed front-view assembly, not a rig for animated joint rotation.

HangarArtLibrary owns image caching, materials and attachment placement. MechAssemblyView owns selection and arrangement. No combat or build calculation is added to either the art library or main.gd.

## Verification

The Godot milestone test checks all sixteen family/slot/torso attachment pairs against actual control positions, plus preview/Cancel/Equip, alpha exclusion between the legs and SVG fallback. Existing tests retain deployment, return, equipment and Orb coverage. `tools/render_hangar_art.gd` renders both full sets and a mixed preview at 1280x590 and 844x390. These are automated render checks, not human playtest sign-off.
