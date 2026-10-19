extends RefCounted
const DruidPose=preload("res://animation/druid_pose.gd")
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
func in_front(actor): return not DruidPose.active_key(actor).is_empty()
func angle_for(actor)->float:
	if not DruidPose.active_key(actor).is_empty(): return DruidPose.angle(actor)
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
	var stationary=not actor.get("walk",false) and not actor.get("pixel_moving",false)
	var shown_face=actor.get("action_face",face) if stationary and actor.get("action_remaining",0.0)>0 and not actor.get("channeling",false) else face
	var tilt=-0.75*shown_face*smoothstep(0,1,actor.get("pixel_down",1.0 if actor.hp<=0 else 0.0))
	var body=Transform2D(tilt,(position+Vector2(0,bob)).round()).scaled_local(Vector2(shown_face,1)*scale_value)
	var grip=Transform2D(angle_for(actor),DruidPose.mount(actor))
	canvas.draw_set_transform_matrix(body*grip)
	canvas.draw_texture_rect(image,Rect2(-Vector2(32,36),image.get_size()),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
