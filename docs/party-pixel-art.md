# Party pixel art

Six new static sprites (druid, marten, fox, tortoise, deer, wolf) share a muted 32-color palette with the existing dark quarter-view scene. Native heights: 72, 32, 40, 32, 64, 48 px. Boar retains its existing walk frames. Other creatures currently translate with static silhouettes, with no whole-image walk shake. Combat, hit feedback and downed poses remain.

Sources were generated as isolated right-facing elevated side-view characters with transparent backgrounds, chunky clusters, earthy colors and natural early-tier anatomy. Druid: moss cloak and wooden staff; marten: cream throat and long tail; fox: rust coat and cream tail tip; tortoise: olive shell and sturdy limbs; deer: modest antlers and fawn coat; wolf: slate coat and charcoal ridge. Original high-resolution generated art is kept separately from runtime assets.

Rebuild with Godot: `godot --headless --path . --script res://tools/bake_party_pixels.gd -- /absolute/source-manifest.json`. The external manifest is an array of `{ "kind": "fox", "source": "/absolute/original.png", "height": 40 }`. The native image pipeline trims alpha halos, samples nearest pixels and quantizes to the shared palette; it writes runtime PNGs and manifest.

Validation: Godot 4.7 import, gameplay self-test and save repair regression passed. All new runtime PNGs have binary alpha and at most 32 opaque colors. Actual gameplay captured with tools/preview.py; lineup review scene includes all seven characters.
