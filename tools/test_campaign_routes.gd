extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
const Main=preload("res://main.gd")
func _initialize(): call_deferred("check")
func click(g,name):
	var b=g.overlay.find_child(name,true,false)
	assert(b is Button and not b.disabled,name)
	b.pressed.emit()
func check():
	assert(R.THEMES.size()==5 and R.DIFFICULTIES.size()==3 and R.VALLEY.size()==8)
	assert(R.migrated({"unlocked":true}).cleared.size()==8)
	assert(R.migrated({"cleared_stages":[1.0,2.0,3.0]}).cleared.size()==24)
	assert(R.migrated({"cleared_stages":[3,2]}).cleared.is_empty())
	var legacy={"cleared_stages":[1,2],"unlocked":true}
	var progress=R.migrated(legacy)
	assert(R.normalize({"campaign_progress":JSON.parse_string(JSON.stringify(progress))})==progress)
	assert(R.normalize({"campaign_progress":{"version":1,"cleared":[R.coordinate(1,3),R.coordinate(2,1),R.coordinate(1,1,"depth")]}}).cleared.is_empty())
	assert(R.available(R.coordinate(2,1),progress) and not R.available(R.coordinate(1,1,"depth"),progress))
	assert(not R.available(R.coordinate(2,1),{"version":1,"cleared":[]}) and not R.available(R.coordinate(3,1),progress))
	assert(not R.valid({"difficulty":"normal","theme":true,"stage":1}) and not R.valid(R.coordinate(1,9)))
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	g.expedition.clear(); g.show_camp(); g.clear_overlay()
	g.campaign_progress={"version":1,"cleared":[]}; g.cleared_stages=[]; g.unlocked=false
	g.map_theme=0; g.map_difficulty="normal"; g.open_stage_select()
	assert(g.overlay.has_node("ExplorationMap"))
	check_details_fit(g)
	click(g,"Theme_1")
	assert(g.map_theme==1 and g.overlay.find_child("Stage_8",true,false)!=null)
	click(g,"Stage_8")
	check_details_fit(g)
	assert(g.mode=="camp" and g.overlay.find_child("DepartRoute",true,false).disabled)
	click(g,"Stage_1")
	click(g,"DepartRoute")
	assert(g.mode=="stage" and g.current_route==R.coordinate(1,1))
	assert(not g.depart_route(R.coordinate(1,2)))
	# Each stage has a distinct route and exact reward ledger, including reserve XP.
	g.owned.clear(); g.squad.clear()
	for kind in ["boar","fox","deer","turtle","wolf","marten"]:
		var d=g.make_owned(kind,1,{"kind":kind,"level":1,"xp":0,"star":1,"grade":"common","trait":"강인함","options":[]})
		g.squad.append(d.id)
	var initial=g.owned.duplicate(true)
	var total_xp=0
	for stage in range(1,9):
		g.show_camp(); g.clear_overlay()
		assert(g.depart_route(R.coordinate(1,stage)))
		assert(g.units.size()==6 and g.active_units().size()==4)
		assert(not g.finish_route(true))
		var before=g.materials
		var reward=R.rewards(g.current_route)
		for e in g.enemies:
			if e.boss:
				assert(not g.trail.engageable(e))
				assert(not g.trail.begin_boss_intro(g))
				assert(g.trail.ready_to_clear(g.enemies)==false)
		for e in g.enemies:
			if not e.boss and e.pack!=8: g.hit_enemy(e,999999,g.player.pos,g.player)
		for e in g.enemies:
			if e.boss:
				assert(g.trail.begin_boss_intro(g))
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind=="stomp")
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind==("stomp" if stage==4 else "charge"))
				g.hit_enemy(e,999999,g.player.pos,g.player)
		assert(g.trail.ready_to_clear(g.enemies))
		assert(g.enemies.filter(func(e): return e.pack==8 and e.hp>0).size()==2)
		g.player.pos=g.trail.data.exit; g.in_combat=false
		# Completion writes the clear bonus and coordinate together; failed writes mutate neither.
		g.save_blocked=true
		var old_progress=g.campaign_progress.duplicate(true)
		var old_materials=g.materials
		assert(not g.finish_route(true))
		assert(g.mode=="stage" and g.campaign_progress==old_progress and g.materials==old_materials)
		g.save_blocked=false
		g.captures.clear(); g.interact()
		assert(g.mode=="result" and g.run_success and g.materials==before+reward.materials)
		assert(R.contains(g.campaign_progress,R.coordinate(1,stage)))
		var after=g.materials
		g.finish(true); g.interact()
		assert(g.materials==after)
		total_xp+=reward.xp
		assert(g.expedition.report.route==R.coordinate(1,stage))
		assert(g.expedition.report.growth.size()==6)
	for i in g.owned.size():
		var expected=g.Management.project(initial[i],total_xp)
		assert(g.owned[i]==expected,"Reserve and active growth must match exact ledger")
	assert(g.cleared_stages==[1] and g.unlocked and g.campaign_progress.cleared.size()==8)
	g.show_camp(); g.clear_overlay(); g.map_theme=2; g.open_stage_select(); click(g,"DepartLegacy")
	assert(g.current_stage==2 and g.current_route.is_empty() and g.enemies.size()==30)
	# Real file migration/roundtrip on a workspace-only unique fixture.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa-data"))
	var path="res://.qa-data/route-"+str(Time.get_ticks_usec())+".json"
	var old={"version":2,"owned":initial,"squad":g.squad,"next_id":g.next_id,"materials":47,"tutorial_done":true,"discovered":g.discovered,"cleared_stages":[1,2],"unlocked":true}
	var original=JSON.stringify(old)
	var f=FileAccess.open(path,FileAccess.WRITE); f.store_string(original); f.close()
	var saved=Main.new(); saved.save_path=path; saved.load_game()
	assert(saved.campaign_progress.cleared.size()==16 and saved.materials==47)
	assert(FileAccess.get_file_as_string(saved.save_backup_path)==original)
	var identity=JSON.stringify(saved.owned)
	var squad=saved.squad.duplicate()
	assert(saved.save_game())
	saved.campaign_progress.clear(); saved.owned.clear(); saved.load_game()
	assert(saved.campaign_progress.cleared.size()==16 and JSON.stringify(saved.owned)==identity and saved.squad==squad)
	var backup=saved.save_backup_path
	saved.load_game(); assert(saved.save_backup_path==backup)
	# Future progress versions must never be silently rewritten.
	old.campaign_progress={"version":99,"cleared":[]}
	f=FileAccess.open(path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var future=Main.new(); future.save_path=path; future.load_game()
	assert(future.save_blocked and not future.save_game())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
	future.free(); saved.free(); g.free()
	print("CAMPAIGN ROUTES PASS: 5x8x3 identifiers, map callbacks, locked/unimplemented gates, eight exact reward ledgers and reserve XP, middle/theme bosses, explicit exit, failed-write rollback, duplicate completion, legacy backup/migration/idempotence and future-save protection")
	quit()
func check_details_fit(g):
	for n in g.overlay.get_children():
		if n is Label and n.position.x>=930:
			var width=g.font.get_multiline_string_size(n.text,HORIZONTAL_ALIGNMENT_LEFT,-1,n.get_theme_font_size("font_size")).x
			assert(width<=265,"Map detail overflows its panel: "+n.text)
