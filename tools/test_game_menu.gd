extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Save=preload("res://save_data.gd")
func _initialize(): call_deferred("check_menu")
func key(game,code):
	var event=InputEventKey.new()
	event.pressed=true
	event.physical_keycode=code
	game._unhandled_input(event)
func check_menu():
	var failures=[]
	var game=Preview.new()
	root.add_child(game)
	game.set_process(false)
	game.mode="camp"
	game.in_combat=false
	game.discovered.clear()
	game.owned.clear()
	game.squad.clear()
	var first=game.make_owned("boar",3)
	var second=game.make_owned("fox",4)
	game.squad=[first.id]
	game.materials=12
	game.show_camp()
	if game.overlay.get_node_or_null("Navigation_inventory")==null: failures.append("camp shared navigation")
	for item in game.overlay.get_children():
		if item.name.begins_with("Navigation_") and not Rect2(0,0,1440,810).encloses(item.get_global_rect()): failures.append("navigation within viewport")
	game.overlay.get_node("Navigation_inventory").pressed.emit()
	if game.menu_page!="inventory" or game.mode!="camp": failures.append("inventory opens without changing game location")
	await process_frame
	await process_frame
	var scroll=game.overlay.get_node("InventoryScroll")
	if scroll.get_child(0).get_child_count()!=2: failures.append("bag shows real companions")
	scroll.get_child(0).get_child(0).pressed.emit()
	if game.inventory_selected!=first.id: failures.append("slot selection callback")
	game.show_loot_details(first.id,-1,false)
	if game.detail_origin_page!="inventory": failures.append("details remember bag origin")
	game.navigate_back()
	if game.menu_page!="inventory": failures.append("detail back returns to bag")
	game.navigate_back()
	if game.menu_page!="menu": failures.append("bag back returns to menu")
	game.navigate_back()
	if game.mode!="camp" or game.menu_page!="home": failures.append("menu back returns to camp")
	game.inventory_category=1
	game.open_inventory()
	if game.overlay.get_node("InventoryScroll").get_child(0).get_child_count()!=1 or game.materials!=12: failures.append("materials bag is read-only")
	game.open_collection()
	if game.discovered!=["boar","fox"]: failures.append("acquisition updates book")
	if not game.release_companion(second.id) or not game.discovered.has("fox"): failures.append("release keeps discovery history")
	var saved=Save.normalize(JSON.parse_string(JSON.stringify({"owned":game.owned,"squad":game.squad,"discovered":game.discovered,"next_id":game.next_id})),game.STATS.keys())
	if saved.repaired or not saved.discovered.has("fox"): failures.append("discovery JSON roundtrip")
	game.start_stage(false)
	game.in_combat=true
	game.open_game_menu()
	var time=game.stage_time
	var pos=game.player.pos
	game._process(0.1)
	if game.stage_time!=time or game.player.pos!=pos or not game.overlay.visible: failures.append("menu pauses actual combat loop")
	if not game.overlay.get_node("Navigation_companions").disabled: failures.append("combat party navigation disabled")
	game.open_inventory()
	if game.mode!="stage" or not game.overlay.visible: failures.append("combat inventory read-only route")
	game.resume_game()
	if game.overlay.visible or game.mode!="stage" or game.player.pos!=pos: failures.append("resume preserves field position")
	key(game,KEY_ESCAPE)
	if game.menu_page!="menu": failures.append("Escape opens menu")
	game.confirm_return()
	game.navigate_back()
	if game.menu_page!="menu" or game.mode!="stage": failures.append("return confirmation cancels back to menu")
	key(game,KEY_ESCAPE)
	if game.overlay.visible: failures.append("Escape resumes from menu")
	key(game,KEY_I)
	if game.menu_page!="inventory": failures.append("I opens bag")
	key(game,KEY_I)
	if game.overlay.visible: failures.append("I closes bag")
	game.mode="camp"
	game.in_combat=true
	game.open_game_menu()
	if game.overlay.get_node("Navigation_companions").disabled: failures.append("camp ignores old combat flag")
	game.owned.clear()
	game.squad.clear()
	game.open_inventory()
	game.open_collection()
	game.open_controls()
	game.navigate_back()
	if game.menu_page!="menu": failures.append("empty bag/book and controls navigation")
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty(): print("GAME MENU PASS: real bag contents, shared navigation/back, pause/resume position, keyboard, combat restrictions, persistent discovery history, empty states")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
