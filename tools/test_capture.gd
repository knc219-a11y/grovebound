extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check_capture")
func check_capture():
	var game=Preview.new()
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	var failures=[]
	game.start_stage(false)
	for enemy in game.enemies:
		if enemy.guaranteed: failures.append("normal stage must not guarantee capture")
	game.units.clear()
	game.enemies.clear()
	game.captures.clear()
	game.rng.seed=20261019
	for i in 1000:
		game.spawn_enemy("boar",Vector2(700,700))
		game.hit_enemy(game.enemies[-1],10000,Vector2.ZERO)
	var count=game.captures.size()
	if count<110 or count>190: failures.append("capture chance outside expected 15 percent seeded range")
	var before=count
	game.spawn_enemy("boar",Vector2(700,700),1,true,true)
	game.hit_enemy(game.enemies[-1],10000,Vector2.ZERO)
	if game.captures.size()!=before: failures.append("boss cannot be captured")
	game.tutorial_species="boar"
	game.start_stage(true)
	game.hit_enemy(game.enemies[0],10000,Vector2.ZERO)
	if game.captures.size()!=1: failures.append("first tutorial capture remains guaranteed")
	if game.enemies[0].death!=0: failures.append("capture pose replaces corpse without overlap")
	var visual=game.capture_visual
	if visual.catalog.size()!=6: failures.append("six capture species present")
	for kind in visual.catalog:
		var image=visual.textures[kind].get_image()
		var standing=game.boar_rig.idle_texture.get_image().get_region(Rect2i(12,14,70,48)) if kind=="boar" else game.textures[kind].get_image()
		for i in 4:
			var bounds=image.get_region(Rect2i(i*112,0,112,104)).get_used_rect()
			if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=112 or bounds.end.y>=104: failures.append(kind+" capture frame clipped")
			if bounds.size.y>=standing.get_used_rect().size.y: failures.append(kind+" low pose must differ from standing")
	print("CAPTURE seeded opportunities: ",count," / 1000")
	if failures.is_empty(): print("CAPTURE PASS: 15 percent, no stage guarantees, tutorial guaranteed, boss excluded, six low poses")
	else: push_error(str(failures))
	game.queue_free()
	quit(0 if failures.is_empty() else 1)
