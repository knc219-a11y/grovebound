extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Special=preload("res://special_companions.gd")
var errors=[]
var g
func check(condition,message):
	if not condition: errors.append(message)
func record(kind,element="wind",unique=""):
	var d=Loot.roll(kind,40,g.loot_rng,3)
	d.id=99
	d.trait="강인함"
	d=Loot.roll_special(d,kind,g.loot_rng)
	d.options=[]
	d.special.affixes=[]
	d.special.state="ready"
	d.special.element=element
	d.special.unique=unique if not unique.is_empty() else Special.choices(kind).keys()[0]
	return d
func prepare(kind,element="wind",unique=""):
	g.clear_overlay()
	g.mode="stage"
	g.current_stage=1
	g.trail.reset()
	g.enemies.clear()
	g.units.clear()
	g.player.pos=Vector2(1000,800)
	g.player.hp=g.player.maxhp
	g.player.erase("team_guard")
	g.player.erase("special_barrier")
	g.player.erase("barrier_time")
	var d=record(kind,element,unique)
	var u=g.make_unit(d,Vector2(1000,800))
	g.units.append(u)
	return u
func enemy(pos):
	g.spawn_enemy("boar",pos,1,false)
	var e=g.enemies[-1]
	e.hp=100000
	e.maxhp=100000
	return e
