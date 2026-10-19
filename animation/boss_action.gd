extends RefCounted
# Visual state follows existing combat timers; never owns attack collision.
var texture:Texture2D
static func headroom(actor,height):
	return height*64.0/48.0 if actor.get("boss",false) and actor.get("hp",0)>0 and actor.get("wind",0.0)>0 and actor.get("attack_kind","")=="stomp" else height
func _init():
	if ResourceLoader.exists("res://assets/attacks-v2/boar-boss.png"):
		texture=load("res://assets/attacks-v2/boar-boss.png")
static func pose(actor):
	if not actor.get("boss",false) or actor.get("hp",0)<=0: return {}
	var kind=actor.get("attack_kind","")
	if actor.get("dash",0.0)>0:
		# Compressed and extended painted strides follow distance, not screen shake.
		return {"row":1,"column":int(actor.get("rig_phase",0.0)/TAU*4)%2,"key":"charge_run"}
	if actor.get("wind",0.0)>0:
		return {"row":0 if kind=="stomp" else 1,"column":0,"key":kind+"_tell"}
	var remaining=actor.get("boss_recovery",0.0)
	if actor.get("walk",false): return {} # Never slide a planted recovery pose during pursuit.
	if remaining>0:
		return {"row":0 if kind=="stomp" else 1,"column":1 if kind=="stomp" and remaining>0.24 else 2,"key":kind+"_recovery"}
	return {}
func draw(canvas,position,height,face,tint,actor):
	if texture==null: return false
	var chosen=pose(actor)
	if chosen.is_empty(): return false
	var region=Rect2(chosen.column*112,chosen.row*104,112,104)
	canvas.draw_set_transform_matrix(Transform2D(0,position.round()).scaled_local(Vector2(face,1)*height/48.0))
	canvas.draw_texture_rect_region(texture,Rect2(-56,-94,112,104),region,tint)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
