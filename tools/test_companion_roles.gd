extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Roles=preload("res://companion_roles.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	var failures=[]
	g.owned.clear()
	g.squad.clear()
	for entry in [["turtle","단단함"],["deer","다정함"],["marten","용맹함"],["wolf","민첩함"]]:
		var d=g.make_owned(entry[0],1,{"kind":entry[0],"level":1,"xp":0,"trait":entry[1],"grade":"common","options":[]})
		d.trait=entry[1]
		g.squad.append(d.id)
	g.start_stage(false)
	g.enemies.clear()
	g.player.pos=Vector2(700,700)
	for p in [Vector2(800,700),Vector2(900,700),Vector2(920,740)]: g.spawn_enemy("boar",p)
	var a=g.enemies[0]
	var b=g.enemies[1]
	var c=g.enemies[2]
	c.hp=1
	b.stun=1
	if Roles.target("marten",Vector2(750,700),g.enemies,g.player.pos,410)!=b: failures.append("marten prioritizes stunned")
	if Roles.target("wolf",Vector2(750,700),g.enemies,g.player.pos,410)!=c: failures.append("wolf prioritizes low HP")
	if Roles.target("turtle",Vector2(900,700),g.enemies,g.player.pos,410)!=a: failures.append("turtle protects player side")
	if Roles.target("fox",Vector2(750,700),g.enemies,g.player.pos,410)!=b: failures.append("fox clustered target")
	if not Roles.target("wolf",Vector2.ZERO,g.enemies,g.player.pos,10).is_empty(): failures.append("target search radius preserved")
	var tank=g.units[0]
	tank.hp=tank.maxhp
	tank.shield=5
	var old=tank.hp
	g.damage_ally(tank,100,Vector2.ZERO)
	if absf(old-tank.hp-34)>0.001 or absf(tank.contribution.mitigation-66)>0.001: failures.append("real mitigation and existing trait/shield")
	var healer=g.units[1]
	tank.hp=tank.maxhp-3
	g.heal(tank,15,healer.pos,healer)
	if healer.contribution.healing!=3: failures.append("exclude overheal")
	var attacker=g.units[2]
	c.hp=5
	g.hit_enemy(c,40,attacker.pos,attacker)
	if attacker.contribution.damage!=5: failures.append("exclude overkill")
	g.use_companion_skill(0)
	if tank.contribution.skills!=1 or tank.role_action!="도발 · 방어" or absf(tank.skill-10.0*(1.0-g.Loot.bonus(tank.data,"skill_haste")))>0.001: failures.append("real skill signal and unchanged cooldown")
	g.show_camp()
	var saved=g.expedition.report.contributions.duplicate(true)
	g.report_contributions=true
	g.show_run_report()
	g.show_run_report()
	if g.expedition.report.contributions!=saved: failures.append("read-only contribution replay")
	g.loot_rng.seed=20261019
	for i in 500:
		if g.Loot.roll("deer",1,g.loot_rng).trait=="용맹함": failures.append("new healer has unusable attack trait")
	var legacy={"kind":"deer","level":1,"trait":"용맹함","grade":"common","options":[]}
	g.Loot.normalize(legacy)
	if legacy.trait!="용맹함": failures.append("legacy trait preserved")
	if failures.is_empty(): print("PASS companion roles: target priorities/ranges, exact damage/healing/mitigation, skill timing, immutable recap, future trait fit and legacy retention")
	else: push_error(str(failures))
	g.queue_free()
	quit(0 if failures.is_empty() else 1)
