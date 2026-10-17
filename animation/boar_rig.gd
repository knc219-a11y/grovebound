extends RefCounted
# The approved complete animal is one continuous skin: no detached leg sprites.
const COLUMNS=32
const ROWS=24
const BODY_REGION=Rect2(55,90,1450,877)
# Root v, foot u, root u, width. Near hind/front and far hind/front.
const LEGS=[Vector4(0.56,0.234,0.265,0.078),Vector4(0.59,0.615,0.615,0.071),Vector4(0.73,0.392,0.365,0.065),Vector4(0.73,0.746,0.729,0.060)]
const BEATS=[0.0,0.25,0.5,0.75]
var body: Texture2D
var rest=PackedVector2Array()
var uv=PackedVector2Array()
var indices=PackedInt32Array()
var skin=[]
var still_mesh: ArrayMesh

func _init(_legacy_atlas=null):
	body=load("res://assets/boar-stance-proposal.png")
	prepare_skin()
	still_mesh=make_mesh(rest)

func prepare_skin():
	for y in range(ROWS+1):
		for x in range(COLUMNS+1):
			var u=float(x)/COLUMNS
			var v=float(y)/ROWS
			rest.append(Vector2(lerpf(-82.67,82.67,u),lerpf(-100.0,0.0,v)))
			uv.append((BODY_REGION.position+Vector2(u,v)*BODY_REGION.size)/Vector2(body.get_size()))
			var weights=PackedFloat32Array()
			var total=0.0
			for leg in LEGS:
				var along=smoothstep(leg.x,0.96,v)
				var center=lerpf(leg.z,leg.y,along)
				var horizontal=exp(-pow(absf((u-center)/leg.w),4.0))
				var w=along*horizontal
				weights.append(w)
				total+=w
			if total>1.0:
				for i in range(4): weights[i]/=total
			skin.append({"legs":weights,"upper":1.0-smoothstep(0.64,0.97,v),"head":smoothstep(0.52,0.84,u)*(1.0-smoothstep(0.60,0.78,v))})
	for y in range(ROWS):
		for x in range(COLUMNS):
			var i=y*(COLUMNS+1)+x
			indices.append_array(PackedInt32Array([i,i+1,i+COLUMNS+1,i+1,i+COLUMNS+2,i+COLUMNS+1]))

func advance(actor,dt):
	var last=actor.get("rig_last",actor.pos)
	var distance=actor.pos.distance_to(last)
	actor["rig_last"]=actor.pos
	var moving=actor.get("walk",false) and actor.hp>0 and distance>0.01
	var stride=112.0 if actor.get("boss",false) else 76.0
	if moving: actor["rig_phase"]=fmod(actor.get("rig_phase",0.0)+minf(distance,35.0)/stride*TAU,TAU)
	actor["rig_move"]=lerpf(actor.get("rig_move",0.0),1.0 if moving else 0.0,1.0-exp(-dt*12.0))
	actor["rig_time"]=actor.get("rig_time",0.0)+dt
	actor["rig_down"]=move_toward(actor.get("rig_down",0.0),1.0 if actor.hp<=0 else 0.0,dt/0.3)

func foot_path(phase: float,beat: float):
	var t=fposmod(phase/TAU+beat,1.0)
	# Longer grounded stance, shorter returning swing; root remains in the skin.
	if t<0.64: return Vector2(lerpf(5.0,-5.0,t/0.64),0.0)
	var swing=(t-0.64)/0.36
	return Vector2(lerpf(-5.0,5.0,smoothstep(0.0,1.0,swing)),-sin(swing*PI)*2.4)

func pose_vertices(phase: float,weight: float,lift: float,head_angle: float,strike: float):
	var feet=[]
	for beat in BEATS: feet.append(foot_path(phase,beat)*weight)
	var vertices=rest.duplicate()
	for i in range(vertices.size()):
		var p=rest[i]
		var field=skin[i]
		for leg in range(4): p+=feet[leg]*field.legs[leg]
		var pivot=Vector2(17,-49)
		p=p.lerp(pivot+(p-pivot).rotated(head_angle),field.head)
		p.x+=strike*1.3*field.head
		p.y+=lift*field.upper
		vertices[i]=p
	return vertices

func make_mesh(vertices):
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh

func draw(canvas: Node2D,position: Vector2,height: float,face: float,tint: Color,actor):
	var phase=actor.get("rig_phase",0.0)
	var down=smoothstep(0.0,1.0,actor.get("rig_down",0.0))
	var weight=actor.get("rig_move",0.0)*(1.0-down)
	var time=actor.get("rig_time",0.0)
	var wind=actor.get("wind",0.0)>0 or actor.get("dash",0.0)>0
	var swing=clampf(actor.get("swing",0.0)/0.22,0.0,1.0)
	var strike=sin((1.0-swing)*PI) if swing>0 else 0.0
	var lift=(sin(time*2.4)*0.30*(1.0-weight)-absf(sin(phase*2.0))*0.25*weight)*(1.0-down)
	var angle=((0.07 if wind else 0.0)+0.04*swing-0.12*strike)*(1.0-down)
	var mesh=still_mesh
	if not actor.is_empty():
		mesh=make_mesh(pose_vertices(phase,weight,lift,angle,strike))
		actor["rig_mesh"]=mesh # Canvas draw is deferred; retain the resource.
	var root=Transform2D(-0.95*down,position+Vector2(0,7*down)*height/100.0)
	canvas.draw_set_transform_matrix(root.scaled_local(Vector2(face,1)*height/100.0))
	canvas.draw_mesh(mesh,body,Transform2D.IDENTITY,tint)
	canvas.draw_set_transform(Vector2.ZERO)
