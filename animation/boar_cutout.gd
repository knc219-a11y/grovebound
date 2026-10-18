extends RefCounted
# Connected head/body + four independently skinned whole-leg layers.
const DUTY = 0.64
const STRIDE = 30.0
const COLS = 10
const ROWS = 28
var body_bob = 0.45
var body: Texture2D
var atlas: Texture2D
var regions = []
var body_region = Rect2(60,24,1447,893)
var legs = [
	{"root":Vector2(-21,-47),"foot":Vector2(-18,-4),"front":false,"beat":0.5,"far":true},
	{"root":Vector2(27,-53),"foot":Vector2(31,-4),"front":true,"beat":0.75,"far":true},
	{"root":Vector2(-39,-49),"foot":Vector2(-43,0),"front":false,"beat":0.0,"far":false},
	{"root":Vector2(6,-54),"foot":Vector2(11,0),"front":true,"beat":0.25,"far":false}
]
var uv_cache = []
var index_cache = PackedInt32Array()

func _init(_legacy=null):
	body = load("res://assets/boar-cutout-body-v1.png")
	atlas = load("res://assets/boar-cutout-legs-v1.png")
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://animation/boar_cutout_legs.json"))
	for frame in data.frames:
		var r = frame.region
		regions.append(Rect2(r[0],r[1],r[2],r[3]))
	rebuild_uvs()

func rebuild_uvs():
	uv_cache.clear()
	index_cache.clear()
	for region in regions:
		var coords = PackedVector2Array()
		for y in range(ROWS+1):
			for x in range(COLS+1):
				coords.append((region.position+region.size*Vector2(float(x)/COLS,float(y)/ROWS))/Vector2(atlas.get_size()))
		uv_cache.append(coords)
	for y in range(ROWS):
		for x in range(COLS):
			var i = y*(COLS+1)+x
			index_cache.append_array(PackedInt32Array([i,i+1,i+COLS+1,i+1,i+COLS+2,i+COLS+1]))

func foot_path(phase: float, beat: float):
	var t = fposmod(phase/TAU+beat,1.0)
	var half = STRIDE*DUTY/2
	if t<DUTY: return Vector2(half-STRIDE*t,0)
	var s = (t-DUTY)/(1-DUTY)
	var m = -STRIDE*(1-DUTY)
	var x = (2*s*s*s-3*s*s+1)*(-half)+(s*s*s-2*s*s+s)*m+(-2*s*s*s+3*s*s)*half+(s*s*s-s*s)*m
	return Vector2(x,-5.0*pow(sin(PI*s),2))

func solve(root: Vector2, target: Vector2, front: bool, length_total: float = 55.0):
	var l1 = length_total*0.51
	var l2 = length_total*0.49
	var delta = target-root
	var d = clampf(delta.length(),1,l1+l2-0.01)
	var direction = delta.normalized()
	var a = (l1*l1-l2*l2+d*d)/(2*d)
	var side = -1.0 if front else 1.0
	var knee = root+direction*a+Vector2(-direction.y,direction.x)*sqrt(maxf(0,l1*l1-a*a))*side
	return [root,knee,root+direction*d]

func leg_vertices(leg, phase: float, amount: float, lift: float):
	var root = leg.root+Vector2(0,lift)
	var target = leg.foot+foot_path(phase,leg.beat)*amount
	var length_total = (51.0 if leg.far else 56.0) if leg.front else (49.0 if leg.far else 55.0)
	var knee_y = length_total*0.51
	var pose = solve(root,target,leg.front,length_total)
	var upper_angle = (pose[1]-pose[0]).angle()-PI/2
	var lower_angle = (pose[2]-pose[1]).angle()-PI/2
	var width = 23.0 if leg.front else 26.0
	var vertices = PackedVector2Array()
	for y in range(ROWS+1):
		var v = float(y)/ROWS
		# Source leg centerline follows the painted shin/hoof, not the image center.
		var center = lerpf(0.44,0.70,smoothstep(0.40,0.92,v)) if leg.front else lerpf(0.49,0.60,smoothstep(0.5,0.95,v))
		for x in range(COLS+1):
			var p = Vector2((float(x)/COLS-center)*width,v*length_total)
			var upper = pose[0]+p.rotated(upper_angle)
			var lower = pose[1]+Vector2(p.x,p.y-knee_y).rotated(lower_angle)
			var result = upper.lerp(lower,smoothstep(knee_y-14,knee_y+14,p.y))
			# Hooves stay level during contact; only the shin bends.
			result = result.lerp(pose[2]+Vector2(p.x,p.y-length_total),smoothstep(length_total-22,length_total,p.y))
			vertices.append(result)
	return vertices

func leg_mesh(leg, phase: float, amount: float, lift: float):
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = leg_vertices(leg,phase,amount,lift)
	arrays[Mesh.ARRAY_TEX_UV] = uv_cache[0 if leg.front else 1]
	arrays[Mesh.ARRAY_INDEX] = index_cache
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh

func advance(actor,dt):
	var distance = actor.pos.distance_to(actor.get("rig_last",actor.pos))
	actor.rig_last = actor.pos
	var moving = actor.get("walk",false) and actor.hp>0 and distance>0.001 and distance<100
	var height = actor.get("render_height",112.0 if actor.get("boss",false) else 64.0)
	if moving: actor.rig_phase = fposmod(actor.get("rig_phase",0.0)+distance/(STRIDE*height/100)*TAU,TAU)
	actor.rig_move = lerpf(actor.get("rig_move",0.0),1.0 if moving else 0.0,1-exp(-dt*12))
	actor.rig_time = actor.get("rig_time",0.0)+dt
	actor.rig_down = move_toward(actor.get("rig_down",0.0),1.0 if actor.hp<=0 else 0.0,dt/0.3)

func draw(canvas: Node2D, position: Vector2, height: float, face: float, tint: Color, actor):
	var phase = actor.get("rig_phase",0.0)
	var weight = actor.get("rig_move",0.0)
	var lift = -body_bob*weight*pow(sin(phase*2),2)
	var down = actor.get("rig_down",0.0)
	canvas.draw_set_transform_matrix(Transform2D(-0.95*down,position).scaled_local(Vector2(face,1)*height/100))
	var meshes = []
	# Far legs first. Near legs also begin beneath the body cover.
	for leg in legs:
		var mesh = leg_mesh(leg,phase,weight,lift)
		meshes.append(mesh)
		var col = tint * (Color(0.72,0.74,0.75,1) if leg.far else Color.WHITE)
		canvas.draw_mesh(mesh,atlas,Transform2D.IDENTITY,col)
	var body_height = 76.0
	var body_width = body_height*body_region.size.x/body_region.size.y
	canvas.draw_texture_rect_region(body,Rect2(-body_width/2,-100+lift,body_width,body_height),body_region,tint)
	actor["cutout_meshes"] = meshes # Deferred canvas draw needs retained resources.
	canvas.draw_set_transform(Vector2.ZERO)
