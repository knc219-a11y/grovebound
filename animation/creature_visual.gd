extends RefCounted
const Species=preload("res://creature_species.gd")
var sheets={}
func _init():
	for kind in Species.NEW:
		var path="res://assets/campaign/"+kind+"-v1.png"
		if ResourceLoader.exists(path): sheets[kind]=load(path)
func portrait(kind):
	if not sheets.has(kind): return null
	var result=AtlasTexture.new()
	result.atlas=sheets[kind]
	result.region=Rect2(sheets[kind].get_image().get_region(Rect2i(0,0,112,104)).get_used_rect())
	return result
func advance(actor,dt):
	var distance=actor.pos.distance_to(actor.get("creature_last",actor.pos))
	actor.creature_last=actor.pos
	if actor.get("walk",false) and distance<100:
		actor.creature_phase=fposmod(actor.get("creature_phase",0.0)+distance/32.0,1.0)
	actor.creature_idle=actor.get("creature_idle",0.0)+dt
func draw(g,position,height,face,color,kind,actor):
	if not sheets.has(kind): return false
	var frame=0
	if actor.get("wind",0.0)>0 or actor.get("swing",0.0)>0: frame=3
	elif actor.get("walk",false): frame=1+int(actor.get("creature_phase",0.0)*2)%2
	elif kind=="bat": frame=1+int(actor.get("creature_idle",0.0)*4)%2
	var scale_value=height/float(Species.NEW[kind].height)
	var tilt=-0.65*face if actor.get("hp",1)<=0 else 0.0
	g.draw_set_transform_matrix(Transform2D(tilt,position.round()).scaled_local(Vector2(face,1)*scale_value))
	g.draw_texture_rect_region(sheets[kind],Rect2(-56,-94,112,104),Rect2(frame*112,0,112,104),color)
	g.draw_set_transform(Vector2.ZERO)
	return true
