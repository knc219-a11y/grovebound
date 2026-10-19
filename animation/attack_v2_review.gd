extends "res://animation/pixel_gameplay_preview.gd"
# Real basic attack queue and impact events; user saves remain isolated.
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","wolf"]:
		var d=make_owned(kind,3,{"kind":kind,"level":3,"xp":0,"trait":"용맹함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1100,760)
	enemies.clear()
	for i in 2:
		units[i].pos=Vector2(1220,680+i*140)
		spawn_enemy("turtle",units[i].pos+Vector2(48,0),5)
		enemies[-1].hp=9999
		enemies[-1].maxhp=9999
		enemies[-1].active=true
	spawn_enemy("boar",Vector2(2590,850),4,true)
	clear_overlay()
