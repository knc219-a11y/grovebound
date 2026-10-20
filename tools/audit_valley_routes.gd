extends SceneTree
const Game=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("run")
func run():
	var runs=[]
	for starter in ["boar","marten","fox"]:
		for seed_value in [10417,20261020]:
			var g=Game.new(); root.add_child(g); g.set_process(false)
			g.owned.clear(); g.squad.clear(); g.discovered.clear(); g.cleared_stages.clear(); g.unlocked=false
			g.campaign_progress={"version":1,"cleared":[]}
			g.rng.seed=seed_value; g.loot_rng.seed=seed_value
			# Real first-invitation/practice functions. Only tutorial combat is fast-forwarded.
			g.tutorial_done=false; g.tutorial_species=starter; g.start_stage(true)
			g.hit_enemy(g.enemies[0],999999,g.player.pos,g.player)
			g.player.pos=g.captures[0].pos; g.in_combat=false; g.interact(); g.resume_game()
			g.start_practice(); g.hit_enemy(g.enemies[-1],999999,g.player.pos,g.player)
			g.update_hud(); g.resume_game(); g.expedition.clear(); g.tutorial_done=true
			for stage in range(1,9):
				g.show_camp(); g.clear_overlay()
				if not g.depart_route(R.coordinate(1,stage)):
					runs.append({"starter":starter,"seed":seed_value,"stage":stage,"success":false,"reason":"departure blocked"})
					break
				var elapsed=0.0; var minimum=g.player.hp; var casts=0; var heals=0; var downs=0; var old_down=0; var bonds=0
				var baseline=g.owned.duplicate(true)
				while g.mode=="stage" and elapsed<420:
					var target=g.trail.next_stop(g.enemies).pos
					var distance=g.player.pos.distance_to(target)
					g.stick=(target-g.player.pos).normalized() if distance>(55 if g.trail.ready_to_clear(g.enemies) else 105) else Vector2.ZERO
					g.holding_revive=false
					if g.in_combat:
						var wounded=g.lowest_ally(g.player.pos,430)
						if not wounded.is_empty() and wounded.hp/wounded.maxhp<0.75 and g.heal_cd<=0: g.cast_heal(); heals+=1
						if g.buff_cd<=0: g.cast_buff()
						for i in g.active_units().size():
							var u=g.units[i]
							if u.hp>0 and u.skill<=0:
								g.use_companion_skill(i)
								if u.skill>0: casts+=1
						for u in g.active_units():
							if u.hp<=0:
								g.stick=(u.pos-g.player.pos).normalized() if g.player.pos.distance_to(u.pos)>65 else Vector2.ZERO
								g.holding_revive=g.player.pos.distance_to(u.pos)<=65
								break
						for e in g.enemies:
							if not e.boss or e.hp<=0 or e.wind<=0: continue
							if e.attack_kind=="stomp" and g.player.pos.distance_to(e.aim)<165:
								g.stick=(g.player.pos-e.aim).normalized(); g.holding_revive=false
							elif e.attack_kind=="charge":
								var near=Geometry2D.get_closest_point_to_segment(g.player.pos,e.origin,e.aim)
								if g.player.pos.distance_to(near)<85: g.stick=(e.aim-e.origin).normalized().orthogonal(); g.holding_revive=false
					g.update_game(0.05); elapsed+=0.05
					minimum=minf(minimum,g.player.hp)
					var down=g.active_units().filter(func(u): return u.hp<=0).size()
					downs+=maxi(0,down-old_down); old_down=down
					if g.mode!="stage": break
					# Real nearby bonds are collected; no injected companions or training materials.
					if not g.in_combat and g.closest_capture()>=0:
						var before=g.owned.size(); g.interact(); g.resume_game(); bonds+=g.owned.size()-before
					if g.route_can_exit(): g.interact()
				var result={"starter":starter,"seed":seed_value,"stage":stage,"success":g.mode=="result" and g.run_success,"seconds":snappedf(elapsed,0.1),"minimum_hp":snappedf(minimum,0.1),"down_events":downs,"skills":casts,"heals":heals,"bonds":bonds,"kills":g.kills,"before":baseline,"after":g.owned.duplicate(true),"report":g.expedition.report.duplicate(true),"progress":g.trail.core_progress(g.enemies)}
				runs.append(result)
				print("VALLEY JOURNEY ",starter," ",seed_value," 1-",stage," ",result.success," ",result.seconds,"s")
				if not result.success: break
			g.free()
	var output={"method":"Six deterministic first-invitation-to-1-8 runs; tutorial enemy kills fast-forwarded, then real update_game dt=.05, real nearby bonds/Q/E/skills/revive/dodge/exit. No synthetic high-level team or material training. Bot timing is not human clear time or success rate.","runs":runs}
	var f=FileAccess.open("res://docs/campaign-map-journeys.json",FileAccess.WRITE); f.store_string(JSON.stringify(output,"\t")+"\n"); f.close()
	var passed=runs.size()==48 and runs.all(func(r): return r.success)
	print("VALLEY JOURNEY ","PASS" if passed else "FAIL"," ",runs.filter(func(r): return r.success).size(),"/48")
	quit(0 if passed else 1)
