extends "res://animation/pixel_gameplay_preview.gd"
# Isolated review fixture: actual UI and XP callbacks, no player saves.
var screen="roster"
var selected_id=-1
var training_shown=false
var still_captured=false
func _ready():
	super()
	owned.clear()
	squad.clear()
	loot_rng.seed=20261019
	var kinds=["boar","fox","deer","wolf","boar","turtle"]
	for i in kinds.size():
		var d=make_owned(kinds[i],3+i%2,Loot.roll(kinds[i],3+i%2,loot_rng,Loot.GRADES[i%3]))
		d.xp=100 if i==0 else 22+i*5
		d.favorite=i in [0,2]
		if i<4: squad.append(d.id)
	selected_id=owned[0].id
	if screen=="promotion":
		owned[0].level=20
		owned[0].xp=0
	materials=18
	mode="camp"
	in_combat=false
	screenshot_mode=true
	if screen=="promotion": show_promotion(selected_id)
	elif screen=="training": show_training(selected_id)
	elif screen=="target": show_target_training(selected_id)
	elif screen=="target_preview": preview_target_training(selected_id,8)
	elif screen=="receipt": train_companion(selected_id)
	elif screen=="filtered":
		roster_favorites_only=true
		roster_sort=2
		open_roster()
	elif screen=="level":
		start_stage(false)
		screenshot_mode=true
		player.pos=Vector2(1100,740)
		units[0].pos=player.pos+Vector2(65,50)
		enemies.clear()
		clear_overlay()
	else: open_roster()
func _process(dt):
	if "--capture-synthesis-still" in OS.get_cmdline_user_args() and clock>0.8 and not still_captured:
		still_captured=true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/synthesis-promotion-v1.png" if screen=="promotion" else "res://docs/synthesis-training-v1.png")
		get_tree().quit()
		return
	if screen=="level":
		combat_feedback.advance(dt)
		for i in range(effects.size()-1,-1,-1):
			effects[i].time-=dt
			if effects[i].time<=0: effects.remove_at(i)
		if clock>0.7 and not training_shown:
			training_shown=true
			gain_xp(find_owned(selected_id),40)
	elif screen=="flow":
		if clock>=1.1 and not training_shown:
			training_shown=true
			show_training(selected_id)
		if clock>=2.7 and materials==18: train_companion(selected_id)
	super(dt)
