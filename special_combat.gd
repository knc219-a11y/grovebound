extends RefCounted
const Special=preload("res://special_companions.gd")
static func barrier(unit,ratio,seconds):
	unit.special_barrier=maxf(unit.get("special_barrier",0.0),unit.maxhp*ratio)
	unit.barrier_time=maxf(unit.get("barrier_time",0.0),seconds)
static func advance(g,u,dt):
	for key in ["special_guard","team_guard","barrier_time"]:
		u[key]=maxf(0,u.get(key,0.0)-dt)
	if u.barrier_time<=0 or u.hp<=0: u.special_barrier=0.0
	if u.hp<=0:
		u.erase("special_action")
		return
	if not u.has("special_action"): return
	var action=u.special_action
	action.time-=maxf(0,dt)
	if action.time>0: return
	if action.kind=="echo":
		g.combat_feedback.emit("skill_fox",u.pos,action.center,0,{"radius":action.radius})
		for e in g.combat_enemies():
			if e.hp>0 and e.pos.distance_to(action.center)<=action.radius:
				g.hit_enemy(e,action.damage,action.origin,u,false,true)
		u.erase("special_action")
	else:
		var target=action.target
		if not g.combat_enemies().has(target) or target.hp<=0 or target.pos.distance_to(u.pos)>430:
			target=g.Roles.target(u.data.kind,u.pos,g.combat_enemies(),g.player.pos,430)
		if target.is_empty(): u.erase("special_action"); return
		g.hit_enemy(target,action.damage,u.pos,u,true,true)
		action.target=target
		action.remaining-=1
		action.time=0.12
		if action.remaining<=0: u.erase("special_action")
static func cast(g,u,target):
	var d=u.data
	if not Special.ready(d): return false
	if d.kind not in ["deer","turtle"] and target.is_empty(): return false
	u.erase("pending_basic")
	var power=g.attack(d)*(1.0+u.get("buff_power",0.6) if u.buff>0 else 1.0)
	match d.kind:
		"boar": g.Assault.begin_dash(g,u,target,power*3.5)
		"fox": g.Assault.begin_blast(g,u,target,power*2.5)
		"marten": u.special_action={"kind":"marten","target":target,"remaining":3,"time":0.0,"damage":power*1.5}
		"wolf":
			g.hit_enemy(target,power*3.5,u.pos,u,true,true)
			target.hunt_owner=d.id
			target.hunt_time=5.0
		"bat":
			var center=target.pos
			g.element_feedback.emit(d,u.pos,center,true,100)
			g.hit_enemy(target,power*3.5,u.pos,u,true,true)
			for e in g.combat_enemies():
				if e!=target and e.hp>0 and e.pos.distance_to(center)<=100:
					g.hit_enemy(e,power,u.pos,u,false,true)
		"turtle":
			g.motion_actions.start(u,"turtle","guard")
			u.shield=6.0 if Special.element(d)=="fire" else 5.0
			for e in g.combat_enemies():
				if e.hp>0 and e.pos.distance_to(u.pos)<270:
					e.active=true
					e.taunt=u
					e.taunt_time=5.0
					if e.wind<=0 and e.get("dash",0.0)<=0:
						e.aim=u.pos
						e.pos=e.pos.move_toward(u.pos,35)
			for ally in g.alive_allies():
				if ally.pos.distance_to(u.pos)<=270: ally.team_guard=maxf(ally.get("team_guard",0.0),3.0)
		"deer":
			g.element_feedback.emit(d,u.pos,u.pos,true,350*Special.radius(d))
			for ally in g.alive_allies():
				if ally.pos.distance_to(u.pos)<350*Special.radius(d):
					g.heal(ally,35*(1.25 if d.trait=="다정함" else 1.0),u.pos,u)
					barrier(ally,0.05,4.0)
	# Every completed 4+ star role can open the guardian's armor, including support.
	for e in g.combat_enemies():
		if e.hp>0 and e.get("cycle_guard",false) and e.get("active",false) and e.pos.distance_to(u.pos)<=600:
			e.cycle_open=6.0
	if d.kind not in ["boar","fox"]: g.combat_feedback.emit("skill_"+d.kind,u.pos,u.pos if target.is_empty() else target.pos)
	if Special.unique(d)=="barrier": barrier(u,0.10,4.0)
	if Special.evolution(d)=="barrier": barrier(u,Special.evolution_value(d,"barrier"),Special.evolution_values(d).barrier_seconds)
	g.Roles.signal_action(u,Special.SKILLS[d.kind])
	g.Roles.add_metric(u,"skills",1)
	g.combat_feedback.emit("special_rune",u.pos,u.pos,0,{"tint":Special.ELEMENTS[Special.element(d)].color,"caption":Special.SKILLS[d.kind]})
	u.skill=10.0*(1.0-g.Loot.bonus(d,"skill_haste"))*Special.haste(d)
	return true
