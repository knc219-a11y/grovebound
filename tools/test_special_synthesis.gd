extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Special=preload("res://special_companions.gd")
const Save=preload("res://save_data.gd")
var errors=[]
func check(condition,message):
	if not condition: errors.append(message)
func _init(): call_deferred("run")
func run():
	var game=load("res://main.gd").new()
	var path="user://special-test-"+str(Time.get_ticks_usec())+".json"
	game.save_path=path
	root.add_child(game)
	game.set_process(false)
	game.mode="camp"
	game.materials=77
	game.owned.clear()
	game.squad.clear()
	for kind in ["boar","fox","turtle","deer"]:
		game.make_owned(kind,40,Loot.roll(kind,40,game.loot_rng,3))
	var ids=[game.owned[0].id,game.owned[1].id,game.owned[2].id]
	game.owned[0].favorite=true
	game.owned[0].legacy_options=true
	game.owned[0].options=[{"key":"stun_hunter","value":20}]
	game.squad=ids.duplicate()
	var old=game.owned.duplicate(true)
	var expected=old.slice(0,3).duplicate(true)
	check(game.save_game(),"baseline actual save")
	# Failure does not consume materials, advance RNG, change original file, or create a result.
	var baseline=FileAccess.get_file_as_string(path)
	var rng=game.loot_rng.state
	game.save_path="user://missing-special-dir/invalid.json"
	check(not game.commit_synthesis(ids,ids[0],"species",expected),"failed write rejected")
	check(game.owned==old and game.loot_rng.state==rng and FileAccess.get_file_as_string(path)==baseline,"failed write rollback")
	game.save_path=path
	game.owned[1].favorite=true
	check(not game.commit_synthesis(ids,ids[0],"species",expected),"stale favorite protected")
	game.owned[1].favorite=false
	check(game.commit_synthesis(ids,ids[0],"position",expected),"actual synthesis")
	var result=game.find_owned(ids[0]).duplicate(true)
	check(game.owned.size()==2 and game.find_owned(ids[1]).is_empty() and game.find_owned(ids[2]).is_empty(),"exactly two supports consumed")
	check(result.star==4 and result.level==1 and result.id==old[0].id and result.favorite and result.trait==old[0].trait and result.options==old[0].options and game.squad==[ids[0]],"identity trait options favorite party preserved and supports removed")
	check(result.kind in ["boar","turtle"] and result.special.affixes.size()==2 and result.special.affixes[0].key!=result.special.affixes[1].key,"approved pool and two distinct affixes")
	check(game.materials==77 and Special.pending(result),"no extra cost and pending selection")
	check(not game.commit_synthesis(ids,ids[0],"position",expected),"double submit rejected")
	game.load_game()
	check(game.find_owned(ids[0])==result,"actual pending file roundtrip")
	game.start_stage(false)
	check(game.mode=="camp" and game.menu_page=="special_choice","pending blocks expedition and resumes selection")
	for i in 3: game.show_special_choice(ids[0])
	check(game.find_owned(ids[0])==result,"reopening no reroll")
	check(not game.commit_special_choice(ids[0],"unknown","vital",result),"invalid element cannot be selected")
	check(game.commit_special_choice(ids[0],"wind","vital",result),"final choice persisted")
	var ready=game.find_owned(ids[0]).duplicate(true)
	check(not game.commit_special_choice(ids[0],"earth","guard",ready),"choices cannot be reset")
	game.load_game()
	check(game.find_owned(ids[0])==ready and Special.ready(ready),"ready file roundtrip fixed affixes")
	# Forced cross-species fixture verifies dormant options survive normalization and repeated JSON loads.
	var crossed=ready.duplicate(true)
	crossed.kind="turtle"
	var normalized=Save.normalize({"owned":[crossed],"squad":[crossed.id]},game.STATS.keys())
	check(normalized.owned[0].options==crossed.options and Loot.bonus(normalized.owned[0],"stun_hunter")==0,"cross-species options retained but inactive")
	var again=Save.normalize(JSON.parse_string(JSON.stringify(normalized)),game.STATS.keys())
	check(again.owned==normalized.owned and not again.repaired,"special save normalization idempotent")
	# Selection buttons use the stored record and cannot alter random affixes.
	game.owned[0]=result.duplicate(true)
	game.show_special_choice(ids[0])
	check(not game.overlay.find_child("Element_water",true,false).disabled,"water catalog is selectable")
	game.overlay.find_child("Element_water",true,false).pressed.emit()
	game.overlay.find_child("Unique_guard",true,false).pressed.emit()
	game.overlay.find_child("ConfirmSpecial",true,false).pressed.emit()
	check(Special.element(game.find_owned(ids[0]))=="water" and Special.unique(game.find_owned(ids[0]))=="guard","real choice callbacks")
	game.save_blocked=true
	var unchanged=game.owned.duplicate(true)
	check(not game.commit_special_choice(ids[0],"wind","vital",game.owned[0]) and game.owned==unchanged,"blocked save refuses changes")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if errors.is_empty(): print("SPECIAL SYNTHESIS PASS: atomic write failure rollback, exact consumption, stale and duplicate submits, identity and inherited options, pending/ready actual save roundtrip, no reroll, choice callbacks, approved water selectable and saved")
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
