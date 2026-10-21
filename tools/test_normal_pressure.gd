extends SceneTree
const Game=preload("res://animation/pixel_gameplay_preview.gd")
const R=preload("res://campaign_routes.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Game.new(); root.add_child(g); g.set_process(false)
	g.show_camp(); g.clear_overlay(); g.owned.clear(); g.squad.clear()
	g.squad=[g.make_owned("boar",24).id]
	g.start_stage(false,5,R.coordinate(5,8)); g.enemies.clear(); g.clear_overlay()
	g.spawn_enemy("cycle_guardian",Vector2(900,800),20,true)
	var e=g.enemies[0]; e.boss_pattern="cycle"; e.boss_pressure=true; e.boss_damage=75.0; e.maxhp=8400; e.hp=e.maxhp
	g.units[0].pos=Vector2(1000,800); g.player.pos=Vector2(600,700)
	g.begin_boss_attack(e,g.units[0]); assert(e.attack_kind=="cone" and e.extra_aims.is_empty())
	g.begin_boss_attack(e,g.units[0]); assert(e.attack_kind=="hex" and e.extra_aims==[g.player.pos] and e.wind>=1.2)
	var locked=e.extra_aims.duplicate(); var aim=e.aim
	g.player.pos=locked[0]+Vector2(0,91)
	var hp=g.player.hp; g.resolve_enemy_attack(e); assert(g.player.hp==hp and e.extra_aims==locked and e.aim==aim)
	g.player.pos=locked[0]+Vector2(0,89); hp=g.player.hp
	g.resolve_enemy_attack(e); assert(is_equal_approx(hp-g.player.hp,75.0))
	# Overlapping primary and extra circles deal one hit, not two.
	e.aim=g.player.pos; e.extra_aims=[g.player.pos]; g.player.hp=180; g.resolve_enemy_attack(e); assert(g.player.hp==105)
	assert(e.cd==2.0)
	e.hp=e.maxhp*0.4; e.pattern=3; g.begin_boss_attack(e,g.units[0]); assert(e.wind>=1.2)
	for theme in [4,5]:
		for stage in range(1,9):
			var p=R.profile(R.coordinate(theme,stage))
			assert(p.enemy_hp_scale>1.0 and p.damage_scale>=0.95)
			if stage in [4,8]: assert(p.boss_pressure and p.boss_damage in [60.0,75.0,95.0])
	e.cycle_guard=true; e.cycle_open=0; e.hp=24000; e.maxhp=e.hp
	var before=e.hp; g.hit_enemy(e,1000,g.player.pos,g.player,false); assert(is_equal_approx(before-e.hp,0.0))
	for kind in ["boar","turtle","marten","wolf","bat","fox","deer"]:
		var d=g.Loot.roll_special(g.owned[0],kind,g.loot_rng)
		d.level=15; d.special.state="ready"; d.special.element="earth"; d.special.unique=g.Special.choices(kind).keys()[0]
		var unit=g.make_unit(d,e.pos+Vector2(-40,0))
		g.units=[unit]; e.active=true; e.cycle_open=0
		assert(g.SpecialCombat.cast(g,unit,e) and e.cycle_open==6.0)
	before=e.hp; g.hit_enemy(e,1000,g.player.pos,g.player,false); assert(is_equal_approx(before-e.hp,1000.0))
	g.player.pos=Vector2(300,350)
	for i in 121: g.update_game(0.05)
	assert(e.cycle_open==0)
	# Earlier routes and legacy encounters do not acquire late-campaign pressure.
	assert(not R.profile(R.coordinate(1,8)).has("boss_pressure"))
	g.start_stage(false,2); assert(g.enemies.all(func(enemy): return not enemy.get("boss_pressure",false)))
	g.free()
	print("NORMAL PRESSURE PASS: locked player tells, 1.2s warning, inside/outside damage, overlap once, recovery, route-only pressure and untouched legacy")
	quit()
