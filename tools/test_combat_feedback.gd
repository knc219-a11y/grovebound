extends SceneTree
const Feedback=preload("res://animation/combat_feedback.gd")
const Preview=preload("res://animation/full_gameplay_preview.gd")
func _initialize(): call_deferred("check_feedback")
func check_feedback():
	var failures=[]
	var feedback=Feedback.new()
	feedback.emit("melee",Vector2.ZERO,Vector2(30,0),7,{"target_id":1})
	feedback.emit("melee",Vector2.ZERO,Vector2(30,0),5,{"target_id":1})
	if feedback.numbers.size()!=1 or feedback.numbers[0].amount!=12: failures.append("same target same burst aggregates")
	feedback.emit("melee",Vector2.ZERO,Vector2(30,0),3,{"target_id":2})
	if feedback.numbers.size()!=2: failures.append("overlapping targets remain independent")
	feedback.advance(0.13)
	feedback.emit("melee",Vector2.ZERO,Vector2(30,0),4,{"target_id":1})
	if feedback.numbers.size()!=3 or feedback.numbers[2].pos==feedback.numbers[0].pos: failures.append("later hit gets separate number lane")
	for i in range(150): feedback.emit("heal",Vector2.ZERO,Vector2(i*4,0),1,{"target_id":i+10})
	if feedback.events.size()>Feedback.MAX_EVENTS or feedback.numbers.size()>Feedback.MAX_NUMBERS: failures.append("bounded feedback")
	feedback.advance(2.0)
	if not feedback.events.is_empty() or not feedback.numbers.is_empty(): failures.append("expired feedback cleaned")
	var game=Preview.new()
	game.preview_events=false
	game.set_process(false)
	root.add_child(game)
	var enemy=game.enemies[0]
	var fox=game.units[3]
	game.combat_feedback.clear()
	var hp=enemy.hp
	game.hit_enemy(enemy,10,fox.pos,fox)
	if enemy.hp!=hp-10 or game.combat_feedback.events[-1].kind!="fox": failures.append("fox hit is immediate and has own effect")
	var target=game.units[0]
	target.hp=target.maxhp-3
	game.combat_feedback.clear()
	game.heal(target,55,game.player.pos,game.player)
	if target.hp!=target.maxhp or game.combat_feedback.numbers[0].amount!=3: failures.append("heal text shows actual restoration")
	game.combat_feedback.clear()
	var tank=game.units[1]
	tank.hp=tank.maxhp
	tank.shield=5
	var before=tank.hp
	game.damage_ally(tank,20,enemy.pos)
	if not game.combat_feedback.numbers[0].blocked or absf(game.combat_feedback.numbers[0].amount-(before-tank.hp))>0.001: failures.append("guard feedback matches reduced damage")
	game.combat_feedback.clear()
	enemy.pattern=0
	game.begin_boss_attack(enemy,game.player)
	if enemy.wind_total!=enemy.wind: failures.append("stomp tell tracks actual countdown")
	enemy.pattern=1
	game.begin_boss_attack(enemy,game.player)
	if enemy.wind_total!=enemy.wind or enemy.attack_kind!="charge": failures.append("charge tell tracks actual countdown")
	for kind in ["boar","wolf","marten","fox"]:
		game.combat_feedback.clear()
		game.revive_target=-1
		game.clear_overlay()
		game.mode="stage"
		enemy.hp=enemy.maxhp
		game.units=[game.make_unit(game.make_owned(kind,1),enemy.pos-Vector2(80,0))]
		game.use_companion_skill(0)
		var found=false
		for event in game.combat_feedback.events:
			if event.kind=="skill_"+kind: found=true
		if not found or game.units[0].skill!=10.0 or enemy.hp>=enemy.maxhp: failures.append(kind+" skill burst follows real damage and cooldown")
	game.start_stage(false)
	if not game.combat_feedback.events.is_empty() or not game.combat_feedback.numbers.is_empty(): failures.append("stage clears feedback")
	game.free()
	if failures.is_empty():
		print("COMBAT FEEDBACK PASS: aggregation, identity, number lanes, limits/cleanup, instant fox hit, actual healing, shield damage, tell countdown, stage clear")
		quit()
	else:
		push_error(str(failures))
		quit(1)
