extends "res://animation/pixel_gameplay_preview.gd"
var show_result=false
var show_roster=false
var did_capture=false
func _ready():
	super()
	owned.clear()
	squad.clear()
	loot_rng.seed=2710
	var first=make_owned("boar",3,Loot.roll("boar",3,loot_rng,"rare"))
	squad.append(first.id)
	start_stage(false)
	screenshot_mode=true
	player.pos=Vector2(1100,740)
	units[0].pos=player.pos+Vector2(-65,70)
	enemies.clear()
	captures.clear()
	for i in 3:
		var record=Loot.roll("boar",3,loot_rng,Loot.GRADES[i])
		record.pos=player.pos+Vector2(80+i*145,50)
		captures.append(record)
	in_combat=false
	message=""
	message_time=0
	if show_result:
		player.pos=captures[-1].pos
		interact()
		show_loot_details(owned[-1].id,-1,false)
	if show_roster:
		for tier in Loot.GRADES: make_owned("boar",3,Loot.roll("boar",3,loot_rng,tier))
		mode="camp"
		open_roster()
func _process(dt):
	combat_feedback.advance(dt)
	if clock>=2.2 and not did_capture and not show_result:
		did_capture=true
		player.pos=captures[-1].pos
		interact()
	super(dt)
