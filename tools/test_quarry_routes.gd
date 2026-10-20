extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("check")
func check():
	assert(R.Quarry.STAGES.size()==8)
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	g.expedition.clear(); g.show_camp(); g.clear_overlay()
	g.cleared_stages=[]; g.unlocked=false; g.campaign_progress={"version":1,"cleared":[]}
	assert(not g.depart_route(R.coordinate(2,1)) and not g.depart_route(R.coordinate(2,8)))
	g.cleared_stages=[1]; g.unlocked=true; g.campaign_progress=R.migrated({"cleared_stages":[1]})
	assert(R.available(R.next(R.coordinate(1,8)),g.campaign_progress))
	g.map_theme=2; g.map_stage=4; g.open_stage_select()
	assert(g.overlay.find_child("DepartRoute",true,false).disabled)
	for stage in range(1,9):
		g.overlay.find_child("Stage_"+str(stage),true,false).pressed.emit()
		for label in g.overlay.get_children():
			if label is Label and label.position==Vector2(930,355):
				var measured=g.font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17)
				assert(label.position.y+measured.y<433,"Story overlaps stage rewards: "+label.text)
	g.overlay.find_child("Stage_1",true,false).pressed.emit()
	assert(g.mode=="camp" and not g.overlay.find_child("DepartRoute",true,false).disabled)
	g.overlay.find_child("DepartRoute",true,false).pressed.emit()
	assert(g.mode=="stage" and g.current_route==R.coordinate(2,1) and g.current_stage==2)
	assert(g.stage_background.resource_path=="res://assets/campaign/quarry-v1.webp" and g.trail.campaign_id==2)
	g.owned.clear(); g.squad.clear()
	for kind in ["boar","fox","deer","turtle","bat","marten"]:
		var d=g.make_owned(kind,6,{"kind":kind,"level":6,"xp":0,"star":1,"grade":"common","trait":"강인함","options":[]})
		g.squad.append(d.id)
	var identity=g.owned.duplicate(true)
	var total_xp=0
	for stage in range(1,9):
		g.show_camp(); g.clear_overlay()
		assert(g.depart_route(R.coordinate(2,stage)))
		assert(g.trail.area(g.player.pos).begins_with("2-%d" % stage))
		assert(g.trail.rest_name=="채굴터 쉼터" and g.units.size()==6 and g.active_units().size()==4)
		var p=R.profile(g.current_route)
		assert(p.level in range(4,8))
		assert(g.enemies.filter(func(e): return e.pack==8).map(func(e): return e.kind)==["bat","skeleton"])
		var before=g.materials; var reward=R.rewards(g.current_route)
		for e in g.enemies:
			if e.boss: assert(not g.trail.engageable(e) and not g.trail.begin_boss_intro(g))
		for e in g.enemies:
			if e.pack!=8 and not e.boss:
				e.guaranteed=true
				if e.get("swarm",false): assert(e.kind=="slime")
				g.hit_enemy(e,999999,g.player.pos,g.player)
		assert(g.captures.all(func(c): return c.kind=="bat"))
		for e in g.enemies:
			if e.boss:
				assert(e.kind=="golem" and e.level==R.boss_level(p) and e.maxhp==p.boss_hp)
				assert(g.trail.begin_boss_intro(g))
				g.player.hp=g.player.maxhp
				for u in g.units: u.pos=e.pos+Vector2(500,0)
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind=="slam" and e.aim==e.pos)
				var radius=e.tell_radius
				g.player.pos=e.aim+Vector2(radius+1,0); var hp=g.player.hp
				g.resolve_enemy_attack(e); assert(g.player.hp==hp)
				g.player.pos=e.aim; g.resolve_enemy_attack(e); assert(g.player.hp<hp)
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind==("slam" if stage==4 else "hex"))
				if stage==8:
					var target=e.aim; hp=g.player.hp
					g.player.pos=target+Vector2(e.tell_radius+1,0); g.resolve_enemy_attack(e)
					assert(g.player.hp==hp and e.aim==target)
					g.player.pos=target; g.resolve_enemy_attack(e); assert(g.player.hp<hp)
				g.hit_enemy(e,999999,g.player.pos,g.player)
		assert(g.trail.ready_to_clear(g.enemies) and g.mode=="stage")
		assert(g.enemies.filter(func(e): return e.pack==8 and e.hp>0).size()==2)
		g.player.pos=g.trail.data.exit; g.in_combat=false; g.captures.clear()
		var old=g.campaign_progress.duplicate(true); var materials=g.materials
		g.save_blocked=true; assert(not g.finish_route(true))
		assert(g.materials==materials and g.campaign_progress==old and g.mode=="stage")
		g.save_blocked=false; g.interact()
		assert(g.mode=="result" and g.run_success and g.materials==before+reward.materials)
		assert(g.expedition.report.route==R.coordinate(2,stage) and R.contains(g.campaign_progress,R.coordinate(2,stage)))
		var after=g.materials; g.finish(true); assert(g.materials==after)
		total_xp+=reward.xp
	for i in g.owned.size(): assert(g.owned[i]==g.Management.project(identity[i],total_xp))
	assert(g.cleared_stages==[1,2] and g.campaign_progress.cleared.size()==16)
	assert(g.Campaign.accessible(3,g.cleared_stages) and not R.available(R.coordinate(3,1),g.campaign_progress))
	assert(R.normalize(JSON.parse_string(JSON.stringify(g.save_payload()))).cleared.size()==16)
	var next_region=g.overlay.get_children().filter(func(n): return n is Button and n.text=="잊힌 묘역으로")
	assert(next_region.size()==1)
	next_region[0].pressed.emit()
	assert(g.current_stage==3 and g.current_route.is_empty() and g.enemies.size()==30)
	g.show_camp(); g.clear_overlay()
	assert(g.depart_route(R.coordinate(2,1)))
	# The legacy quarry retains its original 30 enemies/1050HP boss and can still be revisited.
	g.show_camp(); g.clear_overlay(); g.map_theme=2; g.open_stage_select()
	g.overlay.find_child("DepartLegacy",true,false).pressed.emit()
	assert(g.current_route.is_empty() and g.current_stage==2 and g.enemies.size()==30 and g.enemies[-1].maxhp==1050)
	# Existing completed quarry saves keep all stages open, with no migration loss.
	var old_progress=R.migrated({"cleared_stages":[1.0,2.0],"unlocked":true})
	for stage in range(1,9): assert(R.available(R.coordinate(2,stage),old_progress))
	print("QUARRY ROUTES PASS: eight stage gates, valley handoff, map callbacks/background, exact main/reserve XP/materials, beast-only bonds, boss warning/collision boundaries, atomic completion retry, legacy graveyard unlock and unchanged quarry revisit")
	g.free(); quit()
