extends "res://animation/pixel_gameplay_preview.gd"
@export var candidates=false
func _ready():
	super()
	owned.clear()
	squad.clear()
	for kind in ["boar","turtle","fox","wolf","deer","bat","marten"]:
		var d=make_owned(kind,40,Loot.roll(kind,40,loot_rng,3))
		d.xp=0
	owned[0].favorite=true
	squad.append(owned[0].id)
	materials=18
	mode="camp"
	in_combat=false
	screenshot_mode=true
	var ids=[owned[0].id,owned[1].id,owned[2].id]
	if candidates: preview_synthesis(ids,ids[0],"position")
	else: show_synthesis(ids,ids[0],"position")
