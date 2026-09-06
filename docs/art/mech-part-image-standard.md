# Modular mech part image standard

Every robot family uses one common Hangar coordinate system. Source images are exported at four pixels per Hangar design unit, so their pixel dimensions preserve the actual relative size of each part. Images do not share an arbitrary height.

| Part | Hangar box | Source canvas | Ratio |
|---|---:|---:|---:|
| Head | 75 × 80 | 300 × 320 px | 15:16 |
| Body | 180 × 192 | 720 × 768 px | 15:16 |
| Right Arm | 96 × 288 | 384 × 1152 px | 1:3 |
| Left Arm | 96 × 288 | 384 × 1152 px | 1:3 |
| Legs | 300 × 375 | 1200 × 1500 px | 4:5 |

The complete canvas is the coordinate frame. Do not tightly crop individual exports after composing them. Preserve the canvas dimensions and place the physical joint on the normalized anchor recorded in `mech-part-image-standard.json`. Right and left are anatomical: the right arm appears on the viewer's left.

Artists may work at 2× or 8× by scaling both dimensions uniformly. All modules in one production set should use the same pixel density. At 4×, one Hangar design unit equals four source pixels.

The Hangar enforces the 180 × 192 Body box and one set of assembly-space socket points for every robot family. Changing Body equipment therefore preserves the torso dimensions and the positions of the head, arms and legs while each texture retains its own aspect ratio. The Aegis part boxes follow the full standard. Existing PNGs authored before this specification should be exported onto these canvases rather than stretched.

## Execution / Dependency

- This standard depends on the #70 Hangar art library and its attachment-coordinate support.
- It can be used independently by art workers; applying it in code is parallel-limited with other edits to the Hangar manifest and assembly acceptance tests.
- Shared-file risk is limited to `assets/hangar/detailed/modules.json` and Hangar art tests.
- Apply future robot families by adding their module records with these box sizes and normalized attachment coordinates, then integrate through their dedicated work branch.
