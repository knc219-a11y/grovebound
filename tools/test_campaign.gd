extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Campaign=preload("res://campaign.gd")
const Species=preload("res://creature_species.gd")
func _initialize(): call_deferred("check")
func check():
	assert(Campaign.progress({"unlocked":true})==[1])
	assert(Campaign.progress({"cleared_stages":[3,2]})==[])
	assert(Campaign.progress({"cleared_stages":[1,2,3,99,1]})==[1,2,3])
	assert(Campaign.progress({"cleared_stages":[1.0,2.0],"unlocked":true})==[1,2])
	assert(not Campaign.accessible(3,[1]) and Campaign.accessible(3,[1,2]))
	assert(Species.can_tame("bat","druid") and not Species.can_tame("slime","druid"))
	assert(Species.can_tame("slime","contractor") and not Species.can_tame("skeleton","contractor"))
	assert(Species.can_tame("skeleton","necromancer") and not Species.can_tame("wolf","necromancer"))
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	g.expedition.clear(); g.show_camp(); g.clear_overlay()
	g.cleared_stages=[]
	assert(not g.depart_stage(2))
	g.cleared_stages=[1]; g.unlocked=true
	assert(g.depart_stage(2) and g.current_stage==2)
	assert(g.enemies.size()==30 and g.enemies[-1].kind=="golem" and not g.trail.engageable(g.enemies[-1]))
	var base_count=0
	for e in g.enemies:
		if not e.get("swarm",false): base_count+=1
	assert(base_count==12)
	var old_materials=g.materials
	g.finish(true)
	assert(g.cleared_stages==[1,2] and g.materials==old_materials+10)
	g.finish(true)
	assert(g.materials==old_materials+10)
	assert(g.depart_stage(3) and g.current_stage==3 and g.enemies.size()==30)
	assert(g.enemies[-1].kind=="guardian" and g.trail.campaign_id==3)
	g.enemies.clear(); g.captures.clear()
	var owned=g.owned.size()
	assert(g.make_owned("slime",1).is_empty() and g.owned.size()==owned)
	for kind in ["slime","golem","skeleton","wraith","guardian"]:
		g.spawn_enemy(kind,Vector2(800,800),2,false,true)
		g.hit_enemy(g.enemies[-1],9999,g.player.pos,g.player)
	assert(g.captures.is_empty())
	g.spawn_enemy("bat",Vector2(800,800),2,false,true)
	g.hit_enemy(g.enemies[-1],9999,g.player.pos,g.player)
	assert(g.captures.size()==1 and g.captures[0].kind=="bat")
	var fixed=g.captures[0].duplicate(true)
	g.player.pos=Vector2(800,800); g.in_combat=false
	g.interact()
	assert(g.owned.size()==owned+1 and g.owned[-1].trait==fixed.trait and g.owned[-1].options==fixed.options)
	g.clear_overlay()
	g.open_collection()
	assert(g.overlay.get_node("CreatureCollection").get_child(0).get_child_count()==16)
	g.clear_overlay()
	# Real save/load on a unique test path; never touches the user's production save.
	var persisted=load("res://main.gd").new()
	persisted.save_path="user://campaign-regression-"+str(Time.get_ticks_usec())+".json"
	persisted.owned=g.owned.duplicate(true); persisted.squad=g.squad.duplicate()
	persisted.discovered=g.discovered.duplicate(); persisted.next_id=g.next_id
	persisted.cleared_stages=[1,2]; persisted.unlocked=true
	persisted.seen_species=g.seen_species.duplicate(); persisted.tutorial_done=true
	persisted.save_game()
	var identity=persisted.owned.duplicate(true)
	persisted.owned.clear(); persisted.cleared_stages.clear(); persisted.seen_species.clear()
	persisted.load_game()
	assert(JSON.stringify(persisted.owned)==JSON.stringify(identity) and persisted.cleared_stages==[1,2],JSON.stringify({"before":identity,"after":persisted.owned,"cleared":persisted.cleared_stages}))
	assert("guardian" in persisted.seen_species and persisted.owned[-1].kind=="bat")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(persisted.save_path))
	if not persisted.save_backup_path.is_empty(): DirAccess.remove_absolute(ProjectSettings.globalize_path(persisted.save_backup_path))
	persisted.free()
	# Both new spell patterns use the same radius for warning and damage, and can be dodged.
	g.clear_overlay(); g.enemies.clear(); g.units.clear()
	g.player.pos=Vector2(1200,800); g.player.hp=180
	g.spawn_enemy("wraith",Vector2(1000,800),3)
	var wraith=g.enemies[0]
	g.EnemyPatterns.begin(wraith,g.player)
	assert(wraith.aim==Vector2(1200,800) and wraith.tell_radius==75)
	g.player.pos=Vector2(1400,800)
	g.resolve_enemy_attack(wraith)
	assert(g.player.hp==180)
	g.player.pos=wraith.aim
	g.resolve_enemy_attack(wraith)
	assert(g.player.hp<180)
	for kind in Species.NEW:
		var image=g.creature_visual.sheets[kind].get_image()
		assert(image.get_size()==Vector2i(448,104))
		for frame in 4:
			var bounds=image.get_region(Rect2i(frame*112,0,112,104)).get_used_rect()
			assert(bounds.position.x>0 and bounds.end.x<112 and bounds.position.y>0 and bounds.end.y<=94)
	print("CAMPAIGN PASS: ordered unlock/legacy save, stage2/3 encounters, duplicate reward guard, family-based future taming policy, no incompatible bonds, bat identity/collection/save roundtrip, dodgeable wraith, ten four-pose sheets")
	g.free(); quit()
