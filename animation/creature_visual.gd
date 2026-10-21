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
	if actor.get("swing",0.0)>0: frame=3
	elif actor.get("wind",0.0)>0:
		var progress=1.0-actor.wind/maxf(0.001,actor.get("wind_total",actor.wind))
		frame=3 if progress>=0.40 else 0
	elif actor.get("walk",false): frame=1+int(actor.get("creature_phase",0.0)*2)%2
	elif kind=="bat": frame=1+int(actor.get("creature_idle",0.0)*4)%2
	var scale_value=height/float(Species.NEW[kind].height)
	var tilt=-0.65*face if actor.get("hp",1)<=0 else 0.0
	g.draw_set_transform_matrix(Transform2D(tilt,position.round()).scaled_local(Vector2(face,1)*scale_value))
	g.draw_texture_rect_region(sheets[kind],Rect2(-56,-94,112,104),Rect2(frame*112,0,112,104),color)
	g.draw_set_transform(Vector2.ZERO)
	if actor.get("hp",1)>0: attack_cue(g,position,height,face,kind,actor)
	return true

func attack_cue(g,p,height,face,kind,actor):
	var wind=actor.get("wind",0.0)
	var swing=actor.get("swing",0.0)
	if wind<=0 and swing<=0: return
	var source=(p+Vector2(face*height*0.20,-height*0.45)).round()
	var ranged=kind in ["wraith","shaman"]
	var c=Color("c9b1db") if ranged else Color("edbd81")
	if wind>0:
		var progress=clampf(1.0-wind/maxf(0.001,actor.get("wind_total",wind)),0.0,1.0)
		# Preparation is attached to the hand/mouth; the existing ground tell owns targeting.
		c.a=0.35+progress*0.45
		g.draw_arc(source,3+progress*5,-PI,PI*0.5,12,c,1,false)
		return
	var t=clampf(1.0-swing/0.25,0.0,1.0)
	c.a=1.0-t
	if ranged:
		var target=p+(actor.get("aim",actor.pos)-actor.pos)-Vector2(0,18)
		if t<0.40: g.draw_line(source,target.round(),Color(c,c.a*0.65),2,false)
		g.draw_arc(target.round(),4+t*12,0,TAU,16,c,2,false)
	elif kind in ["skeleton","guardian","sentinel","cycle_guardian"]:
		# A short blade/shield sweep identifies the instant of the existing hit.
		var angle=0.0 if face>0 else PI
		g.draw_arc(source,12+t*15,angle-1.1+t*0.7,angle+0.6+t*0.7,12,c,3,false)
		var tip=source+Vector2(face*(14+t*14),-5+t*8)
		g.draw_line(source,tip.round(),Color("eee4bd",c.a),2,false)
	elif kind in ["golem","slime"]:
		g.draw_set_transform(p.round(),0,Vector2(1,0.4))
		g.draw_arc(Vector2.ZERO,9+t*20,0,TAU,20,c,2,false)
		g.draw_set_transform(Vector2.ZERO)
	else:
		for i in 2:
			var jaw=source+Vector2(face*(5+t*14),(i*2-1)*(7-t*5))
			g.draw_line(jaw.round(),(jaw+Vector2(face*8,(1-i*2)*4)).round(),c,2,false)
