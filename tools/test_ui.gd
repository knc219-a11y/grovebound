extends SceneTree
const Review=preload("res://animation/ui_review.gd")
func _initialize(): call_deferred("check_ui")
func check_ui():
	var game=Review.new()
	game.screen="hud"
	game.set_process(false)
	root.add_child(game)
	await process_frame
	await process_frame
	var failures=[]
	if game.party_buttons.size()!=4: failures.append("four party cards")
	if not is_equal_approx(game.player_hp_bar.value,135): failures.append("player health binding")
	if game.player_hp_bar.size.y>12 or game.boss_hp_bar.size.y>8 or game.interact_progress.size.y>7: failures.append("thin bars do not inherit percentage font height")
	var rects=[]
	for b in game.party_buttons+[game.heal_button,game.buff_button]:
		var r=b.get_global_rect()
		if r.size.x<140 or r.size.y<100 or not Rect2(0,0,1440,810).encloses(r): failures.append("main touch control bounds")
		for other in rects:
			if other.intersects(r): failures.append("overlapping main controls")
		rects.append(r)
	if not game.party_buttons[0].disabled or not game.party_buttons[2].disabled: failures.append("cooldown/down card disabled")
	if game.party_buttons[0].cooldown<=0 or game.party_buttons[2].hp!=0: failures.append("card state binding")
	game.units[0].skill=0
	game.units[0].pos=game.enemies[0].pos+Vector2(-40,0)
	game.update_hud()
	game.party_buttons[0].pressed.emit()
	if game.units[0].skill<=0 or game.units[1].skill>0: failures.append("card callback uses correct slot")
	game.heal_cd=0
	game.revive_target=-1
	game.player.hp=100
	game.update_hud()
	game.heal_button.pressed.emit()
	if game.heal_cd<=0: failures.append("heal callback")
	game.mode="camp"
	game.open_roster()
	await process_frame
	await process_frame
	var scroll: ScrollContainer
	for child in game.overlay.get_children():
		if child is ScrollContainer: scroll=child
	if scroll==null: failures.append("roster scroll")
	else:
		var row=scroll.get_child(0).get_child(0)
		if row.size.x>scroll.size.x: failures.append("roster action row fits")
		var portrait=row.get_child(0)
		if not portrait is TextureRect or portrait.texture==null: failures.append("roster portraits")
	game.show_camp()
	if not game.overlay.visible or game.mode!="camp": failures.append("camp navigation")
	game.units.clear()
	game.mode="stage"
	game.update_hud()
	for b in game.party_buttons:
		if b.occupied or not b.disabled: failures.append("empty slots reset")
	game.free()
	if failures.is_empty():
		print("UI PASS: health/card state, thin bars, main touch bounds, no overlap, skill ownership, heal callback, roster layout/portraits, camp navigation, empty slots")
		quit()
	else:
		push_error(str(failures))
		quit(1)
