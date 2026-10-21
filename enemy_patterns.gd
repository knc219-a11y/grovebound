extends RefCounted
const Species=preload("res://creature_species.gd")
static func begin(e,target):
	var data=Species.NEW[e.kind]
	e.aim=target.pos if e.kind in ["wraith","shaman"] else e.pos if e.kind in ["golem","guardian","sentinel","cycle_guardian"] else target.pos
	e.attack_kind="hex" if e.kind in ["wraith","shaman"] else "slam" if e.kind in ["golem","guardian","sentinel","cycle_guardian"] else "bite"
	if e.kind=="thornling":
		e.attack_kind="cone"; configure_cone(e,target,145.0,0.65)
	e.wind=data.wind; e.wind_total=e.wind; e.tell_radius=data.radius
	if absf(target.pos.x-e.pos.x)>1: e.face=signf(target.pos.x-e.pos.x)
static func boss(e,target):
	e.pattern+=1
	e.attack_kind="hex" if e.get("boss_pattern","")=="hex" else "slam" if e.get("route_mid",false) or e.pattern%2 else "hex"
	var pattern=e.get("boss_pattern","")
	if pattern=="cone": e.attack_kind="cone"
	elif pattern=="frontline": e.attack_kind="cone" if e.pattern%2 else "slam"
	elif pattern=="ward": e.attack_kind="cone" if e.pattern%2 else "hex"
	elif pattern=="cycle": e.attack_kind=["cone","hex","slam"][(e.pattern-1)%3]
	e.aim=e.pos if e.attack_kind in ["slam","cone"] else target.pos
	e.tell_radius=150.0 if e.attack_kind=="slam" else 100.0
	e.wind=1.2 if e.attack_kind=="slam" else 1.0
	if e.attack_kind=="cone": configure_cone(e,target,210.0,0.7); e.wind=1.3
	if e.kind=="cycle_guardian" and e.hp<e.maxhp*0.5: e.wind=maxf(1.0,e.wind-0.15)
	e.wind_total=e.wind
	if absf(target.pos.x-e.pos.x)>1: e.face=signf(target.pos.x-e.pos.x)
static func configure_cone(e,target,radius,half_angle):
	e.aim=e.pos; e.origin=e.pos; e.cone_direction=(target.pos-e.pos).normalized()
	if e.cone_direction.length()<0.01: e.cone_direction=Vector2.RIGHT
	e.tell_radius=radius; e.cone_half_angle=half_angle
static func contains(e,p):
	if e.attack_kind!="cone": return p.distance_to(e.aim)<=e.get("tell_radius",56.0)
	var delta=p-e.origin
	return delta.length()<=e.tell_radius and (delta.length()<0.001 or absf(e.cone_direction.angle_to(delta))<=e.cone_half_angle)
static func resolve(g,e):
	e.swing=0.25
	var radius=e.get("tell_radius",56.0)
	var damage=(e.get("boss_damage",26.0) if e.boss else Species.NEW[e.kind].stats[1]+e.level*1.5)*(e.get("swarm_damage",0.4) if e.get("swarm",false) else 1.0)*e.get("damage_scale",1.0)
	for a in g.alive_allies():
		if contains(e,a.pos): g.damage_ally(a,damage,e.pos)
	g.combat_feedback.emit("stomp" if e.attack_kind=="slam" else "fox" if e.attack_kind=="hex" else "melee",e.pos,e.aim,0,{"radius":radius})
	e.cd=2.6 if e.boss else 2.0 if e.kind in ["golem","guardian","wraith","shaman","sentinel","cycle_guardian"] else 1.5
