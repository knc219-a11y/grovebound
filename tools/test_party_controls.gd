extends SceneTree

const Loot=preload("res://companion_loot.gd")

func _init(): call_deferred("run")

func run():
	var failures=[]
	var game=load("res://main.gd").new()
	var path="user://party-controls-"+str(Time.get_ticks_usec())+".json"
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.mode="camp"
	game.owned.clear()
	game.squad.clear()
	for i in 6:
		var kind=["boar","marten","fox","turtle","deer","wolf"][i]
		game.make_owned(kind,40,Loot.roll(kind,40,game.loot_rng,3))
		game.squad.append(game.owned[-1].id)
	game.open_roster()
	var lineup=game.overlay.get_node_or_null("PartyLineup")
	if lineup==null: failures.append("lineup present")
	else:
		var active=lineup.get_node_or_null("ActiveGroup")
		var reserve=lineup.get_node_or_null("ReserveGroup")
		if active==null or reserve==null: failures.append("active and reserve groups")
		elif not active.get_node("GroupLabel").text.contains("전투 출전") or not reserve.get_node("GroupLabel").text.contains("교체 대기"): failures.append("clear group labels")
		for i in 6:
			var slot=lineup.find_child("PartySlot_"+str(i+1),true,false)
			if slot==null: failures.append("explicit lineup slot "+str(i+1))
			elif i<4 and not slot.text.contains("출전 "+str(i+1)): failures.append("active slot label "+str(i+1))
			elif i>=4 and not slot.text.contains("대기 "+str(i-3)): failures.append("reserve slot label "+str(i-3))
	var first=game.squad[0]
	var fifth=game.squad[4]
	game.select_swap(first)
	game.select_swap(fifth)
	if game.squad[0]!=fifth or game.squad[4]!=first: failures.append("direct active reserve swap")
	if game.auto_skill_button==null or not game.auto_skill_button.text.contains("OFF"): failures.append("auto skill button")
	game.toggle_auto_companion_skills()
	if not game.auto_companion_skills or not game.auto_skill_button.text.contains("ON"): failures.append("auto skill toggle")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not saved is Dictionary or saved.get("auto_companion_skills")!=true: failures.append("auto skill saved")
	game.clear_overlay()
	game.mode="tutorial"
	var deer=game.make_unit(game.owned[4],Vector2(300,300))
	game.units=[deer]
	game.player.pos=Vector2(320,300)
	game.player.hp=game.player.maxhp*0.60
	if not game.should_auto_use_companion_skill(0): failures.append("auto heal injured ally")
	game.player.hp=game.player.maxhp
	if game.should_auto_use_companion_skill(0): failures.append("auto heal conserves cooldown at full health")
	var turtle=game.make_unit(game.owned[3],Vector2(300,300))
	game.units=[turtle]
	game.enemies=[{"hp":10.0,"maxhp":10.0,"pos":Vector2(350,300),"boss":false}]
	if game.should_auto_use_companion_skill(0): failures.append("auto guard waits for pressure")
	game.enemies[0].boss=true
	if not game.should_auto_use_companion_skill(0): failures.append("auto guard reacts to boss")
	var boar=game.make_unit(game.owned[0],Vector2(300,300))
	game.units=[boar]
	if not game.should_auto_use_companion_skill(0): failures.append("auto attack uses valid target")
	boar.skill=1.0
	if game.should_auto_use_companion_skill(0): failures.append("auto skill respects cooldown")
	var legacy=game.save_payload().duplicate(true)
	legacy.erase("auto_companion_skills")
	write_save(path,legacy)
	game.auto_companion_skills=true
	game.load_game()
	if game.auto_companion_skills: failures.append("legacy save defaults auto skill off")
	legacy.auto_companion_skills="yes"
	write_save(path,legacy)
	game.auto_companion_skills=true
	game.load_game()
	if game.auto_companion_skills: failures.append("invalid auto skill setting defaults off")
	game.mode="camp"
	game.clear_overlay()
	game.show_synthesis([game.owned[0].id,game.owned[1].id,game.owned[2].id],game.owned[0].id,"species")
	var support=game.overlay.find_child("SynthesisSelect_"+str(game.owned[1].id),true,false)
	if support==null or support.disabled: failures.append("squad support candidate selectable")
	var plan=game.Synthesis.preview(game.owned,game.squad,[game.owned[0].id,game.owned[1].id,game.owned[2].id],game.owned[0].id,"species")
	if plan.error!="" or plan.leaving_squad.size()!=2: failures.append("squad supports announced for removal")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures.is_empty(): print("PARTY CONTROLS PASS: explicit active/reserve slots, direct swapping, saved auto-skill toggle, squad synthesis candidates")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)

func write_save(path,data):
	var file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
