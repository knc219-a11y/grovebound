extends SceneTree
const Fixture=preload("res://animation/roster_layout_review.gd")
const Main=preload("res://main.gd")
var checks=0
var errors=[]
func check(ok,message):
	checks+=1
	if not ok: errors.append(message)
func _init(): call_deferred("run")
func text_of(node):
	var result=node.text+"\n" if node is Label or node is Button else ""
	for child in node.get_children(): result+=text_of(child)
	return result
func option_nodes(node):
	var result=[]
	if node is Label and node.text.begins_with("옵션:"): result.append(node)
	for child in node.get_children(): result.append_array(option_nodes(child))
	return result
func check_options(label,caption):
	check(label.text.contains("동료 스킬 대기시간 감소 +12%") and label.text.contains("기절 대상 추가 피해 +24%") and label.text.contains("주는 회복량 +16%") and label.text.contains("받는 피해 감소 +9%") and label.text.ends_with("최대 체력 +14%"),caption+" all five options including last")
	check(label.size.x>=840 and label.size.y>=44,caption+" full option rectangle")
	check(not label.clip_text and label.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART,caption+" smart wrap instead of clipping")
	check(label.get_line_count()<=2 and label.get_visible_line_count()>=label.get_line_count(),caption+" at most two fully visible lines")
	check(label.get_line_count()*label.get_line_height()<=label.size.y,caption+" text height fits allocated rectangle")
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa-data"))
	var path="res://.qa-data/feedback-qa-"+str(Time.get_ticks_usec())+".json"
	var g=Main.new()
	g.save_path=path
	root.add_child(g)
	g.set_process(false)
	Fixture.populate(g)
	g.open_roster()
	await process_frame
	var original=g.squad.duplicate()
	var owned=g.owned.duplicate(true)
	var materials=g.materials
	var random_state=g.rng.state
	var loot_state=g.loot_rng.state
	var first=original[0]
	var second=original[1]
	g.roster_select(first)
	g.roster_select(second)
	check(g.squad==original and g.roster_selected_id==second,"D1 different left cards only select")
	g.show_training(second)
	g.open_roster()
	check(g.roster_selected_id==-1 and g.roster_click.is_empty(),"D1 training return clears intent")
	g.roster_select(first)
	g.roster_click.time=Time.get_ticks_msec()-451
	g.roster_select(first)
	check(g.squad==original,"D4 expired second click does not remove")
	g.roster_click.clear()
	g.roster_select(first)
	g.roster_select(first)
	check(g.squad.size()==5 and not g.squad.has(first),"D4 left double removes one ID")
	var after_remove=g.squad.duplicate()
	g.roster_select(after_remove[0])
	check(g.squad==after_remove,"D4 third press after list shift cannot chain remove")
	g.roster_click.clear()
	g.roster_select(first)
	g.roster_select(first)
	check(g.squad.size()==6 and g.squad[-1]==first,"D4 left double adds stored ID")
	g.roster_click.clear()
	g.roster_selected_id=-1
	var right=g.squad[0]
	g.roster_assign(0)
	g.roster_assign(0)
	check(g.squad.size()==5 and not g.squad.has(right),"D4 right double removes its ID")
	g.squad=original.duplicate()
	g.roster_click.clear()
	g.roster_selected_id=-1
	var spare=g.owned[10].id
	g.roster_select(spare)
	g.roster_select(spare)
	check(g.squad==original,"D4 full party refuses double-add")
	g.roster_click.clear()
	g.roster_select(first)
	g.reset_roster_filters()
	g.roster_select(first)
	check(g.squad==original,"D4 reset filters cancels pending double click")
	g.squad=original.duplicate()
	g.roster_click.clear()
	g.roster_selected_id=-1
	check(g.save_game(),"baseline actual save")
	var baseline=FileAccess.get_file_as_string(path)
	g.save_path="res://.qa-data/no-feedback-directory/file.json"
	g.roster_select(first)
	g.roster_select(first)
	check(g.squad==original and FileAccess.get_file_as_string(path)==baseline,"D4 actual failed removal preserves state/file")
	g.roster_click.clear()
	g.squad=original.slice(0,5)
	var reduced=g.squad.duplicate()
	g.roster_select(original[5])
	g.roster_select(original[5])
	check(g.squad==reduced,"D4 actual failed add preserves state")
	g.save_path=path
	g.squad=original.duplicate()
	g.mode="stage"
	g.in_combat=false
	g.units.clear()
	for id in g.squad: g.units.append(g.make_unit(g.find_owned(id),Vector2(600,600)))
	g.roster_click.clear()
	g.roster_select(first)
	g.roster_select(first)
	check(g.squad==original,"D4 stage left double refuses remove")
	g.roster_click.clear()
	g.roster_selected_id=-1
	g.roster_assign(0)
	g.roster_assign(0)
	check(g.squad==original,"D4 stage right double refuses remove")
	g.in_combat=true
	g.roster_click.clear()
	g.roster_select(first)
	g.roster_assign(1)
	check(g.squad==original and g.roster_click.is_empty(),"D4 combat disallows manipulation")
	g.mode="camp"
	g.in_combat=false
	g.roster_selected_id=-1
	g.roster_click.clear()
	g.roster_select(first)
	g.roster_assign(1)
	check(g.squad[1]==first and g.squad[0]==second,"D4 explicit destination swapping retained")
	g.squad=original.duplicate()
	# Swapping an ID to another slot must not make the next click a double remove.
	g.roster_click.clear()
	g.roster_selected_id=-1
	for cycle in 2:
		g.roster_assign(0)
		g.roster_assign(4)
		check(g.squad.size()==6 and g.roster_selected_id==-1,"D4 consecutive slot swaps preserve capacity %d" % cycle)
	check(g.squad==original,"D4 repeated slot swap returns original IDs")
	for value in [null,"invalid",123,{},[],false]: check(g.Formation.normalize(value)=="surround","S1 malformed formation "+str(value))
	for formation in g.Formation.KEYS:
		check(g.set_party_formation(formation),"S1 formation commits "+formation)
		var saved=JSON.parse_string(FileAccess.get_file_as_string(path))
		check(saved.party_formation==formation,"S1 actual JSON stores "+formation)
		g.party_formation="invalid"
		g.load_game()
		check(g.party_formation==formation,"S1 load restores "+formation)
	var payload=g.save_payload().duplicate(true)
	payload.erase("party_formation")
	check(g.persist_payload(payload),"S1 old payload written")
	g.party_formation="front"
	g.load_game()
	check(g.party_formation=="surround","S1 legacy missing formation defaults surround")
	payload.party_formation={"bad":true}
	check(g.persist_payload(payload),"S1 invalid payload written")
	g.load_game()
	check(g.party_formation=="surround","S1 invalid loaded formation defaults surround")
	g.set_party_formation("front")
	var stable=g.save_payload().duplicate(true)
	var file_before=FileAccess.get_file_as_string(path)
	g.save_path="res://.qa-data/no-feedback-directory/file.json"
	check(not g.set_party_formation("rear") and g.party_formation=="front","S2 actual formation write failure preserves memory")
	check(g.Special.equivalent(g.save_payload(),stable) and FileAccess.get_file_as_string(path)==file_before,"S2 failed formation preserves entire payload/file")
	g.save_path=path
	g.save_blocked=true
	check(not g.set_party_formation("rear") and g.party_formation=="front","S2 blocked formation preserves state")
	g.save_blocked=false
	g.mode="stage"
	g.in_combat=true
	check(not g.set_party_formation("rear") and g.party_formation=="front","S2 combat formation change refused")
	g.mode="camp"
	g.in_combat=false
	g.player.pos=Vector2(1000,700)
	g.units.clear()
	for kind in ["fox","deer","boar","turtle"]:
		var d=g.owned.filter(func(record): return record.kind==kind)[0]
		g.units.append(g.make_unit(d,g.player.pos))
	for forward in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,-1).normalized()]:
		g.formation_forward=forward
		for formation in g.Formation.KEYS:
			g.party_formation=formation
			var anchors=[]
			for i in 4:
				var anchor=g.formation_anchor(i)
				anchors.append(anchor)
				check(Rect2(170,345,2570,785).has_point(anchor),"D9 anchor inside world")
				var dot=(anchor-g.player.pos).dot(forward)
				if formation=="front": check(dot>0,"D9 front positive forward")
				if formation=="rear": check(dot<0,"D9 rear negative forward")
			if formation=="front": check((anchors[3]-g.player.pos).dot(forward)>=(anchors[0]-g.player.pos).dot(forward),"D8 turtle gets forward rank")
	for position in [Vector2(170,345),Vector2(2740,1130)]:
		g.player.pos=position
		for formation in g.Formation.KEYS:
			g.party_formation=formation
			for i in 4:
				var anchor=g.formation_anchor(i)
				check(anchor.x>=170 and anchor.y>=345 and anchor.x<=2740 and anchor.y<=1130,"D9 anchor clamps world edge")
	check(g.Special.equivalent(g.owned,owned) and g.materials==materials and g.rng.state==random_state and g.loot_rng.state==loot_state,"D1-D9 controls never alter identities resources RNG")
	# Exact same-species identities remain distinguishable through confirmation.
	g.owned.clear()
	g.squad.clear()
	g.units.clear()
	g.mode="camp"
	for i in 3:
		var raw=g.Loot.roll("boar",40,g.loot_rng,3)
		var d=g.Loot.roll_special(raw,"boar",g.loot_rng)
		d.level=50
		d.special.state="ready"
		d.special.element=["earth","water","wind"][i]
		d.special.unique="guard"
		d.favorite=false
		d.options=[{"key":"skill_haste","value":12},{"key":"stun_hunter","value":24},{"key":"healing","value":16}]
		d.legacy_options=true
		d.special.affixes=[{"key":"armor","value":9},{"key":"vitality","value":14}]
		check(g.Loot.all_options(d).size()==5,"D6 maximum fixture has exactly3 legacy+2 special options")
		g.make_owned("boar",50,d)
	var main_id=g.owned[0].id
	var support_id=g.owned[1].id
	var other_id=g.owned[2].id
	g.squad=[main_id]
	g.EvolutionUI.show_page(g,main_id)
	await process_frame
	await process_frame
	var support_button=g.overlay.find_child("EvolutionSupport_"+str(support_id),true,false)
	var other_button=g.overlay.find_child("EvolutionSupport_"+str(other_id),true,false)
	check(support_button!=null and other_button!=null,"D6 duplicate species have distinct buttons")
	check(text_of(support_button).contains("#"+str(support_id)) and text_of(support_button).contains("물"),"D6 row displays selected identity and element")
	check(text_of(other_button).contains("#"+str(other_id)) and text_of(other_button).contains("바람"),"D6 same species second identity visible")
	var row_options=option_nodes(support_button)
	check(row_options.size()==1,"D6 one option label per material row")
	check_options(row_options[0],"D6 row")
	check(row_options[0].position.y+row_options[0].size.y<=112 and 112+22<=support_button.size.y,"D6 row option/action areas do not overlap")
	support_button.pressed.emit()
	await process_frame
	await process_frame
	var confirmation_options=option_nodes(g.overlay)
	check(confirmation_options.size()==2,"D6 confirmation shows both main and support options")
	for i in confirmation_options.size(): check_options(confirmation_options[i],"D6 confirmation %d" % i)
	check(confirmation_options[0].get_global_rect().end.y<=g.overlay.find_child("EvolutionConsume",true,false).get_global_rect().position.y,"D6 main options end before consume heading")
	check(confirmation_options[1].get_global_rect().end.y<=g.overlay.find_child("EvolutionResult",true,false).get_global_rect().position.y,"D6 support options end before result heading")
	check(g.overlay.find_child("ConfirmEvolution",true,false).text.begins_with("#%d 소비" % support_id),"D6 final action names selected support ID")
	var plan=g.Evolution.preview(g.owned,g.squad,main_id,support_id)
	var identity=g.owned[0].duplicate(true)
	check(g.commit_evolution(main_id,support_id,plan.materials),"G2 actual new evolution commit")
	var pending=g.find_owned(main_id).duplicate(true)
	check(pending.level==1 and pending.xp==0 and pending.special.evolution.growth_version==2,"G2 actual pending growth marker")
	check(is_equal_approx(g.Special.growth(pending)/g.Special.growth(identity),1.10),"G2 pending curve starts110")
	g.load_game()
	check(g.Special.equivalent(g.find_owned(main_id),pending),"G2 pending actual JSON preserves marker")
	g.save_blocked=true
	check(not g.commit_evolution_choice(main_id,"guard",pending) and g.Special.equivalent(g.find_owned(main_id),pending),"G2 failed choice preserves pending marker")
	g.save_blocked=false
	check(g.commit_evolution_choice(main_id,"guard",pending),"G2 actual permanent ability commit")
	var ready=g.find_owned(main_id).duplicate(true)
	check(ready.special.evolution.growth_version==2 and not g.Special.pending(ready),"G2 choice retains new curve marker")
	g.load_game()
	check(g.Special.equivalent(g.find_owned(main_id),ready),"G2 ready actual JSON preserves marker")
	check(g.find_owned(support_id).is_empty() and not g.find_owned(other_id).is_empty(),"D6 exactly selected same-species support consumed")
	for level in range(50,61):
		var legacy=ready.duplicate(true)
		legacy.level=level
		legacy.xp=13 if level<60 else 0
		legacy.special.evolution.erase("growth_version")
		var snapshot=legacy.duplicate(true)
		var power=g.Special.growth(legacy)
		var normal=g.SaveData.normalize(JSON.parse_string(JSON.stringify({"owned":[legacy],"squad":[legacy.id],"next_id":g.next_id,"discovered":["boar"]})),g.STATS.keys())
		check(g.Special.equivalent(normal.owned[0],snapshot) and is_equal_approx(g.Special.growth(normal.owned[0]),power),"G1 old5star exact metadata/strength level%d" % level)
	# Presentation events share the actual area center/radius and never mutate records.
	g.mode="tutorial"
	g.clear_overlay()
	g.player.pos=Vector2(1000,800)
	g.player.hp=g.player.maxhp
	g.enemies.clear()
	g.units.clear()
	g.spawn_enemy("boar",Vector2(1100,800),1,false)
	var target=g.enemies[-1]
	target.hp=100000
	target.maxhp=100000
	for kind in ["fox","deer","bat"]:
		var raw=g.Loot.roll(kind,40,g.loot_rng,3)
		var d=g.Loot.roll_special(raw,kind,g.loot_rng)
		d.special.state="ready"
		d.id=1000+["fox","deer","bat"].find(kind)
		d.special.element="wind"
		d.special.unique="reach" if kind in ["fox","deer"] else "basic"
		var u=g.make_unit(d,Vector2(1000,800))
		g.units=[u]
		g.element_feedback.clear()
		var snapshot=d.duplicate(true)
		check(g.SpecialCombat.cast(g,u,target),"D3 skill accepted "+kind)
		if kind=="fox": g.Assault.advance(g,u,0.23)
		var areas=g.element_feedback.events.filter(func(event): return event.radius>0)
		var radius=180*g.Special.radius(d) if kind=="fox" else 350*g.Special.radius(d) if kind=="deer" else 100.0
		check(areas.size()==1 and is_equal_approx(areas[0].radius,radius),"D3 exact actual visual radius "+kind)
		check(areas[0].b==(u.pos if kind=="deer" else target.pos),"D3 exact actual visual center "+kind)
		check(g.Special.equivalent(d,snapshot),"D3 skill visuals never mutate record "+kind)
		var before_hp=target.hp
		var unit_hp=u.hp
		g.element_feedback.advance(1.0)
		check(g.element_feedback.events.is_empty() and target.hp==before_hp and u.hp==unit_hp,"D3 visual expiry causes no damage or healing "+kind)
	# A direct special basic hit generates one cosmetic impact, not a second hit.
	var attacker=g.units[0]
	var before_hp=target.hp
	var damage=17*g.Special.damage(attacker.data,false,target)
	g.element_feedback.clear()
	g.hit_enemy(target,17,attacker.pos,attacker,false,false)
	check(is_equal_approx(before_hp-target.hp,damage) and g.element_feedback.events.size()==1,"D3 basic single damage with one element impact")
	var actor_snapshot=target.duplicate(true)
	g.element_feedback.clear()
	check(target==actor_snapshot,"D3 event clear does not mutate combat actor")
	for kind in ["boar","marten","wolf","fox","bat","turtle","deer"]:
		var raw=g.Loot.roll(kind,40,g.loot_rng,3)
		var d=g.Loot.roll_special(raw,kind,g.loot_rng)
		d.id=2000+["boar","marten","wolf","fox","bat","turtle","deer"].find(kind)
		d.trait="용맹함"
		d.options=[]
		d.special.affixes=[]
		d.special.state="ready"
		d.special.element="wind"
		d.special.unique=g.Special.choices(kind).keys()[0]
		var unit=g.make_unit(d,Vector2(1000,800))
		g.units=[unit]
		target.pos=Vector2(1030,800)
		target.hp=100000
		target.cd=100
		g.player.hp=g.player.maxhp-1
		g.auto_companion_skills=false
		g.update_game(0.01)
		var expected=(1.7 if kind=="deer" else 0.85 if kind=="marten" else 1.2)/1.1
		check(is_equal_approx(unit.cd,expected),"D5 actual basic action interval "+kind)
		if kind=="turtle":
			unit.hp=unit.maxhp
			unit.shield=5
			var hp=unit.hp
			g.damage_ally(unit,100,target.pos)
			check(is_equal_approx(hp-unit.hp,40),"D8 existing shield remains60 percent reduction")
			check(g.effects.any(func(effect): return effect.get("text","").begins_with("보호")),"D8 prevented damage becomes visible")
	# Existing regular enemy attacks still have one windup and exactly one resolve.
	for kind in g.Species.NEW:
		g.enemies.clear()
		g.spawn_enemy(kind,Vector2(1100,800),1,false)
		var enemy=g.enemies[-1]
		g.EnemyPatterns.begin(enemy,g.player)
		check(enemy.wind>0 and enemy.wind==enemy.wind_total,"D7 regular enemy windup exists "+kind)
		var data_before=g.Species.NEW[kind].duplicate(true)
		g.EnemyPatterns.resolve(g,enemy)
		check(enemy.swing==0.25 and enemy.cd>0,"D7 regular enemy hit animation/cooldown "+kind)
		check(g.Species.NEW[kind]==data_before,"D7 presentation never alters species data "+kind)
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var report={"checks":checks,"failures":errors,"basis":"7b5900b + 10fc00a + fcae89e + 9bcfc98","engine":"4.7.stable.official.5b4e0cb0f","user_save":"isolated res://.qa-data","limits":["No human/mobile interaction assessment","Actual renders supplied by integration lead"]}
	var out=FileAccess.open("res://docs/companion-feedback-qa.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	out.close()
	if errors.is_empty(): print("FEEDBACK QA PASS: %d checks" % checks)
	else: push_error("FEEDBACK QA FAIL: "+str(errors))
	quit(0 if errors.is_empty() else 1)
