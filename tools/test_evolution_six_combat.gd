extends "res://tools/test_special_combat.gd"
func evolve(u,ability):
	u.data.star=6
	u.data.level=60
	u.data.special.evolution={"version":1,"state":"ready","ability":ability,"enhanced":true}
	u.maxhp=g.max_hp(u.data)
	u.hp=u.maxhp
	return u
func run():
	g=load("res://animation/pixel_gameplay_preview.gd").new()
	root.add_child(g)
	g.set_process(false)
	g.screenshot_mode=true
	var u=evolve(prepare("boar","earth","vital"),"vital")
	check(is_equal_approx(Special.hp_bonus(u.data),0.57),"HP additions sum")
	u=evolve(prepare("turtle","earth","guard"),"guard")
	u.data.trait="용맹함"
	var hp=u.hp
	g.damage_ally(u,100,g.player.pos)
	check(is_equal_approx(hp-u.hp,100*0.95*0.92*0.88),"actual stacked mitigation")
	u=evolve(prepare("boar","water","barrier"),"barrier")
	var e=enemy(Vector2(1080,800))
	g.use_companion_skill(0)
	check(is_equal_approx(u.special_barrier,u.maxhp*0.20) and u.barrier_time==6,"actual stronger shield replaces4-star shield")
	g.SpecialCombat.barrier(u,0.10,4)
	check(is_equal_approx(u.special_barrier,u.maxhp*0.20) and u.barrier_time==6,"shield nonstack")
	g.SpecialCombat.advance(g,u,6.1)
	check(u.special_barrier==0,"6-star shield expires")
	for ability in ["basic","skill","execute"]:
		u=evolve(prepare("wolf","fire","basic"),ability)
		e=enemy(Vector2(1040,800))
		e.hp=e.maxhp*0.50
		hp=e.hp
		g.hit_enemy(e,100,u.pos,u,false,false)
		check(is_equal_approx(hp-e.hp,100*1.10*1.15*(1.30 if ability in ["basic","execute"] else 1.0)),"actual basic branch "+ability)
		hp=e.hp
		g.hit_enemy(e,100,u.pos,u,false,true)
		check(is_equal_approx(hp-e.hp,100*1.10*(1.30 if ability in ["skill","execute"] else 1.0)),"actual skill branch "+ability)
		if ability=="execute":
			e.hp=e.maxhp*0.51
			hp=e.hp
			g.hit_enemy(e,100,u.pos,u,false,true)
			check(is_equal_approx(hp-e.hp,110),"execute threshold excludes above50")
	u=evolve(prepare("deer","fire","potency"),"potency")
	g.player.hp-=100
	hp=g.player.hp
	g.use_companion_skill(0)
	check(is_equal_approx(g.player.hp-hp,35*1.15*1.15*1.30),"actual healing multiplicative")
	u=evolve(prepare("fox","water","haste"),"haste")
	u.data.special.affixes=[{"key":"skill_haste","value":10}]
	e=enemy(Vector2(1040,800))
	g.use_companion_skill(0)
	check(is_equal_approx(u.skill,10*0.90*0.85*0.88*0.85),"actual cooldown composed once")
	u=evolve(prepare("fox","wind","reach"),"reach")
	e=enemy(Vector2(1040,800))
	var outer=enemy(Vector2(1270,800))
	g.use_companion_skill(0)
	g.Assault.advance(g,u,0.23)
	check(outer.hp<outer.maxhp,"fox combined radius actual hit")
	hp=outer.hp
	g.SpecialCombat.advance(g,u,0.61)
	check(outer.hp<hp and not u.has("special_action"),"6-star echo once")
	u=evolve(prepare("deer","water","reach"),"reach")
	g.player.pos=Vector2(1480,800)
	g.player.hp-=100
	hp=g.player.hp
	g.use_companion_skill(0)
	check(g.player.hp>hp,"deer expanded heal actual radius")
	u=evolve(prepare("fox","fire","potency"),"potency")
	e=enemy(Vector2(1040,800))
	hp=e.hp
	g.hit_enemy(e,100,u.pos,u,false,true)
	check(is_equal_approx(hp-e.hp,100*1.10*1.15*1.30),"fox potency actual skill damage")
	# All seven upgraded skills remain active at star6; full star4 suite is run separately.
	for kind in ["boar","turtle","marten","wolf","bat","fox","deer"]:
		u=prepare(kind,"water",Special.choices(kind).keys()[0])
		evolve(u,Special.evolution_choices(kind).keys()[0])
		e=enemy(Vector2(1080,800))
		g.use_companion_skill(0)
		check(u.skill>0 and Special.ready(u.data),"retained upgraded skill "+kind)
	g.queue_free()
	await process_frame
	if errors.is_empty(): print("EVOLUTION SIX COMBAT PASS: all9 abilities actual damage/heal/cooldown/radius/shield and HP, multiplicative composition, thresholds, nonstack/expiry, echo once, all7 upgraded skills retained")
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
