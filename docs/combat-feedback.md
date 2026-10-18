# Combat readability v1

Native Godot drawing now gives melee hits, fox ranged hits, druid strikes, heals, buffs, shield impacts and completed revives separate short effects in the established muted palette. No raster source assets were changed. The existing combat logic still applies damage and healing instantly: the fox effect is an immediate shot/contact burst, not a new travelling projectile or delayed hit.

Heal numbers show HP actually restored; damage numbers show HP actually lost. Hits within 120 ms merge only for the same target/category/block state, with separate lanes for subsequent numbers. Enemies have transient visual IDs so overlapping enemies cannot share numbers. Font shadows and target-height offsets keep text above actors. New feedback is bounded to 80 effect events and 32 number entries, expires automatically, and clears on stage start. These bounds concern the new feedback layer; no device FPS claim is made.

Boss tell geometry retains the actual attack widths/radii: 48 px swept charge radius, 130 px stomp radius and 56 px bite radius. Charge arrows indicate direction; its center line and circle arcs show remaining windup progress from the actual countdown. Cancelled/dead enemies immediately lose tells. Tortoise shield hits use a cyan shield mark; revive holds draw a dotted link and a target progress ring, ending on interruption/completion.

Review: `res://animation/combat_feedback_review.tscn` enlarges six effect examples. Real gameplay capture uses `res://animation/full_gameplay_preview.tscn` with heal, buff, guard, revive and two parties, without touching player saves.

Validation: Godot 4.7 import, gameplay self-test, pixel motion regression, action event integration, save repair and `res://tools/test_combat_feedback.gd` passed. Feedback tests check aggregation, independent targets, text lanes, bounded lifetime, immediate fox damage, actual healing, reduced shield damage, tell countdown and stage clearing. CI includes these checks.
