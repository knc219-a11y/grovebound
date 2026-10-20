extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Assault=preload("res://companion_assault.gd")
func _initialize(): call_deferred("check")
func setup(g,kind):
	g.owned.clear(); g.squad.clear()
	var d=g.make_owned(kind,1,{"kind":kind,"level":1,"xp":0,"trait":"강인함","grade":"common","options":[]})
	g.squad=[d.id]
	g.start_stage(false)
	g.player.pos=Vector2(700,800)
	g.units[0].pos=Vector2(700,800)
	g.enemies.clear()
	g.combat_feedback.clear()
	return g.units[0]
func check():
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	var u=setup(g,"boar")
	for p in [Vector2(800,800),Vector2(860,825),Vector2(915,780),Vector2(860,910)]: g.spawn_enemy("boar",p,9)
	var original=g.enemies[0].hp
	g.use_companion_skill(0)
	assert(u.pos==Vector2(700,800) and g.enemies[0].hp==original)
	Assault.advance(g,u,0.08)
	assert(u.pos.x>700 and u.pos.x<895)
	Assault.advance(g,u,0.16)
	for i in 3:
		assert(is_equal_approx(g.enemies[i].hp,original-g.attack(u.data)*3.5))
		assert(g.enemies[i].stun==1.5)
	assert(g.enemies[3].hp==original)
	Assault.advance(g,u,1)
	assert(is_equal_approx(g.enemies[0].hp,original-g.attack(u.data)*3.5))
	assert(u.skill==10 and u.contribution.skills==1)
	# Reverse direction, swept collision with one coarse tick, and death cancellation.
	u=setup(g,"boar")
	g.spawn_enemy("boar",Vector2(600,800),9)
	g.use_companion_skill(0)
	assert(u.face==-1)
	u.hp=0
	original=g.enemies[0].hp
	Assault.advance(g,u,1)
	assert(not u.has("assault") and g.enemies[0].hp==original)
	u=setup(g,"fox")
	for p in [Vector2(800,800),Vector2(965,800),Vector2(800,970),Vector2(1000,800)]: g.spawn_enemy("boar",p,9)
	original=g.enemies[0].hp
	g.use_companion_skill(0)
	var center=u.assault.to
	Assault.advance(g,u,0.21)
	assert(g.enemies[0].hp==original)
	Assault.advance(g,u,0.02)
	for e in g.enemies:
		var expected=g.attack(u.data)*2.5 if e.home.distance_to(center)<=Assault.BLAST_RADIUS else 0.0
		assert(is_equal_approx(e.hp,original-expected))
	assert(not u.has("assault") and u.skill==10)
	# New weak followers cannot inflate the old material/XP/bond budget.
	g.start_stage(false)
	assert(g.enemies.size()==16)
	var before=g.materials
	var xp=u.data.xp
	var followers=0
	for e in g.enemies:
		if e.get("swarm",false):
			followers+=1
			assert(e.hp<g.attack(g.units[0].data)*2.5)
			g.hit_enemy(e,999,g.player.pos,g.player)
	assert(followers==4 and g.materials==before and g.captures.is_empty())
	assert(g.units[0].data.xp==xp)
	g.use_companion_skill(0)
	g.finish(false)
	assert(not g.units[0].has("assault"))
	g.start_stage(true)
	assert(g.enemies.size()==1)
	print("COMPANION ASSAULT PASS: swept multi-hit dash, one hit per enemy, outside lane, left facing, death cancel, delayed fixed-center blast/radius, cooldown, reward-neutral followers, result cancel, isolated tutorial")
	g.free(); quit()
