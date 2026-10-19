extends "res://animation/pixel_gameplay_preview.gd"
# Real AI and collision; no reads or writes to the user's save.
func _ready():
	super()
	start_stage(false)
	player.pos=Vector2(1480,800)
	units.clear()
	squad.clear()
	enemies.clear()
	spawn_enemy("boar",Vector2(1650,800),4,true)
	enemies[0].active=true
	enemies[0].cd=0.3
	message="우두머리 동작 검토 · 발구르기 → 돌진"
	message_time=14
func _process(dt):
	# Sidestep the first stomp, then stand within charge range for swept hit review.
	stick=Vector2.LEFT if clock>0.3 and clock<1.15 else Vector2.ZERO
	super(dt)
