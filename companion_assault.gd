extends RefCounted
# Allied skills only. Wild enemy attacks keep their existing behavior.
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
	u.assault={"kind":"blast","from":u.pos,"to":target.pos,"elapsed":0.0,"damage":damage}
	if absf(target.pos.x-u.pos.x)>1: u.face=signf(target.pos.x-u.pos.x)
	u.walk=false
	g.motion_actions.start(u,"fox","cast")
	g.combat_feedback.emit("fox_charge",u.pos,target.pos,0,{"radius":BLAST_RADIUS})
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
			g.hit_enemy(e,action.damage,u.pos,u,false)
			if not e.boss: e.pos=(e.pos+(action.to-action.from).normalized()*28).clamp(Vector2(170,345),Vector2(2740,1130))
		if action.elapsed>=DASH_TIME: u.erase("assault")
	else:
		u.walk=false
		if action.elapsed>=BLAST_DELAY:
			g.combat_feedback.emit("skill_fox",action.from,action.to,0,{"radius":BLAST_RADIUS})
			for e in g.combat_enemies():
				if e.hp>0 and e.pos.distance_to(action.to)<=BLAST_RADIUS:
					g.hit_enemy(e,action.damage,action.from,u,false)
					if not e.boss: e.pos=(e.pos+(e.pos-action.to).normalized()*20).clamp(Vector2(170,345),Vector2(2740,1130))
			u.erase("assault")
	return true
