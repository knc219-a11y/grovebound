extends SceneTree
const Review=preload("res://animation/town_review.gd")
const Town=preload("res://town.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Review.new()
	root.add_child(g)
	g.set_process(false)
	var failures=[]
	g.player.pos=Vector2(540,510)
	g.town_position=g.player.pos
	g.update_hud()
	g.interact_button.pressed.emit()
	if not g.overlay.visible: failures.append("management interaction")
	g.resume_game()
	var p=g.player.pos
	g.open_inventory()
	g._process(0.03)
	g.resume_game()
	if g.player.pos!=p or g.overlay.visible: failures.append("menu position preservation")
	for b in Town.BUILDINGS:
		var pos=Vector2(b.get_center().x,b.end.y+20)
		for i in 100: pos=Town.move(pos,Vector2(0,-3))
		if b.grow(12).has_point(pos): failures.append("building collision")
	g.player.pos=Town.POINTS[2]
	g.tutorial_done=false
	g.town_interact()
	if g.menu_page!="starters": failures.append("tutorial departure")
	g.resume_game()
	g.tutorial_species="boar"
	g.start_stage(true)
	if g.mode!="tutorial" or g.enemies.size()!=1: failures.append("tutorial preserved")
	g.show_camp()
	if g.mode!="camp" or g.player.pos!=Town.POINTS[2] or not g.enemies.is_empty(): failures.append("return to town")
	g.start_stage(false)
	if g.enemies.size()<10: failures.append("original hunting area")
	g.show_camp()
	if g.can_act(): failures.append("town combat blocked")
	g.dropdown.open()
	if g.dropdown.grid.columns!=5: failures.append("five column menu")
	if failures.is_empty(): print("PASS town movement/collision/menu/tutorial/departure/return/combat isolation")
	else: print("FAIL ",failures)
	g.queue_free()
	quit(0 if failures.is_empty() else 1)
