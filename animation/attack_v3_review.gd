extends "res://animation/pixel_gameplay_preview.gd"
# Two new species, actual normal attacks followed by actual skill button callbacks.
var cues={}
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["marten","fox"]:
		var d=make_owned(kind,3,{"kind":kind,"level":3,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1100,760)
	enemies.clear()
	for i in 2:
		units[i].pos=Vector2(1220,680+i*140)
		spawn_enemy("turtle",units[i].pos+Vector2(48 if i==0 else 200,0),5)
		enemies[-1].hp=9999
		enemies[-1].maxhp=9999
		enemies[-1].active=true
	spawn_enemy("boar",Vector2(2590,850),4,true)
	clear_overlay()
func update_game(dt):
	super(dt)
	for cue in [[2.2,1],[3.8,0]]:
		if clock>=cue[0] and not cues.has(cue[1]):
			cues[cue[1]]=true
			use_companion_skill(cue[1])
