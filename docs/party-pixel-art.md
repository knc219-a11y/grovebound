# Party pixel art

Six new static sprites (druid, marten, fox, tortoise, deer, wolf) share a muted 32-color palette with the existing dark quarter-view scene. Native heights: 72, 32, 40, 32, 64, 48 px. Boar retains its existing walk frames. Other creatures currently translate with static silhouettes, with no whole-image walk shake. Combat, hit feedback and downed poses remain.

Sources were generated as isolated right-facing elevated side-view characters with transparent backgrounds, chunky clusters, earthy colors and natural early-tier anatomy. Druid: moss cloak and wooden staff; marten: cream throat and long tail; fox: rust coat and cream tail tip; tortoise: olive shell and sturdy limbs; deer: modest antlers and fawn coat; wolf: slate coat and charcoal ridge. Original high-resolution generated art is kept separately from runtime assets.

Rebuild with Godot: `godot --headless --path . --script res://tools/bake_party_pixels.gd -- /absolute/source-manifest.json`. The external manifest is an array of `{ "kind": "fox", "source": "/absolute/original.png", "height": 40 }`. The native image pipeline trims alpha halos, samples nearest pixels and quantizes to the shared palette; it writes runtime PNGs and manifest.

Validation: Godot 4.7 import, gameplay self-test and save repair regression passed. All new runtime PNGs have binary alpha and at most 32 opaque colors. Actual gameplay captured with tools/preview.py; lineup review scene includes all seven characters.

## Druid walk v1

The druid now has eight baked walk frames at native resolution. A continuous build-time mesh moves the boots in alternating support/swing phases, the lower cloak, the free hand and the staff. Shared mesh vertices avoid open cutout seams. The original idle art remains unchanged. `animation/pixel_actor.gd` plays the padded atlas at runtime with nearest filtering, integer scales and a shared foot anchor. Stopping, teleporting and being downed reset walking. No runtime mesh or frame generation is required.

Rebuild on a graphical display: `godot --audio-driver Dummy --path . --script res://tools/bake_druid_walk.gd`. Review: `res://animation/druid_walk_review.tscn`; actual combat/movement review: `res://animation/druid_gameplay_preview.tscn` (isolated from player saves). The enlarged review travels at 30 px/s. Gameplay uses its existing 210 px/s movement speed; the v1 walk-only study exposed foot sliding at this speed. See the run update below. The remaining beasts were static at that point; wolf and fox now use the update below.

Regression checks now cover eight distinct unclipped frames, phase wrap, distance-driven advancement, stop/teleport, down/revive, gameplay and save repair.

## Druid run v1

Fast travel now selects a separate 12-frame run cycle: longer steps, higher swing feet, a forward lean and stronger cloak/arm motion. Running begins above 90 px/s and returns to walking below 65 px/s to prevent transition flicker. Both cycles share the original foot anchor and idle portrait; stopping resets the gait. At the actual 210 px/s gameplay speed, the run phase advances by distance / 50 px, with a 0.238-second cycle. The source support foot moves backward by 18 px over 36% of that cycle, cancelling forward world travel mathematically before pixel rounding/frame sampling. Some residual stepping and silhouette deformation remain because this is a skinned single-view original rather than newly painted running anatomy.

Bake: `godot --audio-driver Dummy --path . --script res://tools/bake_druid_walk.gd -- --run`. Review: `res://animation/druid_run_review.tscn` compares walk-only vs run at the same speed, then slows/stops/resumes. Test coverage includes run cadence at 210 px/s, gait hysteresis, 12 unique unclipped frames and support-foot travel. The original walk atlas remains unchanged. Runtime atlas is 320x288 px, binary alpha, 19 opaque palette colors.

Recording now disables encoder stdin and validates a temporary MP4 before exposing it as a finished deliverable.

## Wolf and fox gait v1

Both beasts now have a 12-frame four-beat walk and a 12-frame diagonal trot (48 frames in four atlases). The same continuous skin baker uses species-specific leg roots/feet, step sizes and tail motion, preserving the approved idle sprites. Source leg influence has a rigid central band to avoid stretching the paws, and the tail mask excludes hind paws. There are no new attack paintings: attacks and windups hold the original standing stance while existing hit/effect feedback remains.

Both allied and enemy wolves/foxes use the shared native-pixel player. Per-actor state keeps duplicate animals independent. Slow travel walks; above 60 px/s it trots, returning to walk below 45 px/s. Stride comes from the source support curve; doubled actor scale doubles its world stride. All movement still uses the original game stats. Very fast catch-up travel remains subject to a cadence cap, so the single-view skin is an interim motion solution rather than a full anatomical redraw.

Rebuild all four atlases on a graphical display: `godot --audio-driver Dummy --path . --script res://tools/bake_quadrupeds.gd`. Review `res://animation/quadruped_review.tscn` shows both directions, walk/trot/stop/resume and attack stance. `res://animation/quadruped_gameplay_preview.tscn` uses two wolves and two foxes plus enemy versions, without loading or writing player saves. Each atlas is 384x216 px, binary alpha; wolf uses 13 opaque colors, fox uses 21.

Regression checks cover all frame bounds/uniqueness, species gait selection, independent duplicate state, attack and windup hold, resume, doubled stride and source support travel. Gameplay and save repair checks also passed.

## Complete party movement and event poses v1

Marten, deer and tortoise now join the movement player with 12-frame slow and fast cycles each. Deer cells are taller to preserve antler padding. Tortoise keeps staggered footfall timing even at high speed; its shell remains almost level. Normal gameplay speeds and cadence caps remain, so rapid catch-up movement can still slide.

Ten baked role poses use the approved original sprites: boar/wolf/marten strikes; fox casting; deer healing; tortoise bash/guard; druid support/heal/revive. Each pose has eight frame slots. These are continuous 2D skin deformations rather than newly painted open jaws or detailed joint anatomy. Impact/healing remains instantaneous under the existing combat rules: the pose begins at contact and recovers, without adding a hidden damage delay. Existing trails, hit flashes and spell effects remain. The guard posture persists while a stationary tortoise is shielded. Druid revive loops only during the actual hold; interrupting returns control, and skills remain blocked while channeling. Dead actors suppress action poses.

The shared action player takes explicit attacker/healer identity so overlapping duplicates cannot steal each other's gestures. Routine attacks cannot overwrite an ongoing heal or guard gesture. Source meshes are build-time only; runtime plays native pixel atlases. All approved idle assets and existing walk/run atlases are preserved.

Rebuild new movement: `godot --audio-driver Dummy --path . --script res://tools/bake_quadrupeds.gd -- marten deer turtle`. Rebuild actions: `godot --audio-driver Dummy --path . --script res://tools/bake_actions.gd`. Output metadata is flushed and closed explicitly. `full_motion_review.tscn` reviews all seven; `full_gameplay_preview.tscn` exercises heal, buff, guard, group heal, hold/revive, and a second party in real combat without reading/writing saves.

Validation includes native atlas bounds/variation and binary alpha, all movement regression checks, actual damage/heal/cast/guard event ownership, channel interrupt/skill block, expiry/death, gameplay self-test and save repair. GitHub CI runs the action-event regression too.
