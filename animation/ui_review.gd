extends "res://animation/full_gameplay_preview.gd"
@export var screen="hud"
func _ready():
	super()
	preview_events=false
	materials=24
	tutorial_done=true
	for kind in ["boar","wolf"]: squad.append(make_owned(kind,2).id)
	if screen=="camp": show_camp()
	elif screen=="roster":
		mode="camp"
		open_roster()
	else:
		player.hp=135
		units[0].skill=6
		units[1].hp=units[1].maxhp*0.22
		units[2].hp=0
		units[2].pos=player.pos+Vector2(35,20)
		heal_cd=3
		buff_cd=7
		update_hud()
