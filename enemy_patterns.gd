extends RefCounted
const Species=preload("res://creature_species.gd")
static func begin(e,target):
	var data=Species.NEW[e.kind]
	e.aim=target.pos if e.kind=="wraith" else e.pos if e.kind in ["golem","guardian"] else target.pos
	e.attack_kind="hex" if e.kind=="wraith" else "slam" if e.kind in ["golem","guardian"] else "bite"
	e.wind=data.wind; e.wind_total=e.wind; e.tell_radius=data.radius
	if absf(target.pos.x-e.pos.x)>1: e.face=signf(target.pos.x-e.pos.x)
static func boss(e,target):
	e.pattern+=1
	e.attack_kind="slam" if e.pattern%2 else "hex"
	e.aim=e.pos if e.attack_kind=="slam" else target.pos
	e.tell_radius=150.0 if e.attack_kind=="slam" else 100.0
	e.wind=1.2 if e.attack_kind=="slam" else 1.0
	e.wind_total=e.wind
	if absf(target.pos.x-e.pos.x)>1: e.face=signf(target.pos.x-e.pos.x)
static func resolve(g,e):
	e.swing=0.25
	var radius=e.get("tell_radius",56.0)
	var damage=(26.0 if e.boss else Species.NEW[e.kind].stats[1]+e.level*1.5)*(e.get("swarm_damage",0.4) if e.get("swarm",false) else 1.0)*e.get("damage_scale",1.0)
	for a in g.alive_allies():
		if a.pos.distance_to(e.aim)<=radius: g.damage_ally(a,damage,e.pos)
	g.combat_feedback.emit("stomp" if e.attack_kind=="slam" else "fox" if e.attack_kind=="hex" else "melee",e.pos,e.aim,0,{"radius":radius})
	e.cd=2.6 if e.boss else 2.0 if e.kind in ["golem","guardian","wraith"] else 1.5
