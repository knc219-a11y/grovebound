extends RefCounted
# Connected upper-body mesh with hidden leg roots. No neck cut or shoulder patch.
# Coordinates are authored in a 100px-high space, with the ground at y=0.
const REGIONS = [Rect2(35,74,523,387), Rect2(589,44,451,408), Rect2(1106,131,182,312), Rect2(1484,102,196,336), Rect2(166,531,193,297), Rect2(622,522,184,302), Rect2(1055,581,208,164)]
var atlas: Texture2D
var body: Texture2D
const COLUMNS=16
const ROWS=8
var body_region=Rect2(39,102,1469,740)
var still_mesh: ArrayMesh

func _init(texture: Texture2D):
	atlas=texture
	body=load("res://assets/boar-body-connected.png")
	# Opaque silhouette bounds; ignore the generator's faint transparent padding.
	still_mesh=build_body_mesh(0.0,0.0,0.0)

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
	# All leg roots are under the unbroken belly silhouette, never on top of it.
	var leg_amount=0.32*weight*(1.2 if charge else 1.0)*(1.0-down)
	leg(canvas,root,4,Vector2(14,-39),sin(phase+PI)*leg_amount,0.78,tint)
	leg(canvas,root,5,Vector2(-32,-39),sin(phase)*leg_amount,0.78,tint)
	leg(canvas,root,3,Vector2(-39,-38),sin(phase+PI)*leg_amount+0.22*down,0.88,tint)
	leg(canvas,root,2,Vector2(7,-39),sin(phase)*leg_amount-0.20*down,0.88,tint)
	var head_angle=0.10 if wind or charge else 0.0
	head_angle+=0.06*swing-0.16*strike
	var mesh=still_mesh if actor.is_empty() else build_body_mesh(body_lift,head_angle,strike)
	if not actor.is_empty(): actor["rig_mesh"]=mesh # Keep alive until deferred canvas rendering.
	canvas.draw_set_transform_matrix(root)
	canvas.draw_mesh(mesh,body,Transform2D.IDENTITY,tint)
	canvas.draw_set_transform(Vector2.ZERO)

func leg(canvas,root,index,pivot,angle,scale_leg,tint):
	part(canvas,root,index,pivot,angle,Rect2(-9,-5,23*scale_leg,48*scale_leg),tint)

func part(canvas,root,index,pivot,angle,destination,tint):
	canvas.draw_set_transform_matrix(root*Transform2D(angle,pivot))
	canvas.draw_texture_rect_region(atlas,destination,REGIONS[index],tint,false,true)

func mesh_point(u: float, v: float, lift: float, head_angle: float, strike: float):
	var p=Vector2(lerpf(-65.0,67.0,u),lerpf(-96.0,-24.0,v))
	# Continuous weights: torso stays firm, neck bends, head follows. No split edge.
	var neck_weight=smoothstep(0.47,0.82,u)
	var pivot=Vector2(9,-58)
	var bent=pivot+(p-pivot).rotated(head_angle)
	p=p.lerp(bent,neck_weight)
	p.x+=strike*1.8*neck_weight
	p.y+=lift*(1.0-0.3*v)
	return p

func build_body_mesh(lift: float, head_angle: float, strike: float):
	var vertices=PackedVector2Array()
	var uv=PackedVector2Array()
	var indices=PackedInt32Array()
	for y in range(ROWS+1):
		for x in range(COLUMNS+1):
			var u=float(x)/COLUMNS
			var v=float(y)/ROWS
			vertices.append(mesh_point(u,v,lift,head_angle,strike))
			uv.append((body_region.position+Vector2(u,v)*body_region.size)/Vector2(body.get_size()))
	for y in range(ROWS):
		for x in range(COLUMNS):
			var i=y*(COLUMNS+1)+x
			indices.append_array(PackedInt32Array([i,i+1,i+COLUMNS+1,i+1,i+COLUMNS+2,i+COLUMNS+1]))
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh
