extends "res://animation/pixel_gameplay_preview.gd"
# Exercise the real movement/combat loop without touching player saves.
func update_game(dt):
	var t=fposmod(clock,6.0)
	stick=Vector2.RIGHT if t<1.5 else (Vector2.LEFT if t>=2.2 and t<3.7 else Vector2.ZERO)
	super(dt)
