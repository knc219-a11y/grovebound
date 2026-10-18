extends "res://animation/druid_gameplay_preview.gd"
func _ready():
	super()
	# Use real ownership/unit construction; saves are disabled by the base preview.
	owned.clear()
	squad.clear()
	for kind in ["wolf","fox","wolf","fox"]:
		squad.append(make_owned(kind,2).id)
	start_stage(false)
	player.pos=Vector2(900,790)
	for i in units.size(): units[i].pos=player.pos+Vector2(-100+i*35,70+i*15)
	enemies.clear()
	spawn_enemy("boar",Vector2(1300,690),4,true)
	spawn_enemy("wolf",Vector2(1440,770),2)
	spawn_enemy("fox",Vector2(1470,840),2)
	for enemy in enemies: enemy.active=true
	in_combat=true
