extends SceneTree
const Preview=preload("res://animation/full_gameplay_preview.gd")
func _initialize(): call_deferred("check_events")
func check_events():
	var game=Preview.new()
	game.preview_events=false
	game.set_process(false)
	root.add_child(game)
	var failures=[]
	# Movement easing may change arrival time, but never overshoots attack stop distance.
	var mover={"pos":Vector2(800,700),"face":1.0,"walk":false}
	game.move_entity(mover,Vector2(900,700),100.0,0.05,20.0)
	if mover.pos.x<=800 or mover.pos.x>=805: failures.append("companion eases departure")
	for step in 120: game.move_entity(mover,Vector2(900,700),100.0,0.05,20.0)
	if absf(mover.pos.x-880)>0.001: failures.append("companion reaches stop without overshoot")
	mover.face=1.0
	game.move_entity(mover,mover.pos+Vector2(-5,100),100.0,0.05)
	if mover.face!=1.0: failures.append("near vertical travel keeps facing")
	game.move_entity(mover,mover.pos+Vector2(-100,0),100.0,0.05)
	if mover.face!=-1.0: failures.append("deliberate turn changes facing")
	var actions=game.motion_actions
	# Every baked role has visible variation and padding around every frame.
	for kind in actions.catalog:
		var data=actions.catalog[kind]
		var image=actions.textures[kind].get_image()
		for key in data.actions:
			var unique={}
			for r in data.actions[key].frames:
				var frame=image.get_region(Rect2i(r[0],r[1],r[2],r[3]))
				var bounds=frame.get_used_rect()
				if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=112 or bounds.end.y>=104: failures.append(kind+" "+key+" clipped")
				unique[frame.get_data().hex_encode().sha256_text()]=true
			if unique.size()<2: failures.append(kind+" "+key+" static action")
	for kind in ["deer","turtle"]:
		if not actions.support_textures.has(kind): failures.append(kind+" dedicated support art missing"); continue
		var probe={"hp":100.0,"face":1.0,"walk":false,"shield":5.0 if kind=="turtle" else 0.0}
		actions.start(probe,kind,"heal" if kind=="deer" else "guard")
		if not actions.selection(kind,probe).get("support_art",false): failures.append(kind+" support art routing")
		probe.walk=true
		if not actions.selection(kind,probe).is_empty(): failures.append(kind+" support pose slides while travelling")
		probe.walk=false
		actions.advance(probe,1.0)
		if kind=="turtle":
			if not actions.selection(kind,probe).get("support_art",false): failures.append("shield does not hold brace pose")
			probe.shield=0.0
		if not actions.selection(kind,probe).is_empty(): failures.append(kind+" support expires after effect")
		var image=actions.support_textures[kind].get_image()
		for i in 6:
			var box=image.get_region(Rect2i(i*112,0,112,104)).get_used_rect()
			if box.position.x<=0 or box.position.y<=0 or box.end.x>=112 or box.end.y>=104: failures.append(kind+" support art clipped")
			if box.size.y>(64 if kind=="deer" else 32): failures.append(kind+" support scale changed")
	var enemy=game.enemies[0]
	var marten=game.units[0]
	var turtle=game.units[1]
	var deer=game.units[2]
	var fox=game.units[3]
	var hp=enemy.hp
	game.hit_enemy(enemy,7,marten.pos,marten)
	if enemy.hp!=hp-7 or marten.get("action_key","")!="attack": failures.append("damage event starts exact attack owner")
	if fox.get("action_remaining",0)>0: failures.append("other actor must stay independent")
	game.hit_enemy(enemy,3,fox.pos,fox)
	if fox.get("action_key","")!="cast": failures.append("fox cast event")
	game.heal(marten,10,deer.pos,deer)
	if deer.get("action_key","")!="heal": failures.append("deer heal event")
	game.heal_cd=0
	game.cast_heal()
	if game.player.get("action_key","")!="heal": failures.append("druid heal event")
	actions.advance(game.player,1.0)
	game.buff_cd=0
	game.cast_buff()
	if game.player.get("action_key","")!="support": failures.append("druid buff event")
	game.use_companion_skill(1)
	if turtle.shield<=0 or turtle.get("action_key","")!="guard": failures.append("turtle guard event")
	actions.advance(turtle,1.0)
	turtle.walk=false
	if actions.selection("turtle",turtle).get("key","")!="guard": failures.append("stationary shield holds guard")
	# Channeling is driven by the actual hold/revive logic, not a preview timer.
	marten.hp=0
	marten.pos=game.player.pos+Vector2(25,0)
	game.holding_revive=true
	game.update_game(0.1)
	if not game.player.get("channeling",false) or actions.selection("druid",game.player).get("key","")!="revive": failures.append("revive hold drives channel pose")
	game.heal_cd=0
	game.cast_heal()
	if game.heal_cd!=0: failures.append("channel blocks skills")
	game.holding_revive=false
	game.update_game(0.1)
	if game.player.get("channeling",false): failures.append("interrupt ends channel")
	var probe={"hp":100.0,"face":-1.0,"walk":false}
	actions.start(probe,"wolf","attack")
	probe.face=1.0
	if probe.action_face!=-1.0: failures.append("attack keeps event facing")
	probe.walk=true
	if not actions.selection("wolf",probe).is_empty(): failures.append("travel does not slide in stationary attack pose")
	probe.walk=false
	if actions.selection("wolf",probe).is_empty(): failures.append("stationary attack pose remains available")
	actions.start(probe,"wolf","attack")
	actions.advance(probe,1.0)
	if not actions.selection("wolf",probe).is_empty(): failures.append("action expires")
	actions.start(probe,"wolf","attack")
	probe.hp=0
	actions.advance(probe,0.01)
	if not actions.selection("wolf",probe).is_empty(): failures.append("death suppresses action")
	game.free()
	if failures.is_empty():
		print("ACTION EVENTS PASS: native frame variation/bounds, damage owner, fox cast, deer heal, druid heal/buff, turtle guard, channel/interrupt/skill block, expiry/death")
		quit()
	else:
		push_error(str(failures))
		quit(1)
