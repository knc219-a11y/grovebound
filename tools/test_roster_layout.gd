extends SceneTree
# Independent regression for production roster commands and rendered layout.
const Fixture=preload("res://animation/roster_layout_review.gd")
var failures=[]
var checks=0
func _init(): call_deferred("run")
func check(value,caption):
	checks+=1
	if not value: failures.append(caption)
func all_text(node):
	var result=""
	if node is Label or node is Button: result+=node.text+"\n"
	for child in node.get_children(): result+=all_text(child)
	return result
func descendants(node,type_name):
	var result=[]
	for child in node.get_children():
		if child.is_class(type_name): result.append(child)
		result.append_array(descendants(child,type_name))
	return result
func settle():
	await process_frame
	await process_frame
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa-data"))
	var path="res://.qa-data/roster-layout-"+str(Time.get_ticks_usec())+".json"
	var g=load("res://main.gd").new()
	g.save_path=path
	root.add_child(g)
	g.set_process(false)
	Fixture.populate(g)
	var before=g.owned.duplicate(true)
	var initial=g.squad.duplicate()
	var loot_state=g.loot_rng.state
	var random_state=g.rng.state
	g.open_roster()
	await settle()
	check(g.Special.equivalent(g.owned,before) and g.squad==initial,"opening roster preserves every companion and party")
	check(g.loot_rng.state==loot_state and g.rng.state==random_state,"opening roster never rerolls metadata")
	var scroll=g.overlay.find_child("CompanionScroll",true,false)
	var lineup=g.overlay.get_node_or_null("PartyLineup")
	check(scroll is ScrollContainer,"left roster scroll exists")
	check(lineup!=null,"separate right party exists")
	if scroll!=null and lineup!=null:
		check(scroll.get_global_rect().end.x<=lineup.get_global_rect().position.x+1,"roster and party are side by side without overlap")
		check(scroll.size.y>=300 and scroll.size.x>=550,"roster gets useful browsing space")
		var visible_cards=0
		for i in g.owned.size():
			var card=scroll.find_child("Companion_"+str(g.owned[i].id),true,false)
			if card==null: continue
			if scroll.get_global_rect().encloses(card.get_global_rect()): visible_cards+=1
			check(card.size.x>=44 and card.size.y>=44,"touch target "+str(i))
		check(visible_cards>=9,"at least nine complete companion cards visible")
		check(descendants(scroll,"TextureRect").size()>=30,"all owned companions have portraits")
		check(all_text(scroll).contains("★"),"actual star glyphs in owned list")
		check(scroll.get_v_scroll_bar().max_value>scroll.size.y,"large collection can scroll")
		for i in 6:
			var slot=lineup.find_child("PartySlot_"+str(i+1),true,false)
			check(slot is Button,"explicit party slot "+str(i+1))
			if slot!=null: check(slot.text.contains("출전 "+str(i+1) if i<4 else "대기 "+str(i-3)),"party slot role "+str(i+1))
	# Repeated slot-to-slot actions must reset selection and keep IDs unique.
	for cycle in 2:
		g.overlay.find_child("PartySlot_1",true,false).pressed.emit()
		g.overlay.find_child("PartySlot_5",true,false).pressed.emit()
		check(g.roster_selected_id==-1 and g.squad.size()==6,"slot swap clears selection "+str(cycle))
	check(g.squad==initial,"two repeated slot swaps restore original order")
	check(g.save_game(),"favorite failure baseline written")
	var favorite_id=g.owned[7].id
	var favorite_before=g.find_owned(favorite_id).favorite
	var favorite_file=FileAccess.get_file_as_string(path)
	g.save_blocked=true
	check(not g.toggle_favorite(favorite_id) and g.find_owned(favorite_id).favorite==favorite_before,"blocked favorite write preserves memory")
	check(FileAccess.get_file_as_string(path)==favorite_file,"blocked favorite write preserves file")
	g.save_blocked=false
	g.save_path="res://.qa-data/roster-missing-directory/favorite.json"
	check(not g.toggle_favorite(favorite_id) and g.find_owned(favorite_id).favorite==favorite_before,"actual failed favorite write preserves memory")
	g.save_path=path
	check(g.toggle_favorite(favorite_id) and g.find_owned(favorite_id).favorite!=favorite_before,"favorite publishes after successful write")
	var favorite_disk=JSON.parse_string(FileAccess.get_file_as_string(path))
	var favorite_normal=g.SaveData.normalize(favorite_disk,g.STATS.keys())
	var saved_favorite=favorite_normal.owned.filter(func(d): return d.id==favorite_id)
	check(saved_favorite.size()==1 and saved_favorite[0].favorite!=favorite_before,"favorite persisted in real file")
	check(g.toggle_favorite(favorite_id) and g.find_owned(favorite_id).favorite==favorite_before,"favorite reset preserves metadata baseline")
	# Click a card and a real destination button, then verify a full-party replacement.
	var spare=g.owned[18].id
	var portrait_card=g.overlay.find_child("Companion_"+str(spare),true,false)
	if portrait_card is Button: portrait_card.pressed.emit()
	else: g.roster_select(spare)
	await settle()
	check(g.roster_selected_id==spare and g.squad==initial,"selection alone does not change party")
	var first_slot=g.overlay.find_child("PartySlot_1",true,false)
	if first_slot is Button: first_slot.pressed.emit()
	else: g.roster_assign(0)
	check(g.squad[0]==spare and g.squad.size()==6 and not g.squad.has(initial[0]),"list selection replaces intended full-party slot")
	check(g.Special.equivalent(g.owned,before),"assignment preserves all owned metadata")
	check(g.save_game(),"isolated production file write")
	var disk=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(disk is Dictionary and g.SaveData.normalize(disk,g.STATS.keys()).squad==g.squad,"party assignment persisted through production JSON ID normalization")
	var outgoing=g.squad[0]
	var reserve=g.squad[4]
	g.roster_select(outgoing)
	g.roster_assign(4)
	check(g.squad[0]==reserve and g.squad[4]==outgoing,"owned party member swaps active and reserve slots")
	check(g.squad.size()==6 and g.squad.duplicate().size()==6,"swap preserves party capacity")
	g.roster_remove(g.squad[5])
	check(g.squad.size()==5,"remove selected companion from party")
	g.roster_select(initial[0])
	g.roster_assign(5)
	check(g.squad.size()==6 and g.squad[5]==initial[0],"empty last slot accepts stored companion")
	var stable=g.squad.duplicate()
	var file_before=FileAccess.get_file_as_string(path)
	g.save_blocked=true
	g.roster_select(spare)
	g.roster_assign(1)
	check(g.squad==stable and FileAccess.get_file_as_string(path)==file_before,"failed save rolls back assignment and file")
	g.roster_remove(stable[0])
	check(g.squad==stable and FileAccess.get_file_as_string(path)==file_before,"failed save rolls back removal and file")
	g.save_blocked=false
	var good_path=g.save_path
	g.save_path="res://.qa-data/roster-missing-directory/write.json"
	g.roster_select(spare)
	g.roster_assign(1)
	check(g.squad==stable,"actual filesystem failure does not publish assignment")
	g.save_path=good_path
	g.roster_select(-999)
	g.roster_selected_id=-999
	g.roster_assign(0)
	g.roster_assign(-1)
	g.roster_assign(6)
	g.roster_remove(-999)
	check(g.squad==stable,"invalid IDs and out of range slots cannot mutate party")
	check(g.Special.equivalent(g.owned,before) and g.loot_rng.state==loot_state and g.rng.state==random_state,"all assignment commands preserve companion metadata and RNG")
	# Filters inspect all owned records rather than hiding the out-of-party collection.
	g.roster_kind_filter="bat"
	g.open_roster()
	await settle()
	scroll=g.overlay.find_child("CompanionScroll",true,false)
	if scroll!=null:
		for d in g.owned:
			check((scroll.find_child("Companion_"+str(d.id),true,false)!=null)==(d.kind=="bat"),"species filter "+str(d.id))
	g.roster_kind_filter=""
	for star in range(1,7):
		g.roster_grade_filter=str(star)
		g.open_roster()
		await settle()
		scroll=g.overlay.find_child("CompanionScroll",true,false)
		if scroll!=null:
			for d in g.owned:
				check((scroll.find_child("Companion_"+str(d.id),true,false)!=null)==(g.Loot.star(d)==star),"star filter %d / id %d" % [star,d.id])
	g.roster_grade_filter=""
	g.roster_sort=2
	g.open_roster()
	await settle()
	var grid=g.overlay.find_child("CompanionGrid",true,false)
	if grid!=null:
		var previous=7
		for card in grid.get_children():
			if not str(card.name).begins_with("Companion_"): continue
			var d=g.find_owned(int(str(card.name).trim_prefix("Companion_")))
			check(g.Loot.star(d)<=previous,"descending star sort")
			previous=g.Loot.star(d)
	g.roster_sort=0
	g.roster_favorites_only=true
	g.open_roster()
	await settle()
	scroll=g.overlay.find_child("CompanionScroll",true,false)
	if scroll!=null:
		for d in g.owned:
			check((scroll.find_child("Companion_"+str(d.id),true,false)!=null)==d.favorite,"favorite filter "+str(d.id))
	g.reset_roster_filters()
	await settle()
	scroll=g.overlay.find_child("CompanionScroll",true,false)
	if scroll!=null:
		scroll.scroll_vertical=120
		await settle()
		var at=scroll.scroll_vertical
		g.roster_select(g.owned[17].id)
		await settle()
		scroll=g.overlay.find_child("CompanionScroll",true,false)
		check(scroll!=null and scroll.scroll_vertical==at,"selecting a card preserves scroll position")
	g.roster_kind_filter="unknown"
	g.open_roster()
	await settle()
	check(all_text(g.overlay).contains("없"),"empty filter has visible explanation")
	g.reset_roster_filters()
	var expected=g.save_payload().duplicate(true)
	check(g.save_game(),"save round trip baseline")
	g.owned.clear()
	g.squad.clear()
	g.load_game()
	check(g.Special.equivalent(g.owned,expected.owned) and g.squad==expected.squad,"production reload preserves all companion records and party")
	check(g.Special.equivalent(g.hero,expected.hero) and g.Special.equivalent(g.Routes.progress_for(g),expected.campaign_progress),"UI changes preserve hero and campaign progression")
	# Old root v2 files do not need the ephemeral selection/scroll fields.
	check(not expected.has("roster_selected_id") and not expected.has("roster_scroll") and expected.version==2,"UI state adds no save fields or version bump")
	# Dense existing save arrays fill the next free place even if a later visual slot was chosen.
	var full_party=g.squad.duplicate()
	check(g.commit_roster(full_party.slice(0,2)),"partial party fixture uses atomic command")
	g.open_roster()
	g.roster_select(g.owned[27].id)
	check(g.roster_assign(5) and g.squad.size()==3 and g.squad[2]==g.owned[27].id,"distant empty slot appends into next free active place")
	check(not g.squad.has(-1) and g.commit_roster(full_party),"partial slot action preserves compact compatible save array")
	g.mode="stage"
	g.in_combat=false
	g.units.clear()
	for id in g.squad: g.units.append(g.make_unit(g.find_owned(id),Vector2(500,500)))
	g.open_roster()
	var field_before=g.squad.duplicate()
	var unit0=g.units[0]
	var unit4=g.units[4]
	g.roster_select(field_before[0])
	g.roster_assign(4)
	check(g.squad[0]==field_before[4] and g.squad[4]==field_before[0],"field noncombat active reserve swap remains available")
	check(g.units[0]==unit4 and g.units[4]==unit0,"field swap moves the existing HP/cooldown unit objects")
	stable=g.squad.duplicate()
	g.roster_selected_id=g.owned[27].id
	g.roster_assign(0)
	g.roster_remove(stable[0])
	check(g.squad==stable,"field cannot add stored companions or remove party members")
	g.in_combat=true
	g.roster_select(stable[0])
	g.roster_assign(4)
	check(g.squad==stable,"combat blocks stale roster commands")
	g.mode="tutorial"
	g.in_combat=false
	g.roster_select(stable[0])
	g.roster_assign(4)
	check(g.squad==stable,"tutorial blocks roster commands")
	g.mode="camp"
	g.owned.clear()
	g.squad.clear()
	g.open_roster()
	await settle()
	check(all_text(g.overlay).contains("없") or all_text(g.overlay).contains("첫 인연"),"empty collection has useful first-companion guidance")
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures.is_empty(): print("ROSTER LAYOUT PASS: ",checks," independent layout, selection, assignment, filtering, save failure and compatibility checks")
	else: push_error("ROSTER LAYOUT FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)




