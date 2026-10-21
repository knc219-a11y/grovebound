extends Control
const Tile=preload("res://ui/menu_tile.gd")
const UI=preload("res://ui/grove_ui.gd")
var game
var popup:Control
var toggle:Button
var grid:GridContainer
func setup(g):
	game=g
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	size=Vector2(1440,810)
	popup=Control.new()
	popup.size=size
	add_child(popup)
	popup.gui_input.connect(func(e):
		if (e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
			close()
			accept_event())
	popup.hide()
	toggle=Tile.new()
	toggle.position=Vector2(1356,18)
	toggle.size=Vector2(64,62)
	toggle.tooltip_text="메뉴 [Esc]"
	toggle.focus_mode=Control.FOCUS_NONE
	toggle.pressed.connect(toggle_menu)
	add_child(toggle)
func toggle_menu():
	if popup.visible: close()
	else: open()
func close():
	popup.hide()
	toggle.queue_redraw()
func open():
	for child in popup.get_children():
		popup.remove_child(child)
		child.queue_free()
	var box=PanelContainer.new()
	box.position=Vector2(814,92)
	box.add_theme_stylebox_override("panel",UI.frame(Color("202823")))
	popup.add_child(box)
	var margin=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	box.add_child(margin)
	grid=GridContainer.new()
	grid.name="MenuGrid"
	grid.columns=5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	margin.add_child(grid)
	var entries=[
		["inventory","가방",game.open_inventory],
		["druid","주인공",game.open_hero],
		["equipment","장비",func(): game.open_hero(1)],
		["skills","지원 스킬",func(): game.open_hero(2)],
		["shop","장비 상점",func(): game.open_hero(3)],
		["companions","동료",game.open_roster],
		["collection","도감",game.open_collection],
		["menu","여정",game.open_game_menu],
		["controls","조작",game.open_controls],
		["materials","재료",func(): game.inventory_category=1; game.open_inventory()],
		["home","캠프",func():
			if game.mode=="camp": game.resume_game()
			else: game.confirm_return()]]
	for entry in entries:
		var b=Tile.new()
		b.name="Navigation_"+entry[0]
		b.symbol=entry[0]
		b.tooltip_text=entry[1]
		b.custom_minimum_size=Vector2(104,96)
		b.add_theme_font_size_override("font_size",18)
		b.pressed.connect(func(): close(); entry[2].call())
		grid.add_child(b)
		var caption=Label.new()
		caption.text=entry[1]
		caption.position=Vector2(0,56)
		caption.size=Vector2(104,28)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.add_child(caption)
		if entry[0]=="companions": b.disabled=(game.in_combat and game.mode=="stage") or game.mode=="tutorial"
		caption.modulate=Color("827b68") if b.disabled else Color.WHITE
	game.stick=Vector2.ZERO
	game.mouse_stick=false
	game.stick_id=-1
	game.holding_revive=false
	game.revive_touch_id=-1
	popup.show()
