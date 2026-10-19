extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.enemies.clear()
	g.spawn_enemy("boar",Vector2(1000,800),9)
	var enemy=g.enemies[0]
	var failures=[]
	for kind in ["boar","wolf"]:
		var d=g.make_owned(kind,1)
		var u=g.make_unit(d,Vector2(955,800))
		var hp=enemy.hp
		if not g.begin_basic_attack(u,enemy,7): failures.append(kind+" start")
		if enemy.hp!=hp: failures.append(kind+" damage before impact")
		g.advance_basic_attack(u,0.13)
		if enemy.hp!=hp: failures.append(kind+" early damage")
		g.advance_basic_attack(u,0.011)
		if enemy.hp!=hp-7: failures.append(kind+" exact hit")
		g.advance_basic_attack(u,0.2)
		if enemy.hp!=hp-7: failures.append(kind+" duplicate damage")
		g.begin_basic_attack(u,enemy,7)
		u.hp=0
		g.advance_basic_attack(u,0.2)
		if enemy.hp!=hp-7: failures.append(kind+" dead attacker hits")
		u.hp=100
		g.begin_basic_attack(u,enemy,7)
		u.pos=Vector2.ZERO
		g.advance_basic_attack(u,0.2)
		if enemy.hp!=hp-7: failures.append(kind+" remote hit")
		if not g.motion_actions.attack_textures.has(kind): failures.append(kind+" dedicated art missing")
		else:
			var image=g.motion_actions.attack_textures[kind].get_image()
			var unique={}
			for i in 6:
				var frame=image.get_region(Rect2i(i*112,0,112,104))
				var box=frame.get_used_rect()
				if box.position.x<=0 or box.position.y<=0 or box.end.x>=112 or box.end.y>=104: failures.append(kind+" dedicated art clipped")
				if box.size.y>49: failures.append(kind+" native height changed")
				unique[frame.get_data().hex_encode().sha256_text()]=true
			if unique.size()<4: failures.append(kind+" dedicated poses not distinct")
	if failures.is_empty(): print("ATTACK TIMING PASS: no early/double/dead/remote hit, dedicated boar/wolf art, exact .14 second impact")
	else: push_error(str(failures))
	g.free()
	quit(0 if failures.is_empty() else 1)
