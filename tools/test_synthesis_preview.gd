extends SceneTree
const Rules=preload("res://synthesis_rules.gd")
func _init():
	call_deferred("run")
func run():
	var failures=[]
	var records=[]
	for i in 4:
		records.append({"id":i+1,"kind":["boar","turtle","fox","deer"][i],"star":3,"grade":"epic","level":40,"xp":0,"trait":"용맹함","favorite":i==0,"legacy_options":true,"options":[{"key":"power","value":8}]})
	var before=records.duplicate(true)
	var plan=Rules.preview(records,[1],[1,2,3],1,"position")
	if not plan.error.is_empty() or plan.pool!=["boar","turtle"] or plan.main!=records[0]: failures.append("protected main and position candidates")
	if plan.get("result_star")!=4 or plan.get("result_level")!=1 or plan.get("success_percent")!=100 or plan.get("extra_cost")!=0: failures.append("approved outcome policy")
	plan.main.options[0].value=9
	if records!=before: failures.append("preview snapshot aliases owned options")
	for case in [[[1,1,3],1,"species"],[[1,2,3],4,"species"],[[1,2,99],1,"species"],[[1,2,3],2,"species"],[[1,2,3],1,"bad"]]:
		if Rules.preview(records,[1],case[0],case[1],case[2]).error.is_empty(): failures.append("invalid plan accepted "+str(case))
	records[1].favorite=true
	if Rules.preview(records,[],[1,2,3],1,"species").error.is_empty(): failures.append("favorite support protection")
	records[1].favorite=false
	var squad_support=Rules.preview(records,[1,2],[1,2,3],1,"species")
	if not squad_support.error.is_empty() or squad_support.leaving_squad!=[2]: failures.append("squad support leaves atomically")
	for level in [39,41]:
		records[1].level=level
		if Rules.preview(records,[],[1,2,3],1,"species").error.is_empty(): failures.append("exact level requirement")
	records[1].level=40
	var duplicate=records.duplicate(true)
	duplicate.append(records[1].duplicate(true))
	if Rules.preview(duplicate,[],[1,2,3],1,"species").error.is_empty(): failures.append("ambiguous ID")
	var game=load("res://animation/pixel_gameplay_preview.gd").new()
	root.add_child(game)
	game.mode="camp"
	game.owned=records.duplicate(true)
	game.squad=[1,2]
	game.materials=88
	var owned_before=game.owned.duplicate(true)
	var rng_before=game.loot_rng.state
	game.show_synthesis()
	var protected_pick=game.overlay.find_child("SynthesisSelect_1",true,false)
	if not protected_pick.disabled: failures.append("protected support selectable before main designation")
	game.overlay.find_child("SynthesisMain_1",true,false).pressed.emit()
	game.overlay.find_child("SynthesisSelect_2",true,false).pressed.emit()
	game.overlay.find_child("SynthesisSelect_3",true,false).pressed.emit()
	if game.overlay.find_child("SynthesisCandidates",true,false).disabled: failures.append("actual material and main selection callbacks")
	game.show_synthesis([1,2,3],1,"position")
	var summary=game.overlay.find_child("SynthesisCandidateSummary",true,false)
	var squad_notice=game.overlay.find_child("SynthesisSquadNotice",true,false)
	if summary==null or "합성 후보 4마리" not in summary.text: failures.append("candidate count visible")
	if squad_notice==null or "동행에서 해제" not in squad_notice.text: failures.append("squad material policy visible")
	var confirm=game.overlay.find_child("SynthesisCandidates",true,false)
	if confirm==null or confirm.disabled: failures.append("valid UI confirm")
	else: confirm.pressed.emit()
	if game.menu_page!="synthesis_candidates": failures.append("actual candidate callback")
	var pool_list=game.overlay.find_child("SynthesisPoolList",true,false)
	var leaving_notice=game.overlay.find_child("SynthesisLeavingNotice",true,false)
	if pool_list==null or "멧돼지 특수개체" not in pool_list.text or "거북 특수개체" not in pool_list.text or "50.0%" not in pool_list.text: failures.append("position pool and equal odds visible")
	if leaving_notice==null or "1마리" not in leaving_notice.text: failures.append("squad support removal visible")
	game.navigate_back()
	if game.menu_page!="synthesis": failures.append("candidate back navigation")
	# Revalidate protected state after the selection screen opened.
	game.owned[1].favorite=true
	game.preview_synthesis([1,2,3],1,"position")
	if game.menu_page=="synthesis_candidates": failures.append("stale support state accepted")
	game.owned[1].favorite=false
	for i in 3: game.preview_synthesis([1,2,3],1,"species")
	if game.owned!=owned_before or game.squad!=[1,2] or game.materials!=88 or game.loot_rng.state!=rng_before: failures.append("preview mutated gameplay or RNG")
	game.mode="stage"
	game.clear_overlay()
	game.show_synthesis([1,2,3],1)
	game.preview_synthesis([1,2,3],1,"species")
	if game.overlay.visible: failures.append("field entry blocked")
	game.queue_free()
	await process_frame
	if failures.is_empty(): print("SYNTHESIS PREVIEW PASS: protection, exact materials, distinct IDs, snapshots, candidate pools, actual UI callbacks, stale-state revalidation, no consumption or rerolls, camp-only")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
