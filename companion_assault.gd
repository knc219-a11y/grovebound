extends RefCounted
# Allied skills only. Wild enemy attacks keep their existing behavior.
const Special=preload("res://special_companions.gd")
const DASH_TIME=0.24
const DASH_WIDTH=52.0
const BLAST_DELAY=0.22
const BLAST_RADIUS=180.0
static func begin_dash(g,u,target,damage):
	var direction=(target.pos-u.pos).normalized()
	if direction.length()<0.01: direction=Vector2.RIGHT
	var endpoint=(target.pos+direction*95).clamp(Vector2(170,345),Vector2(2740,1130))
	u.assault={"kind":"dash","from":u.pos,"to":endpoint,"elapsed":0.0,"damage":damage,"hits":[]}
	if absf(direction.x)>0.01: u.face=signf(direction.x)
	u.walk=false
	g.motion_actions.start(u,"boar","attack")
	g.combat_feedback.emit("skill_boar",u.pos,endpoint,0,{"radius":DASH_WIDTH})
static func begin_blast(g,u,target,damage):
	u.assault={"kind":"blast","from":u.pos,"to":target.pos,"elapsed":0.0,"damage":damage,"radius":BLAST_RADIUS*Special.radius(u.data)}
	if absf(target.pos.x-u.pos.x)>1: u.face=signf(target.pos.x-u.pos.x)
	u.walk=false
	g.motion_actions.start(u,"fox","cast")
	g.combat_feedback.emit("fox_charge",u.pos,target.pos,0,{"radius":u.assault.radius})
static func advance(g,u,dt):
	if not u.has("assault"): return false
	if u.hp<=0:
		u.erase("assault")
		return false
	var action=u.assault
	action.elapsed+=maxf(0,dt)
	if action.kind=="dash":
		var previous=u.pos
		u.pos=action.from.lerp(action.to,clampf(action.elapsed/DASH_TIME,0,1))
		u.walk=true
		for e in g.combat_enemies():
			if e.hp<=0 or action.hits.has(e.get("feedback_id",-1)): continue
			var closest=Geometry2D.get_closest_point_to_segment(e.pos,previous,u.pos)
			if e.pos.distance_to(closest)>DASH_WIDTH: continue
			action.hits.append(e.get("feedback_id",-1))
			e.stun=maxf(e.stun,1.5)
			g.hit_enemy(e,action.damage,u.pos,u,false,true)
			if not e.boss: e.pos=(e.pos+(action.to-action.from).normalized()*28).clamp(Vector2(170,345),Vector2(2740,1130))
		if action.elapsed>=DASH_TIME:
			if Special.ready(u.data): u.special_guard=maxf(u.get("special_guard",0.0),3.0)
			u.erase("assault")
	else:
		u.walk=false
		if action.elapsed>=BLAST_DELAY:
			g.combat_feedback.emit("skill_fox",action.from,action.to,0,{"radius":action.get("radius",BLAST_RADIUS)})
			g.element_feedback.emit(u.data,action.from,action.to,true,action.get("radius",BLAST_RADIUS))
			for e in g.combat_enemies():
				if e.hp>0 and e.pos.distance_to(action.to)<=action.get("radius",BLAST_RADIUS):
					g.hit_enemy(e,action.damage,action.from,u,false,true)
					if not e.boss: e.pos=(e.pos+(e.pos-action.to).normalized()*20).clamp(Vector2(170,345),Vector2(2740,1130))
			if Special.ready(u.data):
				u.special_action={"kind":"echo","time":0.6,"center":action.to,"origin":action.from,"radius":action.get("radius",BLAST_RADIUS),"damage":action.damage/2.5}
			u.erase("assault")
	return true
