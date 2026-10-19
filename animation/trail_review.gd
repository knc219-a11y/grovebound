extends "res://animation/pixel_gameplay_preview.gd"
# Layout inspection: real Godot map/actors/UI, frozen enemies, no player save.
var view="flow"
var phase=0
func _ready():
	super()
	start_stage(false)
	screenshot_mode=view not in ["combat","boss_intro"]
	player.pos=Vector2(930,790)
	for i in units.size(): units[i].pos=player.pos+Vector2(-75+i*30,55)
	for e in enemies: e.active=false
	in_combat=false
	if view=="rest": player.pos=Trail.REST
	elif view=="boss": player.pos=Vector2(2360,790)
	elif view=="boss_intro":
		player.pos=Vector2(2240,790)
		for e in enemies:
			if not e.boss: e.hp=0
	trail.update(self)
	if view=="rest": show_trail_rest()
	message="사냥터 동선 검토" if view=="flow" else message
func _process(dt):
	if view=="combat":
		stick=Vector2(0.6,0) if clock<0.6 else Vector2.ZERO
		if clock>2 and heal_cd<=0: cast_heal()
	if view=="boss_intro": stick=Vector2.RIGHT if clock<1.1 else Vector2.ZERO
	if view=="flow":
		var direction=Vector2(0.7,-0.7) if clock<2 else Vector2.RIGHT if clock<4.1 else Vector2(0.9,0.37)
		if clock>4.1 and phase==0:
			phase=1
			show_trail_rest()
		if clock>5.8 and phase==1:
			phase=2
			resume_game()
		var previous=player.pos
		if not overlay.visible:
			player.pos+=direction.limit_length()*210*dt
			player.pos=player.pos.clamp(Vector2(170,345),Vector2(2740,1130))
		player.walk=player.pos.distance_to(previous)>0.01
		player.move_speed=player.pos.distance_to(previous)/maxf(dt,0.001)
		if absf(direction.x)>0.1: player.face=signf(direction.x)
		druid_rig.advance(player,dt)
		trail.update(self)
	super(dt)
