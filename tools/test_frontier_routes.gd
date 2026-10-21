extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	g.show_camp(); g.clear_overlay(); g.owned.clear(); g.squad.clear()
	for kind in ["boar","fox","deer","turtle","bat","marten"]:
		var d=g.make_owned(kind,15,{"kind":kind,"level":15,"xp":0,"star":2,"grade":"uncommon","trait":"강인함","options":[]})
		g.squad.append(d.id)
	g.cleared_stages=[1,2,3]; g.unlocked=true; g.campaign_progress=R.migrated({"cleared_stages":[1,2,3]})
	assert(not R.difficulty_unlocked("depth",g.campaign_progress))
	assert(not g.depart_route(R.coordinate(5,1)))
	for kind in ["thornling","shaman","sentinel","cycle_guardian"]:
		assert(not g.Species.can_tame(kind) and not R.habitats(kind).is_empty())
		assert(g.creature_visual.sheets[kind].get_size()==Vector2(448,104))
		g.seen_species.append(kind)
	g.open_collection(); assert(g.overlay.find_child("CreatureCollection",true,false)!=null); g.clear_overlay()
	g.spawn_enemy("shaman",Vector2(700,700),14)
	var caster=g.enemies[-1]; g.player.pos=Vector2(800,700); g.EnemyPatterns.begin(caster,g.player)
	var locked=caster.aim; g.player.pos+=Vector2(0,150); var player_hp=g.player.hp
	g.resolve_enemy_attack(caster); assert(g.player.hp==player_hp and caster.aim==locked and is_equal_approx(caster.wind_total,1.4))
	var identity=g.owned.duplicate(true); var total_xp=0; var rewards=[]
	for theme in [4,5]:
		for stage in range(1,9):
			g.show_camp(); g.clear_overlay(); g.map_theme=theme; g.map_stage=stage; g.open_stage_select()
			for label in g.overlay.get_children():
				if label is Label and label.position==Vector2(930,355):
					assert(label.position.y+g.font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17).y<433,label.text)
			assert(not g.overlay.find_child("DepartRoute",true,false).disabled)
			g.overlay.find_child("DepartRoute",true,false).pressed.emit()
			assert(g.current_stage==theme and g.current_route==R.coordinate(theme,stage))
			var p=R.profile(g.current_route); var before=g.materials; var reward=R.rewards(g.current_route)
			assert(g.stage_background.resource_path==p.background and g.units.size()==6 and g.active_units().size()==4)
			assert(not R.available(R.next(g.current_route),g.campaign_progress))
			for e in g.enemies:
				if e.pack!=8 and not e.boss: g.hit_enemy(e,999999,g.player.pos,g.player)
			assert(g.captures.all(func(c): return g.Species.can_tame(c.kind)))
			for e in g.enemies:
				if not e.boss: continue
				assert(g.trail.begin_boss_intro(g))
				assert(e.maxhp==p.boss_hp)
				for u in g.units: u.pos=e.pos+Vector2(-500,0)
				g.player.pos=e.pos+Vector2(80,0)
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind=="cone")
				var direction=e.cone_direction; var origin=e.origin
				for pos in [origin+direction*(e.tell_radius+1),origin+direction.rotated(e.cone_half_angle+0.01)*100,origin-direction*80]:
					g.player.pos=pos; var hp=g.player.hp; g.resolve_enemy_attack(e); assert(g.player.hp==hp)
				g.player.hp=g.player.maxhp; g.player.pos=origin+direction*80; var hp=g.player.hp
				g.resolve_enemy_attack(e); assert(g.player.hp<hp and e.cone_direction==direction and e.origin==origin)
				g.begin_boss_attack(e,g.player)
				assert(e.attack_kind==("cone" if theme==4 and stage==4 else "slam" if theme==4 else "hex"))
				if e.attack_kind=="hex":
					var aim=e.aim; g.player.hp=g.player.maxhp; g.player.pos=aim+Vector2(e.tell_radius+1,0); hp=g.player.hp
					g.resolve_enemy_attack(e); assert(g.player.hp==hp and e.aim==aim)
				if theme==5 and stage==8:
					g.begin_boss_attack(e,g.player); assert(e.attack_kind=="slam")
					e.hp=e.maxhp*0.4; g.begin_boss_attack(e,g.player); assert(e.attack_kind=="cone" and is_equal_approx(e.wind,1.15))
				g.hit_enemy(e,999999,g.player.pos,g.player)
			assert(g.trail.ready_to_clear(g.enemies))
			g.player.pos=p.exit; g.in_combat=false; g.captures.clear()
			var old=g.campaign_progress.duplicate(true); var materials=g.materials
			g.save_blocked=true; assert(not g.finish_route(true) and g.materials==materials and g.campaign_progress==old)
			g.save_blocked=false; assert(g.finish_route(true))
			assert(g.materials==before+reward.materials and g.cleared_stages==[1,2,3])
			assert(not g.finish_route(true)); total_xp+=reward.xp
			rewards.append({"theme":theme,"stage":stage,"name":p.name,"level":p.level,"xp":reward.xp,"materials":reward.materials})
	for i in g.owned.size(): assert(g.owned[i]==g.Management.project(identity[i],total_xp))
	assert(g.campaign_progress.cleared.size()==40 and R.difficulty_unlocked("depth",g.campaign_progress) and not R.difficulty_unlocked("challenge",g.campaign_progress))
	var roundtrip=R.normalize(JSON.parse_string(JSON.stringify(g.save_payload())))
	assert(roundtrip==g.campaign_progress and R.difficulty_unlocked("depth",roundtrip))
	var unlock=g.overlay.get_children().filter(func(n): return n is Button and n.text=="심층 해금 · 지도")
	assert(unlock.size()==1); unlock[0].pressed.emit()
	assert(g.mode=="camp" and g.map_difficulty=="depth" and g.overlay.find_child("Difficulty_depth",true,false).text.contains("해금/준비 중"))
	assert(not g.depart_route(R.coordinate(1,1,"depth")))
	var f=FileAccess.open("res://docs/frontier-route-rewards.json",FileAccess.WRITE); f.store_string(JSON.stringify(rewards,"\t")+"\n"); f.close()
	print("FRONTIER ROUTES PASS: sixteen sequential gates, unique backgrounds, six companion exact rewards, cone radius/angle/frozen direction and damage, delayed targets, three-pattern final boss, atomic completion, normal ending and persistent depth unlock")
	g.free(); quit()
