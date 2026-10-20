extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	var failures=[]
	for kind in ["boar","wolf","marten","fox","turtle","deer"]:
		g.owned.clear(); g.squad.clear()
		var d=g.make_owned(kind,3,{"kind":kind,"level":3,"xp":0,"trait":"강인함","grade":"common","options":[]})
		g.squad=[d.id]
		g.start_stage(false)
		g.player.pos=Vector2(700,700)
		g.units[0].pos=g.player.pos+Vector2(40,0)
		g.units[0].hp=g.units[0].maxhp-50
		g.enemies.clear()
		g.spawn_enemy("boar",Vector2(830,700),4,true)
		var hp=g.enemies[0].hp
		var unit_hp=g.units[0].hp
		g.combat_feedback.clear()
		g.use_companion_skill(0)
		if kind in ["boar","fox"]: g.Assault.advance(g,g.units[0],0.25)
		var count=0
		for e in g.combat_feedback.events:
			if e.kind=="skill_"+kind: count+=1
		if count!=1: failures.append(kind+" unique skill visual")
		var expected=g.attack(d)*(2.5 if kind=="fox" else 3.5) if kind not in ["deer","turtle"] else 0
		if not is_equal_approx(hp-g.enemies[0].hp,expected): failures.append(kind+" damage changed")
		if kind=="deer" and not is_equal_approx(g.units[0].hp-unit_hp,35): failures.append("healing changed")
		if not is_equal_approx(g.units[0].skill,10): failures.append(kind+" cooldown changed")
		var events=g.combat_feedback.events.size()
		g.use_companion_skill(0)
		if g.combat_feedback.events.size()!=events: failures.append(kind+" cooldown repeats visual")
	if failures.is_empty(): print("SKILL VISUAL PASS: six successful casts each emit one distinct cue, failed cooldown silent, single-target damage/healing/cooldown preserved, assault resolved at impact")
	else: push_error(str(failures))
	g.free()
	quit(0 if failures.is_empty() else 1)
