# Typography and background v2

Runtime fonts are Galmuri11 Regular and Bold by quiple, obtained from the official upstream repository. The full upstream TTF bytes are stored unchanged inside compressed Godot FontFile .res resources, preserving all Hangul syllables. No glyph subsetting or renamed derivative font is used. assets/fonts/README.md pins the upstream revision and SHA256 hashes; LICENSE.txt accompanies the font resources. Main body text uses Regular, large headings and combat HUD/numbers use Bold. Subpixel positioning is disabled. Existing UI rectangles and controls are retained.

Font resources: `assets/fonts/Galmuri11.res`, `assets/fonts/Galmuri11-Bold.res`. Original Noto font and old background remain available.

Background `assets/pixel-ruins-background-v2.png` is a new sibling asset, generated with the built-in imagegen tool (not the API/CLI fallback). Original generated source: `/workspace/scratch/bb70d37d6886/generated_images/exec-dc0d5661-3ddf-47d4-995f-dcfa3d4713b3.png`. Runtime image is baked by native Godot nearest sampling to 1450x825 and a 64-entry earth/stone palette (63 colors used). The existing world plate still spans 2900x1650; this does not add collision, navigation or gameplay obstacles.

The background preserves the quarter-view ruined courtyard and outer wall/brazier layout while simplifying thin cobble outlines and high-contrast small rubble. The floor uses broader, quieter soil and paving patches so the approved beasts read more clearly.

## Final image prompt

Use case: style-transfer. Asset: landscape quarter-view pixel RPG background map plate, no characters. Image 1 is the EDIT TARGET and layout reference. Image 2 is STYLE REFERENCE ONLY: match its chunky, muted pixel clusters and earthy dark-fantasy beasts; do not copy its lettering, panels, animals or layout into the map. Repaint Image 1 while strictly preserving the overall open courtyard floor, quarter-view camera, broad floor height, ruined walls concentrated at outer perimeter, and lone small warm brazier in upper-left corner. Keep the central 70 percent open, unobstructed and walkable-looking, including a wide clear west-east band; no new columns, gates, stairs or raised obstacles in the middle. Make this a coherent hand-crafted low-resolution pixel-art map, not a detailed painterly texture. Radically reduce noisy tiny rubble, black speckles and repeated thin cobblestone outlines on the floor. Ground is low-contrast dusty warm slate/olive earth with broad irregular worn paving groups and large quiet patches. Use fewer larger square pixel clusters, flat 3-shade material ramps, crisp stepped edges, no dithering, no microtexture, no antialiasing or smooth painted gradients. Walls/root silhouettes remain dark and readable at the borders, with sparse moss and muted ochre plants. Palette should match brown/umber/slate/moss/cream characters in reference 2, but background stays darker and less contrasted so small characters read in gameplay. Soft subdued ambient light, only a restrained amber brazier accent; no dramatic spotlights or bright focal center. Flat opaque full-bleed background, same wide approximately 16:9 framing as target. NO text, letters, HUD, borders, characters, animals, grids, frame labels, watermarks or foreground vignettes.

References: previous `assets/pixel-ruins-background-v1.png` as edit target; approved `docs/party-pixel-lineup.png` as character/style reference.

## Rebuild and validation

Run `godot --headless --path . --script res://tools/bake_background.gd -- /absolute/generated-source.png` for the runtime background. Font rebuild instructions are in assets/fonts/README.md.

Font load, full Hangul range, UI symbols, text shaping and background dimensions/visibility are checked by `tools/test_art_type.gd` and CI. UI layout/callbacks, gameplay, animation events, combat feedback and save repair regressions passed. HUD, camp, roster and actual gameplay were rendered for inspection. Physical phone readability still needs device testing; the viewport can scale the native font grid at non-integer ratios.

Current terrain revision: the v3 contour correction supersedes the v2 plate; see `docs/terrain-crisp.md`.
