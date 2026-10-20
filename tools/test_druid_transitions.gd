extends SceneTree
const Preview=preload("res://animation/druid_scale_review.gd")
const Pose=preload("res://animation/druid_pose.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	var enemy=g.enemies[0]
	for direction in [-1,1,-1]:
		enemy.pos=g.player.pos+Vector2(direction*100,0)
		g.player.face=-direction
		g.player.action_remaining=0.0
		var hp=enemy.hp
		g.hit_enemy(enemy,6,g.player.pos,g.player)
		assert(g.player.face==direction and g.player.action_face==direction)
		assert(enemy.hp==hp-6)
	# A target crossing during anticipation must determine the impact direction.
	g.player.action_remaining=0.0
	g.player.cd=0.14
	g.update_game(0.05)
	assert(g.player.action_face==-1)
	enemy.pos=g.player.pos+Vector2(100,0)
	g.update_game(0.10)
	assert(g.player.face==1 and g.player.action_face==1)
	for action in ["attack","heal","support","revive","down"]:
		g.start_stage(false)
		g.player.action_key=action
		g.player.action_remaining=0.38
		g.player.action_duration=0.6
		g.player.action_face=-1
		g.player.channeling=true
		g.player.channel_time=2.0
		g.player.pixel_down=1.0
		g.player.pixel_moving=true
		g.player.pixel_running=true
		g.player.hit=0.18
		g.player.swing=0.22
		g.player.recoil=Vector2(6,0)
		g.revive_progress=2.0
		g.holding_revive=true
		if action=="down": g.player.hp=0
		g.show_camp()
		g.clear_overlay()
		var pos=g.player.pos
		for i in 60: g.update_town(1.0/60)
		assert(g.player.pos==pos and g.player.hp==g.player.maxhp)
		assert(Pose.active_key(g.player)=="")
		assert(Pose.mount(g.player)==Vector2(8,-36))
		assert(g.weapon_visual.angle_for(g.player)==0.0)
		assert(g.player.get("action_remaining",0)==0 and not g.player.channeling)
		assert(not g.player.pixel_moving and g.player.get("pixel_down",0)==0)
		assert(g.revive_progress==0 and g.revive_target==-1 and not g.holding_revive)
		g.start_stage(false)
		assert(Pose.active_key(g.player)=="" and g.player.pixel_last==g.player.pos)
		g.player.action_key="attack"
		g.player.action_remaining=0.38
		g.finish(false)
		assert(Pose.active_key(g.player)=="")
	print("DRUID TRANSITIONS PASS: target direction including crossing, unchanged damage, attack/heal/support/revive/down return, idle weapon, town position, fresh departure and result cleanup")
	g.free()
	quit()
