extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Special=preload("res://special_companions.gd")
const Evolution=preload("res://evolution_rules.gd")
const Save=preload("res://save_data.gd")
var errors=[]
func check(ok,message):
	if not ok: errors.append(message)
func _init(): call_deferred("run")
func run():
	var g=load("res://main.gd").new()
	var path="user://evolution-test-"+str(Time.get_ticks_usec())+".json"
	g.save_path=path
	root.add_child(g)
	g.set_process(false)
	g.mode="camp"
	g.owned.clear()
	g.squad.clear()
	g.materials=77
	for kind in ["boar","fox","deer"]:
		var source=Loot.roll(kind,40,g.loot_rng,3)
		var d=Loot.roll_special(source,kind,g.loot_rng)
		d.level=50
		d.special.state="ready"
		d.special.element="water"
		d.special.unique=Special.choices(kind).keys()[1]
		g.make_owned(kind,50,d)
	var main_id=g.owned[0].id
	var support_id=g.owned[1].id
	g.owned[0].favorite=true
	g.owned[0].options=[{"key":"healing","value":12},{"key":"power","value":8}]
	g.owned[0].legacy_options=true
	g.squad=[main_id,g.owned[2].id]
	var before=g.owned.duplicate(true)
	var squad=g.squad.duplicate()
	var rng=g.loot_rng.state
	var plan=Evolution.preview(g.owned,g.squad,main_id,support_id)
	check(plan.error.is_empty() and plan.result.star==5 and plan.result.level==1 and Special.evolution_pending(plan.result),"valid cross-species preview")
	check(g.owned==before and g.loot_rng.state==rng,"preview is read-only")
	for invalid in [-1,main_id]: check(not Evolution.preview(g.owned,g.squad,main_id,invalid).error.is_empty(),"invalid/duplicate material")
	var dup=before.duplicate(true)
	dup.append(before[1].duplicate(true))
	check(not Evolution.preview(dup,g.squad,main_id,support_id).error.is_empty(),"duplicate owned id refused")
	for field in ["star","level","state"]:
		var bad=before.duplicate(true)
		if field=="state": bad[1].special.state="pending"
		elif field=="star": bad[1].star=5
		else: bad[1].level=51
		check(not Evolution.preview(bad,g.squad,main_id,support_id).error.is_empty(),"exact material "+field)
	g.owned[1].favorite=true
	check(not g.commit_evolution(main_id,support_id,plan.materials),"favorite protection recheck")
	g.owned[1].favorite=false
	g.squad.append(support_id)
	check(not g.commit_evolution(main_id,support_id,plan.materials),"squad protection recheck")
	g.squad=squad.duplicate()
	g.owned[0].special.element="earth"
	check(not g.commit_evolution(main_id,support_id,plan.materials),"stale main snapshot")
	g.owned=before.duplicate(true)
	check(g.save_game(),"baseline save")
	var baseline=FileAccess.get_file_as_string(path)
	g.save_path="user://missing-evolution-dir/invalid.json"
	check(not g.commit_evolution(main_id,support_id,plan.materials),"write failure refuses evolution")
	check(g.owned==before and g.squad==squad and g.loot_rng.state==rng and FileAccess.get_file_as_string(path)==baseline,"atomic rollback")
	g.save_path=path
	g.show_training(main_id)
	var evolve_button
	for child in g.overlay.get_children():
		if child is Button and child.text=="5성 진화": evolve_button=child
	check(is_instance_valid(evolve_button) and not evolve_button.disabled,"4-star max training evolution entry")
	if is_instance_valid(evolve_button): evolve_button.pressed.emit()
	check(g.menu_page=="evolution","training to evolution callback")
	check(not g.overlay.find_child("EvolutionSupport_"+str(support_id),true,false).disabled,"support UI enabled")
	g.overlay.find_child("EvolutionSupport_"+str(support_id),true,false).pressed.emit()
	check(g.menu_page=="evolution_confirm","confirmation callback")
	g.overlay.find_child("ConfirmEvolution",true,false).pressed.emit()
	var result=g.find_owned(main_id).duplicate(true)
	check(g.owned.size()==2 and g.find_owned(support_id).is_empty() and g.squad==squad and g.materials==77 and g.loot_rng.state==rng,"one support consumed no extra cost or RNG")
	var identity=result.duplicate(true)
	identity.star=4
	identity.level=50
	identity.special.erase("evolution")
	check(identity==before[0],"all existing identity metadata options element unique preserved")
	check(is_equal_approx(g.attack(result)/g.attack(before[0]),1.10) and is_equal_approx(g.max_hp(result)/g.max_hp(before[0]),1.10),"immediate raw110 percent")
	check(not g.commit_evolution(main_id,support_id,plan.materials),"double submit blocked")
	g.load_game()
	check(Special.equivalent(g.find_owned(main_id),result),"pending actual file roundtrip")
	g.start_stage(false)
	check(g.mode=="camp" and g.menu_page=="evolution_choice","pending blocks departure and routes recovery")
	for i in 3: g.show_special_choice(main_id)
	check(Special.equivalent(g.find_owned(main_id),result),"reopening no reroll")
	check(not g.commit_special_choice(main_id,"earth","vital",g.find_owned(main_id)),"cannot replace old 4-star choices")
	g.save_blocked=true
	check(not g.commit_evolution_choice(main_id,"guard",result),"blocked save rejects choice")
	g.save_blocked=false
	var stale=result.duplicate(true)
	stale.trait="different"
	check(not g.commit_evolution_choice(main_id,"guard",stale),"stale selection snapshot")
	check(not g.commit_evolution_choice(main_id,"skill",result),"wrong role choice rejected")
	g.save_path="user://missing-evolution-dir/invalid.json"
	check(not g.commit_evolution_choice(main_id,"guard",result) and Special.equivalent(g.find_owned(main_id),result),"choice save failure rollback")
	g.save_path=path
	g.show_special_choice(main_id)
	g.overlay.find_child("EvolutionAbility_guard",true,false).pressed.emit()
	g.overlay.find_child("ConfirmEvolutionChoice",true,false).pressed.emit()
	var ready=g.find_owned(main_id).duplicate(true)
	check(Special.evolution(ready)=="guard" and not Special.pending(ready),"actual choice callbacks")
	check(not g.commit_evolution_choice(main_id,"vital",ready),"permanent choice no resubmit")
	g.load_game()
	check(Special.equivalent(g.find_owned(main_id),ready),"ready actual file roundtrip")
	var normalized=Save.normalize(JSON.parse_string(JSON.stringify({"owned":g.owned,"squad":g.squad,"next_id":g.next_id,"discovered":g.discovered})),g.STATS.keys())
	check(Special.equivalent(normalized.owned,g.owned) and not normalized.repaired,"normalization idempotent and inactive inherited option retained")
	var capped=ready.duplicate(true)
	capped.level=60
	check(is_equal_approx(g.attack(capped)/g.attack(before[0]),1.30) and Loot.max_level(capped)==60,"5-star level60 raw130 percent cap")
	check(g.Management.project(capped,99999)==capped,"max XP blocked")
	check(Evolution.material_error(capped,g.squad,true,5).is_empty(),"5->6 material enabled")
	var ready_index=g.owned.find(g.find_owned(main_id))
	g.owned[ready_index]=capped
	g.show_training(main_id)
	var six_enabled=false
	for child in g.overlay.get_children():
		if child is Button and child.text=="6성 진화": six_enabled=not child.disabled
	check(six_enabled,"6-star button enabled")
	g.owned[ready_index]=ready
	g.show_training(main_id)
	var labels=[]
	for child in g.overlay.get_children():
		if child is Button: labels.append(child.text)
	check(labels.has("재료 3개로 육성"),"5-star training remains available")
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if errors.is_empty(): print("EVOLUTION PASS: actual UI and file roundtrip, exact materials/protection/stale/double submit, atomic failure rollback, identity and all options, no RNG, pending recovery and departure gate, permanent choice,110/130 growth, cap and enabled6")
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
