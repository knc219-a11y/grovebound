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
	var path="user://evolution-six-test-"+str(Time.get_ticks_usec())+".json"
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
		d.star=5
		d.level=60
		d.special.evolution={"version":1,"state":"ready","ability":Special.evolution_choices(kind).keys()[1]}
		d.special.state="ready"
		d.special.element="water"
		d.special.unique=Special.choices(kind).keys()[1]
		g.make_owned(kind,60,d)
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
	check(plan.error.is_empty() and plan.result.star==6 and plan.result.level==60 and not Special.pending(plan.result) and plan.result.special.evolution.enhanced,"valid cross-species preview")
	check(g.owned==before and g.loot_rng.state==rng,"preview is read-only")
	for invalid in [-1,main_id]: check(not Evolution.preview(g.owned,g.squad,main_id,invalid).error.is_empty(),"invalid/duplicate material")
	var dup=before.duplicate(true)
	dup.append(before[1].duplicate(true))
	check(not Evolution.preview(dup,g.squad,main_id,support_id).error.is_empty(),"duplicate owned id refused")
	for field in ["star","level","state"]:
		var bad=before.duplicate(true)
		if field=="state": bad[1].special.state="pending"
		elif field=="star": bad[1].star=4
		else: bad[1].level=61
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
		if child is Button and child.text=="6성 진화": evolve_button=child
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
	identity.star=5
	identity.special.evolution.erase("enhanced")
	check(identity==before[0],"all identity and selected ability preserved")
	check(g.menu_page=="detail","six-star transaction opens detail without reselection")
	check(not g.commit_evolution(main_id,support_id,plan.materials),"double submit blocked")
	check(not g.commit_evolution_choice(main_id,"vital",result),"6-star choice cannot be replaced")
	g.load_game()
	check(Special.equivalent(g.find_owned(main_id),result),"enhancement actual file roundtrip")
	check(not Special.pending(g.find_owned(main_id)),"loaded six-star ready")
	var normalized=Save.normalize(JSON.parse_string(JSON.stringify({"owned":g.owned,"squad":g.squad,"next_id":g.next_id,"discovered":g.discovered})),g.STATS.keys())
	check(Special.equivalent(normalized.owned,g.owned) and not normalized.repaired,"six-star normalization idempotent")
	var capped=result.duplicate(true)
	capped.level=70
	check(Loot.max_level(capped)==70 and g.Management.project(capped,99999)==capped,"six-star cap XP blocked")
	check(is_equal_approx(Special.attack_scale(result)/Special.attack_scale(before[0]),1.10),"six-star starting raw110 percent")
	check(is_equal_approx(Special.attack_scale(capped)/Special.attack_scale(before[0]),1.30),"six-star max raw130 percent")
	var growing=result.duplicate(true)
	growing.level=69
	growing.xp=35*69-1
	var projected=g.Management.project(growing,100000)
	check(projected.level==70,"XP crosses final level and stops")
	for field in ["state","ability"]:
		var bad=before.duplicate(true)
		bad[1].special.evolution[field]="pending" if field=="state" else "invalid"
		var repaired=Save.normalize({"owned":bad,"squad":squad,"next_id":g.next_id,"discovered":g.discovered},g.STATS.keys())
		check(not Evolution.preview(repaired.owned,squad,main_id,support_id).error.is_empty(),"incomplete evolution choice "+field)
	g.start_stage(false)
	check(g.mode!="camp","ready six-star can depart")
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if errors.is_empty(): print("EVOLUTION SIX PASS: UI transaction, exact materials, protection, stale and duplicate submission, atomic failure rollback, identity/options/selection and squad preserved, no RNG/cost, real file roundtrip, XP70 and110/130 growth")
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
