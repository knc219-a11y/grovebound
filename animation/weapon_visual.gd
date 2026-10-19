extends RefCounted
# Rigid weapon layer. Gameplay can swap this visual without changing actor stats.
var visuals={"staff":preload("res://assets/party-pixel/druid-staff-v2.png")}
var current="staff"
func register_visual(key:String,texture:Texture2D):
	if texture!=null: visuals[key]=texture
func set_visual(key:String)->bool:
	if not visuals.has(key): return false
	current=key
	return true
func texture(): return visuals.get(current)
func angle_for(actor)->float:
	if actor.get("channeling",false): return 0.16
	if actor.get("action_remaining",0.0)>0:
		var strength=pow(actor.action_remaining/maxf(0.001,actor.action_duration),1.5)
		return (-0.22 if actor.get("action_key","")=="heal" else -0.12)*strength
	if actor.get("pixel_moving",false):
		return sin(actor.get("pixel_phase",0.0)*TAU)*(0.035 if actor.get("pixel_running",false) else 0.015)
	return 0.0
func draw(canvas,position,height,face,tint,actor):
	var image=texture()
	if image==null: return
	var scale_value=maxf(1.0,roundf(float(height)/72.0))
	var bob=0.0
	if actor.get("pixel_moving",false):
		bob=-(2.0 if actor.get("pixel_running",false) else 0.65)*pow(sin(actor.get("pixel_phase",0.0)*TAU),2)
	var shown_face=actor.get("action_face",face) if actor.get("action_remaining",0.0)>0 and not actor.get("channeling",false) else face
	canvas.draw_set_transform_matrix(Transform2D(angle_for(actor)*shown_face,(position+Vector2(0,bob)).round()).scaled_local(Vector2(shown_face,1)*scale_value))
	canvas.draw_texture_rect(image,Rect2(-Vector2(24,72),image.get_size()),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
