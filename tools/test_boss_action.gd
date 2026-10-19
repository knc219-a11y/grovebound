extends SceneTree
const BossAction=preload("res://animation/boss_action.gd")
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.units.clear()
	g.enemies.clear()
	g.spawn_enemy("boar",Vector2(1500,800),4,true)
	var boss=g.enemies[0]
	g.player.pos=Vector2(1550,800)
	g.player.hp=180
	g.begin_boss_attack(boss,g.player)
	assert(boss.wind==1.15 and boss.attack_kind=="stomp")
	assert(BossAction.pose(boss).key=="stomp_tell")
	assert(BossAction.headroom(boss,96)==128)
	assert(g.player.hp==180)
	boss.wind=0
	g.resolve_enemy_attack(boss)
	assert(g.player.hp==152 and boss.cd==2.4)
	assert(BossAction.pose(boss).column==1)
	g.motion_actions.advance(boss,0.15)
	assert(BossAction.pose(boss).column==2)
	g.motion_actions.advance(boss,0.24)
	assert(BossAction.pose(boss).is_empty())
	g.player.pos=Vector2(1800,800)
	g.begin_boss_attack(boss,g.player)
	assert(boss.wind==1.25 and boss.attack_kind=="charge")
	assert(BossAction.pose(boss).key=="charge_tell")
	boss.wind=0
	g.resolve_enemy_attack(boss)
	assert(boss.dash==0.48 and BossAction.pose(boss).key=="charge_run")
	g.advance_charge(boss,0.4)
	assert(g.player.hp==117)
	g.advance_charge(boss,0.05)
	assert(g.player.hp==117 and boss.cd==2.8)
	assert(BossAction.pose(boss).is_empty()) # Travelling feet take priority.
	boss.walk=false
	assert(BossAction.pose(boss).key=="charge_recovery")
	boss.hp=0
	assert(BossAction.pose(boss).is_empty())
	var image=g.motion_actions.boss_action.texture.get_image()
	var unique={}
	for i in 6:
		var frame=image.get_region(Rect2i((i%3)*112,(i/3)*104,112,104))
		var bounds=frame.get_used_rect()
		assert(bounds.position.x>0 and bounds.position.y>0 and bounds.end.x<112 and bounds.end.y<104)
		assert(bounds.size.y<=64)
		unique[hash(frame.get_data())]=true
	assert(unique.size()==6)
	assert(image.get_region(Rect2i(112,0,112,104)).get_used_rect().size.y<=48)
	print("BOSS ACTION PASS: six poses, native bounds, stomp/charge timers and damage unchanged, one swept hit, recovery/death priority")
	g.free()
	quit()
