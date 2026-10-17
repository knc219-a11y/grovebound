extends Node3D
# Procedural 3D locomotion study. Joint positions use a planar two-link IK solve.
const CYCLE=0.8
const STRIDE=0.8
const DUTY=0.64
const UPPER=0.46
const LOWER=0.45
var animal: Node3D
var trunk: Node3D
var head: Node3D
var camera: Camera3D
var legs=[]
var brown
var dark
var hoof_material
var outline_material
var sphere: SphereMesh
var cylinder: CylinderMesh
var elapsed=0.0
var automatic=false

func _ready():
	brown=material(Color("a46835"))
	dark=material(Color("754728"))
	hoof_material=material(Color("30251f"))
	outline_material=ShaderMaterial.new()
	var shader=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded,cull_front; void vertex(){VERTEX+=NORMAL*0.018;} void fragment(){ALBEDO=vec3(0.11,0.065,0.04);}"
	outline_material.shader=shader
	sphere=SphereMesh.new()
	sphere.radius=1.0
	sphere.height=2.0
	sphere.radial_segments=20
	sphere.rings=12
	cylinder=CylinderMesh.new()
	cylinder.top_radius=1.0
	cylinder.bottom_radius=1.0
	cylinder.height=1.0
	cylinder.radial_segments=10
	animal=Node3D.new()
	add_child(animal)
	trunk=Node3D.new()
	animal.add_child(trunk)
	ellipsoid(trunk,Vector3(0,1.12,0),Vector3(1.03,0.64,0.54),brown)
	ellipsoid(trunk,Vector3(-0.56,1.10,0),Vector3(0.64,0.62,0.56),brown)
	ellipsoid(trunk,Vector3(0.47,1.16,0),Vector3(0.58,0.66,0.55),brown)
	for i in range(8):
		var bristle=cone(trunk,Vector3(-0.90+i*0.20,1.73,0),0.13,0.26,dark)
		bristle.rotation.z=0.45
	head=Node3D.new()
	trunk.add_child(head)
	head.position=Vector3(0.77,1.14,0)
	ellipsoid(head,Vector3(0.12,0,0),Vector3(0.58,0.49,0.41),brown)
	ellipsoid(head,Vector3(0.53,-0.16,0),Vector3(0.43,0.27,0.30),brown)
	var pink=material(Color("d78b79"))
	ellipsoid(head,Vector3(0.87,-0.16,0),Vector3(0.075,0.21,0.28),pink)
	for side in [-1.0,1.0]:
		ellipsoid(head,Vector3(0.941,-0.13,side*0.12),Vector3(0.018,0.065,0.045),hoof_material)
		var ear=cone(head,Vector3(-0.02,0.48,side*0.29),0.23,0.50,dark)
		ear.rotation.z=-0.30
		ellipsoid(head,Vector3(0.32,0.14,side*0.363),Vector3(0.085,0.095,0.055),hoof_material)
		ellipsoid(head,Vector3(0.34,0.17,side*0.409),Vector3(0.025,0.025,0.015),material(Color("fff0cf")))
		var ivory=material(Color("f0e0ae"))
		var points=[Vector3(0.49,-0.30,side*0.27),Vector3(0.63,-0.23,side*0.33),Vector3(0.65,-0.05,side*0.34)]
		for n in range(2): segment(head,points[n],points[n+1],0.065-n*0.022,ivory)
		ellipsoid(head,points[2],Vector3(0.032,0.045,0.032),ivory)
	var tail_points=[Vector3(-1.0,1.22,0),Vector3(-1.25,1.30,0),Vector3(-1.36,1.46,0),Vector3(-1.26,1.54,0)]
	for i in range(3): segment(trunk,tail_points[i],tail_points[i+1],0.047,dark)
	for side in [-1.0,1.0]:
		for front in [true,false]:
			var root=Vector3(0.53 if front else -0.68,0.91,side*0.38)
			var thigh=ellipsoid(animal,root,Vector3(0.23,0.29,0.22),brown)
			var upper=mesh_node(animal,cylinder,brown)
			var lower=mesh_node(animal,cylinder,brown)
			var knee=ellipsoid(animal,Vector3.ZERO,Vector3(0.17,0.17,0.17),brown)
			var foot=Node3D.new()
			animal.add_child(foot)
			for toe in [-1.0,1.0]:
				ellipsoid(foot,Vector3(0.06,-0.025,toe*0.058),Vector3(0.145,0.095,0.055),hoof_material)
			var beat=(0.25 if front else 0.0)+(0.5 if side<0 else 0.0)
			legs.append({"root":root,"upper":upper,"lower":lower,"knee":knee,"thigh":thigh,"foot":foot,"beat":beat,"bend":-1.0 if front else 1.0})
	var environment=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0,0,0,0)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("ffe2bc")
	environment.environment.ambient_light_energy=0.5
	add_child(environment)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-42,-35,0)
	light.light_energy=1.0
	add_child(light)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.2
	camera.near=0.05
	add_child(camera)
	camera.current=true
	set_pose(0.0)

