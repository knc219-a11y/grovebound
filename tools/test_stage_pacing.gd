extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.start_stage(false)
	assert(g.enemies.size()==28)
	var reward_targets=0
	for e in g.enemies:
		if not e.get("swarm",false): reward_targets+=1
		assert(e.pos.x>=170 and e.pos.x<=2740 and e.pos.y>=345 and e.pos.y<=1130)
	assert(reward_targets==12)
	assert(g.Trail.follower_offsets(0)!=g.Trail.follower_offsets(3))
	assert(g.Trail.follower_offsets(3)!=g.Trail.follower_offsets(5))
	assert(g.trail.next_stop(g.enemies).pack==0)
	assert(g.trail.objective(g.enemies,g.Trail.PACKS[0]).contains("5/5"))
	assert(g.trail.objective(g.enemies,Vector2(1280,800)).contains("굽은 풀길"))
	for point in [Vector2(340,800),g.Trail.PACKS[0],g.Trail.PACKS[3],g.Trail.REST,g.Trail.PACKS[5]]:
		g.player.pos=point
		g.update_hud()
		for line in g.quest_label.text.split("\n"):
			assert(g.font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x<=580)
	g.player.pos=Vector2(340,800)
	var before=g.materials
	g.message="교감 안내 보존"
	for pack in [0,1,3]:
		for e in g.enemies:
			if e.get("pack",-1)==pack: e.hp=0
		g.trail.update_progress(g,0.05)
		assert(g.trail.milestone.contains(g.Trail.ENCOUNTERS[pack].name))
		g.trail.update_progress(g,0.5)
		assert(g.trail.milestone_time<2.6)
	assert(g.materials==before and g.message=="교감 안내 보존")
	assert(g.trail.next_stop(g.enemies).pos==g.Trail.REST)
	assert(g.trail.objective(g.enemies,g.Trail.REST).contains("[F]"))
	g.player.pos=g.Trail.REST
	g.trail.update(g)
	assert(g.trail.next_stop(g.enemies).pack==5)
	g.trail.update_progress(g,3)
	assert(g.trail.milestone_time==0)
	for e in g.enemies:
		if e.get("pack",-1)==5: e.hp=0
	assert(g.trail.next_stop(g.enemies).pack==-2)
	# The final pack cannot pull the boss before the player crosses the entrance.
	g.start_stage(false)
	var boss=g.enemies[-1]
	assert(boss.boss and boss.stage_entry and not g.combat_enemies().has(boss))
	var hp=boss.hp
	g.player.pos=Vector2(2240,850)
	for u in g.units: u.pos=boss.pos-Vector2(10,0)
	g.hit_enemy(boss,100,g.player.pos,g.player)
	g.update_game(0.05)
	assert(boss.hp==hp and not boss.active and boss.wind==0)
	g.player.pos=Vector2(2360,850)
	g.trail.update(g)
	assert(g.combat_enemies().has(boss) and boss.active and boss.intro>1)
	g.hit_enemy(boss,1,g.player.pos,g.player)
	assert(boss.hp==hp-1)
	g.start_stage(false)
	assert(g.trail.milestone_time==0 and g.trail.next_stop(g.enemies).pack==0)
	assert(not g.trail.engageable(g.enemies[-1]))
	print("STAGE PACING PASS: distinct formations, unchanged28/12 budget, remaining count, one-time clear banner, notice/reward preservation, optional rest suggestion, boss entrance isolation, fresh run reset")
	g.free()
	quit()
