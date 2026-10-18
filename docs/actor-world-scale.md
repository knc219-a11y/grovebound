# Actor/world scale

The beginner map stays unchanged. Runtime actors now render at a shared 2× native pixel scale (druid 144px; boar 96px; wolf 96px; deer 128px; fox 80px; marten/turtle 64px). Bosses keep their existing extra 2× multiplier. Integer scaling preserves crisp pixels in idle, walk and action playback.

World HP bars and floating numbers use the resulting sprite height; shadows and status/selection rings follow actor size. Out-of-combat formation offsets are doubled. Runtime actor visual_scale is passed into distance-based gait progression so larger legs do not cycle as though sprites were still native size. Default visual_scale remains 1 for isolated tests and study scenes. HUD portraits remain unchanged.

This is a visual scale pass: combat distances, movement speeds and enemy tell hit areas retain existing balance. The background is still painted scenery without prop collision. Boss dimensions are intentionally exaggerated.

Validation: Godot 4.7 clean import; gameplay self-test; pixel actor regression test; HUD screenshot and six-second actual combat recording reviewed locally.
