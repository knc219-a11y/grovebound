extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	g.start_stage(false)
	var counts={}; var rewards=0
	for e in g.enemies:
		if not e.boss: counts[e.pack]=counts.get(e.pack,0)+1
		if not e.get("swarm",false): rewards+=1
	assert(counts=={0:5,1:2,2:2,3:7,4:2,5:9})
	assert(rewards==12 and g.enemies.size()==28)
	for pack in g.Trail.FOLLOWERS:
		var sum=0.0
		for e in g.enemies:
			if e.get("pack",-1)==pack and e.get("swarm",false): sum+=e.swarm_damage
		assert(is_equal_approx(sum,1.6))
	# Main path, including rest approach, never activates either optional clearing.
	for point in [Vector2(650,790),Vector2(1000,850),Vector2(1500,820),g.Trail.REST,Vector2(2190,760)]:
		g.player.pos=point
		g.trail.update(g)
	for e in g.enemies:
		if e.get("pack",-1) in [2,4]:
			assert(not g.trail.engageable(e))
			var hp=e.hp
			g.hit_enemy(e,999,g.player.pos,g.player)
			assert(e.hp==hp and not g.combat_enemies().has(e))
	# A fox explosion close enough to overlap the north clearing cannot pull it.
	g.owned.clear(); g.squad.clear()
	var d=g.make_owned("fox",1,{"kind":"fox","level":1,"xp":0,"trait":"강인함","grade":"common","options":[]})
	g.squad=[d.id]; g.start_stage(false)
	g.enemies.clear()
	g.spawn_enemy("boar",Vector2(1100,680),1)
	g.spawn_enemy("deer",Vector2(1100,510),1)
	g.enemies[1].pack=2
	g.player.pos=Vector2(1100,800)
	g.units[0].pos=Vector2(1100,800)
	var optional_hp=g.enemies[1].hp
	g.use_companion_skill(0)
	g.Assault.advance(g,g.units[0],0.23)
	assert(g.enemies[1].hp==optional_hp and not g.enemies[1].active)
	g.player.pos=g.Trail.NORTH
	g.trail.update(g)
	assert(g.trail.engageable(g.enemies[1]))
	g.hit_enemy(g.enemies[1],1,g.player.pos,g.player)
	assert(g.enemies[1].hp==optional_hp-1)
	# Returning and starting a fresh stage restores the choice; south unlock is independent.
	g.show_camp(); g.start_stage(false)
	g.trail.unlock_paths(g.Trail.SOUTH)
	for e in g.enemies:
		if e.get("pack",-1)==2: assert(not g.trail.engageable(e))
		if e.get("pack",-1)==4: assert(g.trail.engageable(e))
	g.start_stage(true)
	assert(g.enemies.size()==1)
	print("WAVE PROGRESSION PASS: 5/2/7/9 main waves, unchanged12 reward targets, optional clearings excluded from targeting/AoE until player entry, independent unlock/reset, tutorial preserved")
	g.free(); quit()
