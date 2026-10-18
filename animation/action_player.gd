extends RefCounted
# Event-triggered pixel poses. Damage/healing timing remains owned by gameplay.
var catalog={}
var textures={}
func _init():
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://animation/actions-v1.json"))
	for kind in catalog: textures[kind]=load(catalog[kind].texture)
func start(actor,kind,key):
	if actor.hp<=0 or not catalog.has(kind) or not catalog[kind].actions.has(key): return false
	# A routine strike must not cancel an explicit heal/guard/support gesture.
	if key in ["attack","support","cast"] and actor.get("action_remaining",0.0)>0 and actor.get("action_key","") in ["heal","guard"]: return false
	var duration=catalog[kind].actions[key].duration
	actor.action_face=actor.get("face",1.0)
	actor.action_key=key
	actor.action_duration=duration
	actor.action_remaining=duration
	return true
func advance(actor,dt):
	actor.action_remaining=maxf(0,actor.get("action_remaining",0.0)-dt)
	if actor.hp<=0:
		actor.action_remaining=0.0
		actor.channeling=false
func selection(kind,actor):
	if actor.hp<=0 or not catalog.has(kind): return {}
	var key=actor.get("action_key","")
	var phase=0.0
	if kind=="druid" and actor.get("channeling",false):
		key="revive"
		phase=fposmod(actor.get("channel_time",0.0),0.9)/0.9
	elif actor.get("action_remaining",0.0)>0:
		phase=1.0-actor.action_remaining/actor.action_duration
	elif kind=="turtle" and actor.get("shield",0.0)>0 and not actor.get("walk",false):
		key="guard"
	else: return {}
	if not catalog[kind].actions.has(key): return {}
	# Full-body stationary poses cannot replace travelling feet. Channeling is stationary.
	if actor.get("walk",false) and not actor.get("channeling",false): return {}
	var frames=catalog[kind].actions[key].frames
	return {"key":key,"region":frames[clampi(floori(phase*frames.size()),0,frames.size()-1)]}
func draw(canvas,position,height,face,tint,kind,actor):
	var chosen=selection(kind,actor)
	if chosen.is_empty(): return false
	var data=catalog[kind]
	var r=chosen.region
	var region=Rect2(r[0],r[1],r[2],r[3])
	var scale_value=maxf(1,roundf(float(height)/data.height))
	canvas.draw_set_transform_matrix(Transform2D(0,position.round()).scaled_local(Vector2(actor.get("action_face",face) if not actor.get("channeling",false) else face,1)*scale_value))
	canvas.draw_texture_rect_region(textures[kind],Rect2(-Vector2(data.ground[0],data.ground[1]),region.size),region,tint)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
