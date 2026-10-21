extends SceneTree
# Prepared 2/2/3/2-star parties; no production save is read or written.
const Game=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("run")
func run():
	var rows=[]
	var args=OS.get_cmdline_user_args()
	for kinds in [["boar","fox","wolf","deer"],["boar","marten","wolf","bat"]]:
		for scenario in ["mixed","three","four_boar","four_fox"]:
			if scenario=="four_fox" and "fox" not in kinds: continue
			for level in ([24,30,40] if "--hero-max" in args else [24,30]):
				for assisted in [false,true]:
					for theme in [4,5]:
						var g=Game.new(); root.add_child(g); g.set_process(false)
						g.show_camp(); g.clear_overlay(); g.owned.clear(); g.squad.clear(); g.campaign_progress={"version":1,"cleared":[]}
						g.rng.seed=10417; g.loot_rng.seed=10417
						for i in 4:
							var d=g.make_owned(kinds[i],level,{"kind":kinds[i],"level":level,"xp":0,"star":(3 if i==2 else 2) if scenario=="mixed" else 3,"trait":"강인함","options":[]})
							if scenario=="four_"+kinds[i]:
								d.star=4; d.level=15; d.grade="special"
								d.special={"version":1,"state":"ready","element":"earth" if i==0 else "fire","unique":"guard" if i==0 else "potency","affixes":[{"key":"skill_haste","value":8},{"key":"power","value":6}]}
							g.squad.append(d.id)
						if "--hero-max" in args:
							g.hero.level=30
							for key in g.Hero.SKILLS: g.hero.skills[key]=5
							for pair in [["grove_staff","weapon"],["guardian_robe","armor"],["wind_charm","charm1"],["stream_charm","charm2"]]:
								var item=g.Hero.add_item(g.hero,pair[0]); item.enhance=5; g.hero.equipped[pair[1]]=item.id
							g.sync_hero()
						g.start_stage(false,theme,R.coordinate(theme,8)); g.clear_overlay()
						# Boss arena only: previous packs are marked clear without granting XP/rewards.
						for e in g.enemies:
							if not e.boss: e.hp=0
						g.player.pos=g.trail.points[-1]+Vector2(-200,0)
						for i in 4: g.units[i].pos=g.player.pos+Vector2(i*25,35)
						if "--baseline" in args:
							for e in g.enemies:
								if e.boss:
									e.hp=R.Frontier.STAGES["%d:8" % theme].boss_hp; e.maxhp=e.hp
									e.boss_damage=30.0 if theme==4 else 34.0; e.boss_pressure=false; e.cycle_guard=false
						g.trail.begin_boss_intro(g)
						var elapsed=0.0; var low=g.player.hp; var downs=0; var previous_down=0; var skills=0; var heals=0
						while g.mode=="stage" and elapsed<180 and g.enemies.any(func(e): return e.boss and e.hp>0):
							g.stick=Vector2.ZERO; g.holding_revive=false
							if assisted:
								var boss=g.enemies.filter(func(e): return e.boss)[0]
								if g.player.pos.distance_to(boss.pos)>230: g.stick=(boss.pos-g.player.pos).normalized()
								if g.heal_cd<=0:
									var wounded=g.lowest_ally(g.player.pos,430)
									if not wounded.is_empty() and wounded.hp/wounded.maxhp<0.8: g.cast_heal(); heals+=1
								if g.buff_cd<=0: g.cast_buff()
								if "--hero-max" in args: g.cast_barrier()
								for i in 4:
									if g.units[i].hp>0 and g.units[i].skill<=0:
										g.use_companion_skill(i)
										if g.units[i].skill>0: skills+=1
								var down=g.closest_down()
								g.holding_revive=down>=0
								for e in g.enemies:
									if e.hp<=0 or e.wind<=0: continue
									if e.attack_kind=="cone" and g.EnemyPatterns.contains(e,g.player.pos): g.stick=e.cone_direction.orthogonal(); g.holding_revive=false
									elif e.attack_kind in ["slam","hex"]:
										for aim in [e.aim]+e.get("extra_aims",[]):
											if g.player.pos.distance_to(aim)<e.tell_radius+35:
												g.stick=(g.player.pos-aim).normalized(); g.holding_revive=false
												if g.stick.length()<0.1: g.stick=Vector2.LEFT
							g.update_game(0.05); elapsed+=0.05; low=minf(low,g.player.hp)
							var down_count=g.active_units().filter(func(u): return u.hp<=0).size()
							downs+=maxi(0,down_count-previous_down); previous_down=down_count
						var won=g.enemies.all(func(e): return not e.boss or e.hp<=0)
						var row={"hero_max":"--hero-max" in args,"party":kinds,"scenario":scenario,"stars":g.owned.map(func(d): return d.star),"level":level,"theme":theme,"assisted":assisted,"win":won,"seconds":snappedf(elapsed,0.1),"minimum_player_hp":snappedf(low,0.1),"downs":downs,"skills":skills,"heals":heals,"ally_hp":g.units.map(func(u): return snappedf(u.hp/u.maxhp,0.01))}
						rows.append(row); print("PRESSURE ",JSON.stringify(row)); g.free()
	var out=args[args.find("--out")+1] if "--out" in args else "res://docs/normal-pressure-after.json"
	var f=FileAccess.open(out,FileAccess.WRITE); f.store_string(JSON.stringify({"configuration":"original boss settings" if "--baseline" in args else "adjusted boss settings","hero_configuration":"Lv30, all hero skills rank5, grove staff/guardian robe/wind charm/stream charm all +5" if "--hero-max" in args else "Lv1, no equipment, starting skills", "method":"Prepared mixed 2/2/3/2 or all-3-star parties at Lv24/30 (also Lv40 with --hero-max; normalized to each star cap), or one 4-star Lv15 boar/fox with 3-star Lv24/30 allies; isolated final boss arenas; passive=no movement/support/skills, assisted=Q/E/skills/revive and fixed-tell avoidance; deterministic not human success rate","runs":rows},"\t")+"\n"); f.close()
	var assisted=rows.filter(func(r): return r.assisted)
	var passive=rows.filter(func(r): return not r.assisted)
	var final_four=rows.filter(func(r): return r.theme==5 and r.assisted and r.scenario.begins_with("four_"))
	var final_mixed=rows.filter(func(r): return r.theme==5 and r.assisted and r.scenario=="mixed")
	var passed=not final_four.is_empty() and final_four.all(func(r): return r.win) and final_mixed.all(func(r): return not r.win) and rows.filter(func(r): return r.theme==5 and r.scenario=="three").all(func(r): return not r.win)
	print("PRESSURE ","PASS" if passed else "COMPLETE",": ",rows.size()," scenarios, assisted ",assisted.filter(func(r): return r.win).size(),"/",assisted.size(),", passive ",passive.filter(func(r): return r.win).size(),"/",passive.size())
	quit(1 if "--check" in args and not passed else 0)
