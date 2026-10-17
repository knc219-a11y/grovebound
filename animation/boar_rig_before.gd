extends RefCounted
# Eight painted cutout parts; no per-frame image generation or screen capture.
# Coordinates are authored in a 100px-high space, with the ground at y=0.
const REGIONS = [Rect2(35,74,523,387), Rect2(589,44,451,408), Rect2(1106,131,182,312), Rect2(1484,102,196,336), Rect2(166,531,193,297), Rect2(622,522,184,302), Rect2(1055,581,208,164)]
var atlas: Texture2D

func _init(texture: Texture2D):
	atlas=texture

func advance(actor, dt):
	var last=actor.get("rig_last",actor.pos)
	var distance=actor.pos.distance_to(last)
	actor["rig_last"]=actor.pos
	var moving=actor.get("walk",false) and actor.hp>0 and distance>0.01
	# Distance, rather than world position or wall time, drives the feet.
	var stride=76.0 if not actor.get("boss",false) else 112.0
	if moving: actor["rig_phase"]=fmod(actor.get("rig_phase",0.0)+minf(distance,35.0)/stride*TAU,TAU)
	actor["rig_move"]=lerpf(actor.get("rig_move",0.0),1.0 if moving else 0.0,1.0-exp(-dt*12.0))
	actor["rig_time"]=actor.get("rig_time",0.0)+dt
	actor["rig_down"]=move_toward(actor.get("rig_down",0.0),1.0 if actor.hp<=0 else 0.0,dt/0.3)

func draw(canvas: Node2D, position: Vector2, height: float, face: float, tint: Color, actor):
	var phase=actor.get("rig_phase",0.0)
	var weight=actor.get("rig_move",0.0)
	var time=actor.get("rig_time",0.0)
	var down=smoothstep(0.0,1.0,actor.get("rig_down",0.0))
	var wind=actor.get("wind",0.0)>0 and actor.hp>0
	var charge=actor.get("dash",0.0)>0 and actor.hp>0
	var swing=clampf(actor.get("swing",0.0)/0.22,0.0,1.0)
	var strike=sin((1.0-swing)*PI) if swing>0 else 0.0
	var breath=sin(time*2.4)*0.6*(1.0-weight)
	var body_lift=-absf(sin(phase*2.0))*0.9*weight+breath
	var root=Transform2D(-0.95*down,position+Vector2(0,9*down)*height/100.0)
	root=root.scaled_local(Vector2(face,1)*height/100.0)
	# Far legs -> tail -> torso -> near legs -> head. Upper joints stay hidden.
	var leg_amount=0.43*weight*(1.25 if charge else 1.0)*(1.0-down)
	leg(canvas,root,4,Vector2(19,-44),sin(phase+PI)*leg_amount,0.9,tint)
	leg(canvas,root,5,Vector2(-32,-43),sin(phase)*leg_amount,0.9,tint)
	part(canvas,root,6,Vector2(-49,-57+body_lift),sin(time*3.0)*0.09,Rect2(-23,-10,28,22),tint)
	part(canvas,root,0,Vector2(0,body_lift),-0.025*strike,Rect2(-57,-89,96,68),tint)
	leg(canvas,root,3,Vector2(-37,-42+body_lift),sin(phase+PI)*leg_amount+0.35*down,1.0,tint)
	leg(canvas,root,2,Vector2(16,-43+body_lift),sin(phase)*leg_amount-0.3*down,1.0,tint)
	var head_angle=0.22 if wind or charge else 0.0
	head_angle+=0.12*swing-0.32*strike+sin(time*2.4-0.4)*0.012
	part(canvas,root,1,Vector2(12+strike*3,-59+body_lift+down*3),head_angle,Rect2(-12,-36,67,61),tint)
	canvas.draw_set_transform(Vector2.ZERO)

func leg(canvas,root,index,pivot,angle,scale_leg,tint):
	part(canvas,root,index,pivot,angle,Rect2(-9,-5,23*scale_leg,48*scale_leg),tint)

func part(canvas,root,index,pivot,angle,destination,tint):
	canvas.draw_set_transform_matrix(root*Transform2D(angle,pivot))
	canvas.draw_texture_rect_region(atlas,destination,REGIONS[index],tint,false,true)
