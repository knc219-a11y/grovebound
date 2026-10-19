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
	game.dropdown.toggle.pressed.emit()
	await process_frame
	await process_frame
	var grid=game.dropdown.grid
	if grid.columns!=5 or grid.get_child_count()!=7: failures.append("five-column menu with seven real actions")
	for i in grid.get_child_count():
		var tile=grid.get_child(i)
		if not Rect2(0,0,1440,810).encloses(tile.get_global_rect()): failures.append("dropdown within viewport")
		if i<5 and tile.position.y!=grid.get_child(0).position.y: failures.append("first five share row")
	if grid.get_child(5).position.y<=grid.get_child(0).position.y or grid.get_child(5).position.x!=grid.get_child(0).position.x: failures.append("sixth wraps to next row")
	for i in 4:
		var extra=Button.new()
		extra.custom_minimum_size=Vector2(104,96)
		grid.add_child(extra)
	await process_frame
	await process_frame
	if grid.get_child(10).position.y<=grid.get_child(5).position.y: failures.append("future entries wrap to third row")
	var click=InputEventMouseButton.new()
	click.position=Vector2(700,740)
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=true
	root.push_input(click,true)
	await process_frame
	if game.dropdown.popup.visible or game.overlay.visible: failures.append("outside click dismisses without navigating")
	click.pressed=false
	root.push_input(click,true)
	game.dropdown.open()
	game.dropdown.grid.get_node("Navigation_inventory").pressed.emit()
	if game.dropdown.popup.visible: failures.append("selection closes dropdown")
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
	if game.mode!="camp" or game.overlay.visible: failures.append("menu back returns to camp")
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
	game.dropdown.open()
	if not game.dropdown.grid.get_node("Navigation_companions").disabled: failures.append("combat party navigation disabled")
	game.dropdown.close()
	game.open_inventory()
	if game.mode!="stage" or not game.overlay.visible: failures.append("combat inventory read-only route")
	game.resume_game()
	if game.overlay.visible or game.mode!="stage" or game.player.pos!=pos: failures.append("resume preserves field position")
	key(game,KEY_ESCAPE)
	if not game.dropdown.popup.visible: failures.append("Escape opens dropdown")
	game._process(0.1)
	if game.stage_time!=time or game.player.pos!=pos or game.can_act(): failures.append("dropdown pauses field and blocks actions")
	key(game,KEY_ESCAPE)
	if game.dropdown.popup.visible or game.player.pos!=pos: failures.append("Escape closes dropdown preserving position")
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
	game.dropdown.open()
	if game.dropdown.grid.get_node("Navigation_companions").disabled: failures.append("camp ignores old combat flag")
	game.dropdown.close()
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
	if failures.is_empty(): print("GAME MENU PASS: five-column dropdown/wrapping, outside dismissal, real bag contents, navigation/back, pause/resume position, keyboard, combat restrictions, persistent discovery history, empty states")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
