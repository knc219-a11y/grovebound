extends SceneTree
const Preview=preload("res://animation/druid_scale_review.gd")
const Attack=preload("res://animation/druid_attack.gd")
const Pose=preload("res://animation/druid_pose.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	var enemy=g.enemies[0]
	var hp=enemy.hp
	g.player.cd=0.14
	g.player.action_remaining=0.0
	g.update_game(0.05)
	assert(enemy.hp==hp and Attack.frame(g.player)==1)
	g.update_game(0.05)
	assert(enemy.hp==hp and Attack.frame(g.player)==2)
	g.update_game(0.041)
	assert(enemy.hp==hp-6 and Attack.frame(g.player)==3)
	assert(is_equal_approx(g.player.cd,0.85))
	var indices={}
	for i in 8:
		var actor={"hp":100,"face":1,"walk":false,"action_key":"attack","action_duration":Attack.DURATION,"action_remaining":Attack.DURATION-Attack.TIMES[i]}
		assert(Attack.frame(actor)==i)
		indices[g.motion_actions.selection("druid",actor).region[0]]=true
		assert(Pose.mount(actor)==Attack.mount(actor))
		actor.walk=true
		assert(g.motion_actions.selection("druid",actor).is_empty())
		assert(Pose.mount(actor)==Vector2(8,-36))
		actor.walk=false
		actor.hp=0
		assert(not Attack.active(actor))
	assert(indices.size()==8)
	var image=g.motion_actions.druid_attack.get_image()
	var unique={}
	for i in 8:
		var frame=image.get_region(Rect2i(i*112,0,112,104))
		var bounds=frame.get_used_rect()
		assert(bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<112 and bounds.end.y==94)
		assert(bounds.size.y<=60 and bounds.size.y>=58)
		unique[hash(frame.get_data())]=true
	assert(unique.size()>=7)
	assert(image.get_region(Rect2i(0,0,112,104)).get_data()==image.get_region(Rect2i(7*112,0,112,104)).get_data())
	g.player.action_key="heal"
	g.player.action_remaining=0.3
	assert(not Attack.start(g.player))
	g.player.action_key="support"
	assert(not Attack.start(g.player))
	g.player.action_remaining=0
	g.player.cd=0.14
	g.update_game(0.05)
	assert(Attack.active(g.player))
	enemy.hp=0
	g.update_game(0.02)
	assert(not Attack.active(g.player))
	print("DRUID ATTACK PASS: six new sequential poses + exact idle endpoints, grounded58..60px body, pre-hit no damage, original6 damage/.85s cooldown, impact frame, hand routing, movement/death/support priority, lost target cancels windup")
	g.free()
	quit()