func _init(): call_deferred("run")
func run():
	g=load("res://animation/pixel_gameplay_preview.gd").new()
	root.add_child(g)
	g.set_process(false)
	g.screenshot_mode=true
	# Star4 curve preserves old star1-3 and is relative to result species, before bonuses.
	var d=record("wolf","wind","skill")
	var old=d.duplicate(true)
	old.star=3
	old.level=40
	old.erase("special")
	check(is_equal_approx(g.max_hp(d)/g.max_hp(old),0.7) and is_equal_approx(g.attack(d)/g.attack(old),0.7),"4-star level1 raw70 percent")
	d.level=15
	check(is_equal_approx(g.attack(d)/g.attack(old),1.008),"level15 recovery")
	d.level=50
	check(is_equal_approx(g.attack(d)/g.attack(old),1.778),"level50 curve")
	# Shared attributes and position uniques have concrete, separate effects.
	check(Special.ELEMENTS.keys().size()==4 and Special.ELEMENTS.has("water"),"four shared elements")
	var u=prepare("wolf","fire","basic")
	var e=enemy(Vector2(1030,800))
	var hp=e.hp
	g.hit_enemy(e,100,u.pos,u,false,false)
	check(is_equal_approx(hp-e.hp,126.5),"fire and basic unique")
	hp=e.hp
	g.hit_enemy(e,100,u.pos,u,false,true)
	check(is_equal_approx(hp-e.hp,110),"basic unique excludes skills")
	u=prepare("turtle","earth","guard")
	u.data.trait="용맹함"
	hp=u.hp
	g.damage_ally(u,100,g.player.pos)
	check(is_equal_approx(hp-u.hp,100*0.95*0.92),"earth and guard reductions")
	g.SpecialCombat.barrier(u,0.1,4)
	var shield=u.special_barrier
	g.SpecialCombat.barrier(u,0.05,4)
	check(u.special_barrier==shield,"barriers do not stack")
	g.SpecialCombat.advance(g,u,4.1)
	check(u.special_barrier==0,"barrier expires")
	# Approved water cooldown multiplies affix and unique reductions once.
	u=prepare("fox","water","haste")
	u.data.special.affixes=[{"key":"skill_haste","value":10}]
	e=enemy(Vector2(1040,800))
	g.use_companion_skill(0)
	check(is_equal_approx(u.skill,10*0.85*0.88*0.90),"water actual15 percent with unique and affix")
	# Boar retains swept collision, then gains guard only after actual dash.
	u=prepare("boar","wind","barrier")
	e=enemy(Vector2(1090,800))
	g.use_companion_skill(0)
	check(u.has("assault") and u.get("special_guard",0)==0 and u.special_barrier>0 and is_equal_approx(u.skill,9.0),"boar actual cast and wind cooldown")
	g.Assault.advance(g,u,0.25)
	check(u.special_guard==3 and e.hp<e.maxhp,"boar guard after dash")
	# Fox fixed delayed area, reach and exactly one echo.
	u=prepare("fox","wind","reach")
	e=enemy(Vector2(1040,800))
	var outer=enemy(Vector2(1235,800))
	g.use_companion_skill(0)
	g.Assault.advance(g,u,0.23)
	check(outer.hp<outer.maxhp and u.has("special_action"),"fox extended radius and scheduled echo")
	hp=e.hp
	g.SpecialCombat.advance(g,u,0.59)
	check(e.hp==hp,"echo waits")
	g.SpecialCombat.advance(g,u,0.02)
	check(e.hp<hp and not u.has("special_action"),"echo hits once")
	hp=e.hp
	g.SpecialCombat.advance(g,u,1.0)
	check(e.hp==hp,"no recursive echo")
	# Marten can transfer remaining hits to a nearby live enemy.
	u=prepare("marten","wind","skill")
	e=enemy(Vector2(1040,800))
	e.hp=1
	var second=enemy(Vector2(1050,800))
	g.use_companion_skill(0)
	for i in 3: g.SpecialCombat.advance(g,u,0.13)
	check(e.hp==0 and second.hp<second.maxhp and not u.has("special_action"),"marten retargets remaining hits")
	# Wolf's marked follow-up, not the initial hit, receives the bonus.
	u=prepare("wolf","wind","skill")
	e=enemy(Vector2(1040,800))
	g.use_companion_skill(0)
	hp=e.hp
	g.hit_enemy(e,100,u.pos,u,false,false)
	check(is_equal_approx(hp-e.hp,120) and e.hunt_owner==u.data.id,"wolf owner mark")
	# Bat splash excludes primary target and does not chain itself.
	u=prepare("bat","wind","skill")
	e=enemy(Vector2(1040,800))
	second=enemy(Vector2(1100,800))
	g.use_companion_skill(0)
	check(is_equal_approx((e.maxhp-e.hp)/(second.maxhp-second.hp),3.5),"bat primary not double hit")
	# Turtle team mitigation; fire improves own shield duration only.
	u=prepare("turtle","fire","vital")
	g.use_companion_skill(0)
	check(u.shield==6 and g.player.team_guard==3,"turtle fire and team protection")
	check(Special.damage(u.data,false,{"hp":100,"maxhp":100})==1.0,"fire turtle does not gain an unapproved attack bonus")
	hp=g.player.hp
	g.damage_ally(g.player,100,u.pos)
	check(is_equal_approx(hp-g.player.hp,85),"team mitigation actual damage")
	# Deer applies both fire and potency to healing and adds a percent-maxHP barrier.
	u=prepare("deer","fire","potency")
	g.player.hp-=100
	hp=g.player.hp
	g.use_companion_skill(0)
	check(is_equal_approx(g.player.hp-hp,35*1.15*1.15) and is_equal_approx(g.player.special_barrier,g.player.maxhp*0.05),"deer healing and barrier")
	# Death cancels pending effects; stage entry protections apply to new splash/echo hits.
	u=prepare("fox","wind","potency")
	e=enemy(Vector2(1040,800))
	g.use_companion_skill(0)
	g.Assault.advance(g,u,0.23)
	u.hp=0
	hp=e.hp
	g.SpecialCombat.advance(g,u,1)
	check(e.hp==hp and not u.has("special_action"),"death cancels echo")
	g.player.team_guard=3.0
	g.player.special_barrier=100.0
	g.player.barrier_time=4.0
	g.reset_player_visual_state()
	check(g.player.get("team_guard",0)==0 and g.player.get("special_barrier",0)==0,"support effects reset between expeditions")
	g.queue_free()
	await process_frame
	if errors.is_empty(): print("SPECIAL COMBAT PASS: curve70/100.8/177.8, four-element catalog, actual attribute/unique effects, all seven upgraded skills, barrier nonstack/expiry, primary splash exclusion, echo delay and death cancellation")
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
