extends SceneTree
const Game=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("check")
func defeat(g,optional=false):
	if optional: g.trail.visited.side=true
	for e in g.enemies:
		if (e.pack==8)==optional: g.hit_enemy(e,999999,g.player.pos,g.player)
func check():
	var g=Game.new(); root.add_child(g); g.set_process(false)
	g.show_camp(); g.clear_overlay(); g.owned.clear(); g.squad.clear(); g.materials=0
	for kind in ["boar","fox","wolf","deer","turtle","bat"]:
		var d=g.make_owned(kind,1,{"kind":kind,"level":1,"xp":0,"star":3,"trait":"강인함","options":[]})
		g.squad.append(d.id)
	g.campaign_progress=R.migrated({"cleared_stages":[1,2,3]})
	g.cleared_stages=[1,2,3]
	var initial=g.owned.duplicate(true)
	var route=R.coordinate(4,1)
	assert(g.depart_route(route) and not g.growth_replay)
	defeat(g); g.player.pos=g.trail.data.exit; g.in_combat=false; g.captures.clear()
	assert(g.finish_route(true) and g.materials==14)
	for i in 6: assert(g.owned[i]==g.Management.project(initial[i],240))
	g.show_camp(); g.clear_overlay(); assert(g.depart_route(route) and g.growth_replay)
	var before=g.owned.duplicate(true); var materials=g.materials
	var weak=g.enemies.filter(func(e): return e.get("swarm",false))[0]
	g.hit_enemy(weak,999999,g.player.pos,g.player)
	assert(g.materials==materials and g.owned==before)
	defeat(g)
	for i in 6: assert(g.owned[i]==g.Management.project(before[i],2880))
	assert(g.materials==materials+12)
	defeat(g,true)
	for i in 6: assert(g.owned[i]==g.Management.project(before[i],4320))
	assert(g.materials==materials+18 and g.captures.all(func(c): return c.star==1 and c.options.is_empty()))
	g.player.pos=g.trail.data.exit; g.in_combat=false; g.captures.clear(); g.save_blocked=true
	assert(not g.finish_route(true) and g.materials==materials+18)
	g.save_blocked=false; assert(g.finish_route(true) and g.materials==materials+48)
	assert(not g.finish_route(true))
	assert(R.rewards(route,true).xp==2880 and R.rewards(route,true).materials==42)
	assert(R.rewards(route).xp==240 and R.rewards(route).materials==14)
	g.show_camp(); g.clear_overlay(); g.map_theme=4; g.map_stage=1; g.open_stage_select()
	assert(g.overlay.get_children().any(func(n): return n is Label and n.text.contains("재탐험") and n.text.contains("2880")))
	g.start_stage(false,2); assert(not g.growth_replay)
	g.free()
	print("GROWTH REPLAY PASS: first-clear preserved, six travelers exact XP x12/materials x3, optional rewards, weak mobs excluded, atomic bonus failure/retry, map policy, legacy isolated")
	quit()
