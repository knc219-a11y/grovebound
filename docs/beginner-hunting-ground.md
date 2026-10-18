# Beginner hunting ground v1

Replaces the oversized ruined courtyard with a flat wooded clearing and a winding dirt trail. No stairs, monumental masonry, cliffs, or raised terraces. Existing combat, encounters and character sizes are unchanged.

Runtime: `assets/maps/greenwater-beginner-v1.webp`, 2900×1650, lossless WebP. Source: built-in imagegen, 1672×941, generated 2026-10-18; local source `generated_images/exec-ee01d866-6d8a-4d5a-8a5c-9a0ac4d103cd.png`. Reference: `docs/party-pixel-lineup.png` for palette/style only. Older ruins assets remain available.

Scale brief: a 72px druid corresponds to approximately 41 source pixels. Trees target 2–3 human heights; rocks ankle-to-knee height and shrubs knee-height. These are visual targets, not collision measurements. This is still a painted background without prop collision. The center remains open for west-east movement.

Pack with `tools/pack_background.gd -- SOURCE.png res://assets/maps/greenwater-beginner-v1.webp`. Nearest-neighbor resize retains source edges; reload verifies byte-exact RGB losslessness. Upscaling does not invent detail. Camera now clamps to actual world bounds so neither horizontal edge exposes blank space.

Validated in Godot 4.7: clean asset import, art/type test, UI test and gameplay self-test. Reviewed actual 1280×720 HUD capture and six-second combat recording (`docs/beginner-hud.png`, `docs/beginner-gameplay.mp4`, local review artifacts).

Generation brief: New full-bleed landscape pixel-art beginner beast hunting ground; elevated orthographic view with no horizon; broad gently winding west-east dirt trail and two open clearings; central 65% unobstructed; trees at outer top/bottom edges. Source-scale targets: trees 80–110px, shrubs 8–16px, stones 5–10px, flowers 2–5px, trail width 110–150px. No stairs, platforms, ruins, walls, cliffs, buildings, water, fences, characters, UI or text. Moss/sage grass, umber soil, warm grey pebbles, muted olive shrubs, tiny ochre wildflowers. Crisp stepped pixel clusters, compact shading, earthy daylight, quiet ground patches, no blur or foreground vignette.
