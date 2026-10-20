extends SceneTree
const Manager=preload("res://companion_management.gd")
const Loot=preload("res://companion_loot.gd")
const Save=preload("res://save_data.gd")
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check_management")
func check_management():
	var failures=[]
	var records=[
		{"id":1,"kind":"boar","level":3,"xp":100,"trait":"강인함","star":1,"grade":"common","options":[],"favorite":true},
		{"id":2,"kind":"fox","level":4,"xp":0,"trait":"용맹함","star":3,"grade":"epic","options":[],"favorite":false},
		{"id":3,"kind":"boar","level":5,"xp":5,"trait":"민첩함","star":2,"grade":"rare","options":[],"favorite":false},
		{"id":4,"kind":"boar","level":2,"xp":0,"trait":"단단함","star":3,"grade":"epic","options":[],"favorite":true}]
	var original=JSON.stringify(records)
	var party=[3,1]
	var order=Manager.filtered(records,party)
	if order[0].id!=3 or order[1].id!=1: failures.append("party display order")
	if Manager.filtered(records,party,"boar","epic",true).size()!=1: failures.append("combined filters")
	if Manager.filtered(records,party,"deer").size()!=0: failures.append("empty filter")
	if Manager.filtered(records,party,"","",false,1)[0].id!=4: failures.append("recent sorting")
	if Manager.filtered(records,party,"","",false,2)[0].id!=2: failures.append("grade then level sorting")
	if Manager.filtered(records,party,"","",false,3)[0].id!=3: failures.append("level sorting")
	if JSON.stringify(records)!=original or party!=[3,1]: failures.append("sorting never mutates ownership or party")
	var projection=Manager.project(records[0],40)
	if projection.level!=4 or projection.xp!=35 or records[0].level!=3: failures.append("level projection and leftover XP")
	var multi=Manager.project(records[3],300)
	if multi.level!=4 or multi.xp!=125: failures.append("multiple level projection")
	if Manager.project(records[0],-40).xp!=100: failures.append("negative XP ignored")
	if Manager.can_release(records[0],[]) or Manager.can_release(records[2],party): failures.append("favorite and squad protection")
	var normalized=Save.normalize(JSON.parse_string(JSON.stringify({"owned":records,"squad":party,"next_id":5,"discovered":["boar","fox"]})),["boar","fox"])
	if normalized.repaired or not normalized.owned[0].favorite or normalized.owned[1].favorite: failures.append("favorite JSON roundtrip")
	var legacy=records[0].duplicate(true)
	legacy.erase("favorite")
	var migrated=Save.normalize({"owned":[legacy],"squad":[1]},["boar"])
	if not migrated.repaired or migrated.owned[0].favorite or migrated.owned[0].xp!=100: failures.append("legacy metadata migration preserves XP")
	var game=Preview.new()
	root.add_child(game)
	game.set_process(false)
	game.mode="camp"
	game.owned=records.duplicate(true)
	game.squad=[3]
	game.units=[game.make_unit(game.find_owned(3),Vector2(900,800))]
	game.materials=6
	game.open_roster()
	game.toggle_favorite(2)
	if not game.find_owned(2).favorite or game.release_companion(2): failures.append("favorite protected at operation boundary")
	game.confirm_release(1)
	if not game.find_owned(1).favorite: failures.append("confirmation does not unlock")
	game.toggle_favorite(2)
	var reward=Manager.farewell_reward(game.find_owned(2))
	if not game.release_companion(2) or not game.find_owned(2).is_empty() or game.materials!=6+reward: failures.append("unlocked reserve release")
	if game.release_companion(2) or game.release_companion(3) or game.materials!=6+reward: failures.append("duplicate release and squad release blocked")
	game.show_training(1)
	if game.materials!=6+reward or game.find_owned(1).level!=3: failures.append("preview spends nothing")
	var metadata=game.find_owned(1).duplicate(true)
	if not game.train_companion(1) or game.materials!=3+reward or game.find_owned(1).level!=4 or game.find_owned(1).xp!=35: failures.append("training cost and XP")
	for key in ["id","kind","trait","star","grade","options","favorite"]:
		if game.find_owned(1)[key]!=metadata[key]: failures.append("training preserves "+key)
	game.materials=2
	if game.train_companion(1) or game.materials!=2 or game.find_owned(1).xp!=35: failures.append("insufficient materials")
	game.mode="stage"
	game.materials=8
	if game.train_companion(1): failures.append("field training rejected")
	game.gain_xp(game.find_owned(3),200)
	if game.units[0].maxhp!=game.max_hp(game.find_owned(3)): failures.append("active unit maxHP synced after growth")
	var found=false
	for event in game.combat_feedback.events:
		if event.kind=="level_up": found=true
	if not found: failures.append("actual active level up has feedback")
	var capped={"id":9,"kind":"boar","level":20,"xp":0,"trait":"강인함","star":1,"grade":"common","options":[],"favorite":true}
	game.mode="camp"
	game.owned.append(capped)
	var expected=capped.duplicate(true)
	if not game.promote_companion(9,expected) or capped.star!=2 or capped.level!=1 or capped.id!=9 or not capped.favorite: failures.append("atomic identity-preserving promotion")
	if game.promote_companion(9,expected): failures.append("stale duplicate promotion blocked")
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty(): print("MANAGEMENT PASS: combined filters/stable sorting, favorite persistence/protection, XP projection/training costs, metadata preservation, active growth feedback")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
