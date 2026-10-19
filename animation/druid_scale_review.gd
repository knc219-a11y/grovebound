extends "res://animation/pixel_gameplay_preview.gd"
# Actual repeated player auto-attacks, with harmless stationary targets and isolated save.
func _ready():
	super()
	start_stage(false)
	units.clear()
	squad.clear()
	player.pos=Vector2(1100,740)
	enemies.clear()
	spawn_enemy("boar",Vector2(1250,740),9)
	enemies[0].active=true
	enemies[0].stun=100
	spawn_enemy("boar",Vector2(2590,850),4,true)
	message="주인공 자동 공격 · 기본 몸체 크기 유지 검토"
	message_time=10
