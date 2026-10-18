extends "res://animation/pixel_gameplay_preview.gd"
var preview_events=true
var cues={}
var group=0
func _ready():
	super()
	setup_team(0)
func setup_team(index):
	owned.clear()
	squad.clear()
	var species=["marten","turtle","deer","fox"] if index==0 else ["boar","wolf","deer","turtle"]
	for kind in species: squad.append(make_owned(kind,2).id)
	start_stage(false)
	player.pos=Vector2(920,790)
	for i in units.size():
		units[i].pos=player.pos+Vector2(-70+i*45,60+i*12)
		units[i].hp*=0.7
	enemies.clear()
	spawn_enemy("boar",Vector2(1280,690),12,true)
	spawn_enemy("wolf",Vector2(1400,820),5)
	for enemy in enemies: enemy.active=true
	in_combat=true
func update_game(dt):
	if not preview_events:
		super(dt)
		return
	if clock>8.0 and group==0:
		group=1
		setup_team(1)
	stick=Vector2.RIGHT*0.4 if clock<1.0 else Vector2.ZERO
	super(dt)
	if clock>=0.7 and not cues.has("heal"):
		cues.heal=true
		cast_heal()
	if clock>=1.3 and not cues.has("buff"):
		cues.buff=true
		cast_buff()
	if clock>=1.9 and not cues.has("guard"):
		cues.guard=true
		use_companion_skill(1)
	if clock>=2.6 and not cues.has("deer"):
		cues.deer=true
		use_companion_skill(2)
	if clock>=3.2 and not cues.has("down"):
		cues.down=true
		units[0].hp=0
		units[0].pos=player.pos+Vector2(35,15)
		holding_revive=true
	if clock>=6.5: holding_revive=false
