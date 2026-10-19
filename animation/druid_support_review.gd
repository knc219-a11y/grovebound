extends "res://animation/pixel_gameplay_preview.gd"
var cues={}
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","turtle"]:
		var d=make_owned(kind,3,{"kind":kind,"level":3,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1100,740)
	units[0].pos=player.pos+Vector2(75,35)
	units[0].hp=units[0].maxhp-60
	units[1].pos=player.pos+Vector2(-35,35)
	enemies.clear()
	spawn_enemy("boar",Vector2(2590,850),4,true)
	clear_overlay()
func update_game(dt):
	stick=Vector2.RIGHT if clock<0.3 else Vector2.ZERO
	for cue in [[0.7,"heal"],[1.9,"buff"],[3.0,"revive"]]:
		if clock>=cue[0] and not cues.has(cue[1]):
			cues[cue[1]]=true
			match cue[1]:
				"heal": cast_heal()
				"buff": cast_buff()
				"revive":
					units[1].hp=0
					units[1].pos=player.pos+Vector2(40,15)
					holding_revive=true
	if clock>6.3: holding_revive=false
	super(dt)
