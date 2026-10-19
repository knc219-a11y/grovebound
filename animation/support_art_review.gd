extends "res://animation/pixel_gameplay_preview.gd"
var cues={}
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["turtle","deer","boar","wolf"]:
		var d=make_owned(kind,3,{"kind":kind,"level":3,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1100,760)
	for i in 4:
		units[i].pos=player.pos+Vector2(90+i*40,20+i*18)
		units[i].hp*=0.65
	enemies.clear()
	spawn_enemy("boar",Vector2(1380,780),4,true)
	enemies[0].hp=9999
	enemies[0].maxhp=9999
	enemies[0].active=true
	clear_overlay()
func update_game(dt):
	super(dt)
	for cue in [[0.8,0],[1.7,1]]:
		if clock>=cue[0] and not cues.has(cue[1]):
			cues[cue[1]]=true
			use_companion_skill(cue[1])
