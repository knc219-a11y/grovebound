extends SceneTree
const Game=preload("res://animation/pixel_gameplay_preview.gd")
const Pose=preload("res://animation/druid_pose.gd")
const Attack=preload("res://animation/druid_attack.gd")
var findings=[]
func _initialize(): call_deferred("run")
func run():
	var reports=[]
	for config in [
		{"name":"starter_boar_lv1","kinds":["boar"],"level":1},
		{"name":"starter_boar_lv1_main_only","kinds":["boar"],"level":1,"main_only":true},
		{"name":"balanced_lv2","kinds":["boar","wolf","deer","turtle"],"level":2},
		{"name":"offense_lv2","kinds":["boar","wolf","marten","fox"],"level":2}]:
		var g=Game.new()
		root.add_child(g)
		g.set_process(false)
		g.owned.clear(); g.squad.clear()
		g.loot_rng.seed=10417
		g.rng.seed=10417
		for kind in config.kinds:
			var d=g.make_owned(kind,config.level,{"kind":kind,"level":config.level,"xp":0,"grade":"common","trait":"강인함","options":[]})
			g.squad.append(d.id)
		g.tutorial_done=true
		g.show_camp()
		g.clear_overlay()
		g.start_stage(false)
		var checkpoint=0
		var route=[0,1,3,-1,5,6] if config.get("main_only",false) else [0,1,2,3,-1,4,5,6]
		var elapsed=0.0
		var transitions=[]
		var minimum_hp=g.player.hp
		var downs=0
		var previous_down=0
		var skills=0
		var heals=0
		var buffs=0
		var bonds=0
		var samples=[]
		while g.mode=="stage" and elapsed<480:
			var dt=0.05
			var waypoint=route[mini(checkpoint,route.size()-1)]
			var target=g.Trail.REST if waypoint==-1 else Vector2(2430,850) if waypoint==6 else g.Trail.PACKS[waypoint]
			g.holding_revive=false
			g.stick=(target-g.player.pos).normalized() if g.player.pos.distance_to(target)>(60 if waypoint==-1 else 120) else Vector2.ZERO
			if waypoint==6 and g.player.pos.x<2360: g.stick=Vector2.RIGHT
			if g.in_combat:
				var wounded=g.lowest_ally(g.player.pos,430)
				if not wounded.is_empty() and wounded.hp/wounded.maxhp<0.75 and g.heal_cd<=0:
					g.cast_heal(); heals+=1
				if g.buff_cd<=0: g.cast_buff(); buffs+=1
				for i in g.active_units().size():
					var u=g.units[i]
					if u.hp>0 and u.skill<=0:
						var prior=u.skill
						g.use_companion_skill(i)
						if u.skill>prior: skills+=1
				for u in g.active_units():
					if u.hp<=0:
						g.stick=(u.pos-g.player.pos).normalized() if g.player.pos.distance_to(u.pos)>65 else Vector2.ZERO
						g.holding_revive=g.player.pos.distance_to(u.pos)<=65
						break
				for e in g.enemies:
					if not e.boss or e.hp<=0 or e.wind<=0: continue
					if e.attack_kind=="stomp" and g.player.pos.distance_to(e.aim)<165:
						g.stick=(g.player.pos-e.aim).normalized()
						g.holding_revive=false
					elif e.attack_kind=="charge":
						var closest=Geometry2D.get_closest_point_to_segment(g.player.pos,e.origin,e.aim)
						if g.player.pos.distance_to(closest)<85:
							g.stick=(e.aim-e.origin).normalized().orthogonal()
							g.holding_revive=false
			g.update_game(dt)
			elapsed+=dt
			minimum_hp=minf(minimum_hp,g.player.hp)
			var down=0
			for u in g.active_units():
				if u.hp<=0: down+=1
			downs+=maxi(0,down-previous_down); previous_down=down
			if int(elapsed*20)%200==0: samples.append({"seconds":roundi(elapsed),"x":roundi(g.player.pos.x),"hp":roundi(g.player.hp),"kills":g.kills,"down":down})
			if g.mode!="stage": break
			var done=false
			if waypoint==-1 and g.player.pos.distance_to(g.Trail.REST)<90 and not g.in_combat:
				g.show_trail_rest()
				done=g.menu_page=="trail_rest"
				g.resume_game()
			elif waypoint>=0 and waypoint<6: done=g.trail.cleared_pack(g.enemies,waypoint)
			if done and checkpoint<route.size()-1:
				transitions.append({"point":waypoint,"seconds":roundi(elapsed),"hp":roundi(g.player.hp),"kills":g.kills})
				checkpoint+=1
			# Collect only nearby post-combat opportunities through the real interaction.
			if not g.in_combat and g.closest_capture()>=0:
				var before=g.owned.size()
				g.interact(); g.resume_game()
				bonds+=g.owned.size()-before
		var packs={}
		for e in g.enemies:
			var key="boss" if e.boss else str(e.get("pack",-1))
			if not packs.has(key): packs[key]={"alive":0,"dead":0}
			packs[key]["alive" if e.hp>0 else "dead"]+=1
		var result={"scenario":config,"mode":g.mode,"outcome":g.expedition.report.get("outcome","480s timeout"),"seconds":snappedf(elapsed,0.1),"kills":g.kills,"checkpoint":checkpoint,"minimum_player_hp":snappedf(minimum_hp,0.1),"down_events":downs,"skills":skills,"heals":heals,"buffs":buffs,"bonds":bonds,"core":g.trail.core_progress(g.enemies),"packs":packs,"transitions":transitions,"samples":samples,"growth":g.expedition.report.get("growth",[])}
		g.show_camp()
		result.returned_to_town=g.mode=="camp" and g.enemies.is_empty()
		reports.append(result)
		print("JOURNEY AUDIT ",JSON.stringify(result))
		g.free()
	probe_visual_state()
	var output={"baseline":"f30301241904df812ec0962bbc2cee54401cf564","method":"Synthetic fixed common teams, real update_game at dt=.05, scripted movement/Q/E/skills/revive/boss dodge; not a human or device playtest. No damage/HP/cooldown edits.","runs":reports,"confirmed_probes":findings}
	var file=FileAccess.open("res://docs/audit-2026-10-20-journeys.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"\t")+"\n")
	quit()
func probe_visual_state():
	var g=Game.new(); root.add_child(g); g.set_process(false)
	g.player.face=1
	g.player.action_remaining=0
	g.enemies.clear()
	g.spawn_enemy("boar",g.player.pos-Vector2(100,0),5)
	g.hit_enemy(g.enemies[0],6,g.player.pos,g.player)
	findings.append({"id":"attack_facing","target_left":true,"action_face":g.player.action_face,"confirmed":g.player.action_face==1})
	g.player.walk=false; g.player.pixel_moving=false
	Attack.start(g.player)
	g.show_camp()
	var before=g.player.action_remaining
	for i in 60: g.update_town(1.0/60)
	findings.append({"id":"town_stale_action","key":Pose.active_key(g.player),"remaining_before":before,"remaining_after":g.player.action_remaining,"confirmed":Pose.active_key(g.player)=="attack" and g.player.action_remaining==before})
	var sound=preload("res://animation/combat_audio.gd").new(); root.add_child(sound)
	findings.append({"id":"player_attack_sound","support_cue_accepted":sound.cue("support"),"confirmed":not sound.PROFILES.has("support")})
	sound.free(); g.free()
