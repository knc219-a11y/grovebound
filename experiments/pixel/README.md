# Dark pixel boar study

Open `review.tscn` and run the current scene in Godot4.7. This is a visual walking study, not the full combat game.

Pipeline: generated three-part artwork → connected body plus independent whole-leg IK → fixed96x72 transparent SubViewport →16-color nearest palette shader →8 walking cells and1 idle sprite → review stage.

Rebuild sprites: run `export.tscn` with a graphics display, then let Godot import the outputPNG files before running review. Shared ground anchor(48,62), visible height48px, cycle0.85s, stride14.4source pixels. Source parts remain unchanged; exported sprite pixels are rendered by Godot. Existing2D skeleton remains the motion basis.

Verified: eight distinct frames, upper35rows stable across cycle, binary transparency, at most16colors, no border clipping. Bone controls are inherited from `animation/boar_cutout.gd`; that file exposes reusable UV-cache rebuild and configurable body bob.

Limitations: motion is sampled from a2D cutout rig; hand-authored pose cleanup and in-combat readability review remain. Main game now uses the baked PNG files through `animation/boar_pixel.gd`. Other characters retain their previous art. The backdrop is a static generated plate, not a reusable tile set.
