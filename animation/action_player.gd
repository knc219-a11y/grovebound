extends RefCounted
# Event-triggered pixel poses. Damage/healing timing remains owned by gameplay.
var catalog={}
var textures={}
var attack_textures={}
var support_textures={}
func _init():
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://animation/actions-v1.json"))
	for kind in catalog: textures[kind]=load(catalog[kind].texture)
	for kind in ["boar","wolf","marten","fox"]:
		if ResourceLoader.exists("res://assets/attacks-v2/"+kind+".png"):
			attack_textures[kind]=load("res://assets/attacks-v2/"+kind+".png")
			catalog[kind].actions["cast" if kind=="fox" else "attack"].duration=0.42
	for kind in ["deer","turtle"]:
		if ResourceLoader.exists("res://assets/attacks-v2/"+kind+".png"):
			support_textures[kind]=load("res://assets/attacks-v2/"+kind+".png")
			catalog[kind].actions["heal" if kind=="deer" else "guard"].duration=0.6
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
	# Enemy bite anticipation keeps its existing .65s wind-up and hit timing.
	if attack_textures.has(kind) and actor.get("wind",0.0)>0 and not actor.get("boss",false):
		return {"key":"cast" if kind=="fox" else "attack","region":[112,0,112,104],"dedicated":true}
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
	if key==("heal" if kind=="deer" else "guard") and support_textures.has(kind):
		# Healing/shield already applies immediately: begin on the release/brace pose.
		var index=clampi(2+floori(phase*4),2,5)
		if kind=="turtle" and actor.get("shield",0.0)>0: index=mini(index,3)
		return {"key":key,"region":[index*112,0,112,104],"support_art":true}
	if key==("cast" if kind=="fox" else "attack") and attack_textures.has(kind) and not actor.get("boss",false):
		# Enemy impact starts after its existing wind-up; allies start with anticipation.
		var index=clampi(floori(phase*6),0,5)
		if actor.has("kind") and not actor.get("boss",false): index=clampi(2+floori(phase*4),2,5)
		return {"key":key,"region":[index*112,0,112,104],"dedicated":true}
	var frames=catalog[kind].actions[key].frames
	return {"key":key,"region":frames[clampi(floori(phase*frames.size()),0,frames.size()-1)]}
func draw(canvas,position,height,face,tint,kind,actor):
	var chosen=selection(kind,actor)
	if chosen.is_empty(): return false
	var data=catalog[kind]
	var r=chosen.region
	var region=Rect2(r[0],r[1],r[2],r[3])
	var scale_value=maxf(1,roundf(float(height)/data.height))
	var shown_face=face if actor.get("wind",0.0)>0 else actor.get("action_face",face) if not actor.get("channeling",false) else face
	canvas.draw_set_transform_matrix(Transform2D(0,position.round()).scaled_local(Vector2(shown_face,1)*scale_value))
	var texture=attack_textures[kind] if chosen.get("dedicated",false) else textures[kind]
	if chosen.get("support_art",false): texture=support_textures[kind]
	canvas.draw_texture_rect_region(texture,Rect2(-Vector2(data.ground[0],data.ground[1]),region.size),region,tint)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
