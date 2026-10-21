extends SceneTree
const Main=preload("res://main.gd")
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Manager=preload("res://companion_management.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("check")
func check():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa-data"))
	var path="res://.qa-data/review-"+str(Time.get_ticks_usec())+".json"
	var g=Main.new(); g.save_path=path; root.add_child(g); g.set_process(false)
	g.show_camp(); g.clear_overlay(); g.owned.clear(); g.squad.clear(); g.materials=2000
	var a=g.make_owned("boar",19); var b=g.make_owned("fox",3); var c=g.make_owned("deer",2)
	g.squad=[a.id]; a.favorite=true; a.legacy_options=true; a.options=[{"key":"power","value":7}]
	assert(g.save_game())
	var snapshot=g.save_payload().duplicate(true); var bytes=FileAccess.get_file_as_bytes(path)
	g.save_path="res://.qa-data/nonexistent-review-dir/invalid.json"
	assert(not g.train_companion(a.id))
	assert(not g.train_to_level(a.id,20,a.duplicate(true)))
	assert(not g.release_companion(b.id))
	g.bulk_selection=[b.id,c.id]
	assert(not g.commit_bulk_release(g.bulk_selection.duplicate()))
	assert(g.bulk_selection==[b.id,c.id] and g.save_payload()==snapshot and FileAccess.get_file_as_bytes(path)==bytes)
	g.save_blocked=true; g.save_path=path
	assert(not g.train_companion(a.id) and g.save_payload()==snapshot)
	g.save_blocked=false
	assert(g.train_to_level(a.id,20,a.duplicate(true)) and a.level==20 and a.xp==0 and g.materials==1949)
	var capped=a.duplicate(true); var original=FileAccess.get_file_as_bytes(path)
	g.save_path="res://.qa-data/nonexistent-review-dir/invalid.json"
	assert(not g.promote_companion(a.id,capped) and a==capped and FileAccess.get_file_as_bytes(path)==original)
	g.save_path=path
	assert(g.promote_companion(a.id,capped) and a.star==2 and a.level==1 and a.xp==0)
	assert(a.favorite and a.options==capped.options and a.id==capped.id and a.trait==capped.trait and g.squad==[a.id])
	assert(not g.promote_companion(a.id,capped))
	var trained=a.duplicate(true)
	assert(g.train_companion(a.id) and a==Manager.project(trained,40))
	var reward=Manager.farewell_reward(b)+Manager.farewell_reward(c); var materials=g.materials
	assert(g.commit_bulk_release([b.id,b.id,c.id]) and g.materials==materials+reward and g.owned.size()==1)
	assert(not g.commit_bulk_release([b.id,c.id]))
	var disk=Main.new(); disk.save_path=path; disk.load_game()
	assert(disk.owned==g.owned and disk.squad==g.squad and disk.materials==g.materials); disk.free()
	for star in [1,2,3,4,5,6]:
		var d={"kind":"boar","level":g.Loot.MAX_LEVELS[star]-1,"xp":3,"star":star,"trait":"강인함","options":[]}
		if star>=4: continue # Special metadata is validated by the existing evolution checks.
		var plan=Manager.target_plan(d,g.Loot.MAX_LEVELS[star])
		assert(plan.after==Manager.project(d,plan.xp) and plan.after.xp==0)
	# Menu reads all normal coordinates, not the legacy three-region compatibility list.
	g.campaign_progress={"version":1,"cleared":[]}
	for theme in range(1,6):
		for stage in range(1,9): g.campaign_progress=R.completed(g.campaign_progress,R.coordinate(theme,stage))
	g.open_game_menu()
	assert(g.overlay.get_children().any(func(n): return n is Label and n.text.contains("일반 탐험 40/40")))
	g.free(); DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Both ordinary and enhanced turtle preserve tells, origins, cones and charge paths.
	var v=Preview.new(); root.add_child(v); v.set_process(false)
	for special in [false,true]:
		v.show_camp(); v.clear_overlay(); v.owned.clear(); v.squad.clear()
		var d=v.make_owned("turtle",5)
		if special:
			d.star=4; d.special={"version":1,"state":"ready","element":"earth","unique":"vital","affixes":[]}
		v.squad=[d.id]; v.start_stage(false); v.clear_overlay(); v.enemies.clear()
		v.units[0].pos=Vector2(700,700); v.player.pos=Vector2(800,700)
		for kind in ["shaman","wraith","golem","thornling","boar"]:
			v.spawn_enemy(kind,Vector2(700,800),12,kind=="boar")
			var e=v.enemies[-1]
			if kind=="boar": e.pattern=1; v.begin_boss_attack(e,v.player)
			else: v.EnemyPatterns.begin(e,v.player)
			var aim=e.aim; var pos=e.pos; var origin=e.get("origin",Vector2.ZERO); var direction=e.get("cone_direction",Vector2.ZERO)
			v.units[0].skill=0; v.use_companion_skill(0)
			assert(e.aim==aim and e.pos==pos and e.get("origin",Vector2.ZERO)==origin and e.get("cone_direction",Vector2.ZERO)==direction)
			if kind=="boar":
				v.resolve_enemy_attack(e); v.units[0].skill=0; v.use_companion_skill(0)
				assert(e.aim==aim and e.pos==pos and e.dash>0)
	v.free()
	print("REVIEW FIXES PASS: real disk failure/blocked save rollback, retry and stale guards, exact consumption/identity, cap XP equivalence, 40-stage menu, ordinary/special taunt frozen tells and charge paths")
	quit()