func material(color):
	var result=StandardMaterial3D.new()
	result.albedo_color=color
	result.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	result.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
	result.roughness=1.0
	return result

func mesh_node(parent,mesh,mat):
	var node=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=mat
	parent.add_child(node)
	var outline=MeshInstance3D.new()
	outline.mesh=mesh
	outline.material_override=outline_material
	node.add_child(outline)
	return node

func ellipsoid(parent,position_value,scale_value,mat):
	var node=mesh_node(parent,sphere,mat)
	node.position=position_value
	node.scale=scale_value
	return node

func cone(parent,position_value,radius,height_value,mat):
	var mesh=CylinderMesh.new()
	mesh.top_radius=0.0
	mesh.bottom_radius=radius
	mesh.height=height_value
	mesh.radial_segments=3
	var node=mesh_node(parent,mesh,mat)
	node.position=position_value
	return node

func fit_segment(node,a,b,radius):
	node.position=(a+b)/2.0
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	node.scale=Vector3(radius,a.distance_to(b),radius)

func segment(parent,a,b,radius,mat):
	var node=mesh_node(parent,cylinder,mat)
	fit_segment(node,a,b,radius)
	return node

static func foot_offset(time: float,beat: float):
	var phase=fposmod(time/CYCLE+beat,1.0)
	var half=STRIDE*DUTY/2.0
	if phase<DUTY: return Vector2(lerpf(half,-half,phase/DUTY),0.0)
	var swing=(phase-DUTY)/(1.0-DUTY)
	# Hermite endpoints match stance velocity; squared sine lifts smoothly.
	var s2=swing*swing
	var s3=s2*swing
	var tangent=-STRIDE*(1.0-DUTY)
	var x=(2*s3-3*s2+1)*(-half)+(s3-2*s2+swing)*tangent+(-2*s3+3*s2)*half+(s3-s2)*tangent
	return Vector2(x,pow(sin(swing*PI),2.0)*0.15)

static func solve_knee(root: Vector3,foot: Vector3,bend: float):
	var delta=foot-root
	var distance=clampf(delta.length(),0.01,UPPER+LOWER-0.001)
	var direction=delta.normalized()
	var along=(UPPER*UPPER-LOWER*LOWER+distance*distance)/(2.0*distance)
	var perpendicular=Vector3(-direction.y,direction.x,0).normalized()*bend
	return root+direction*along+perpendicular*sqrt(maxf(0.0,UPPER*UPPER-along*along))

func set_pose(time: float):
	var travel=time*STRIDE/CYCLE
	animal.position.x=travel
	var bob=sin(time/CYCLE*TAU*2.0)*0.018
	trunk.position.y=bob
	head.rotation.z=sin(time/CYCLE*TAU)*0.018
	for leg in legs:
		var offset=foot_offset(time,leg.beat)
		var root=leg.root+Vector3(0,bob,0)
		var target=Vector3(leg.root.x+offset.x,0.12+offset.y,leg.root.z)
		var joint=solve_knee(root,target,leg.bend)
		leg.thigh.position=root
		leg.knee.position=joint
		leg.foot.position=target
		fit_segment(leg.upper,root,joint,0.15)
		fit_segment(leg.lower,joint,target,0.10)
	camera.position=Vector3(travel+2.7,2.65,6.0)
	camera.look_at(Vector3(travel+0.12,0.92,0),Vector3.UP)

func _process(dt):
	if automatic:
		elapsed+=dt
		set_pose(elapsed)
