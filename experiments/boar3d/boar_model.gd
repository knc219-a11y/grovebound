extends "res://experiments/boar3d/boar_model_blockout.gd"
# Fused implicit surface, skinned continuously to the existing analytic gait.
var surface_node: MeshInstance3D
var rest_vertices=PackedVector3Array()
var rest_normals=PackedVector3Array()
var surface_colors=PackedColorArray()
var surface_indices=PackedInt32Array()
var influences=[]
var weights=[]
var bind_origins=[]
var bind_directions=[]

func _ready():
	super()
	for child in trunk.get_children(): child.hide()
	for leg in legs:
		for key in ["upper","lower","knee","thigh"]: leg[key].hide()
	var raw=FileAccess.get_file_as_bytes("res://experiments/boar3d/boar_surface.json.gz")
	var data=JSON.parse_string(raw.decompress_dynamic(-1,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	for v in data.vertices: rest_vertices.append(Vector3(v[0],v[1],v[2]))
	for n in data.normals: rest_normals.append(Vector3(n[0],n[1],n[2]))
	for c in data.colors: surface_colors.append(Color(c[0],c[1],c[2]))
	for i in data.indices: surface_indices.append(int(i))
	influences=data.bones
	weights=data.weights
	bind_origins.append(Vector3.ZERO)
	bind_directions.append(Vector3.UP)
	for bone in data.rest_bones:
		var a=Vector3(bone[0][0],bone[0][1],bone[0][2])
		var b=Vector3(bone[1][0],bone[1][1],bone[1][2])
		bind_origins.append(a)
		bind_directions.append((b-a).normalized())
	var skin_material=material(Color.WHITE)
	skin_material.vertex_color_use_as_albedo=true
	skin_material.diffuse_mode=BaseMaterial3D.DIFFUSE_BURLEY
	surface_node=mesh_node(animal,make_surface(rest_vertices,rest_normals),skin_material)
	# Soft, irregular back tufts replace the line of repeated triangular cones.
	for i in range(data.back.size()):
		var p=data.back[i]
		var root=Vector3(p[0],p[1]-0.025,p[2])
		fur_tuft(trunk,root,0.12+float(i%3)*0.025,brown)
	# Face details sit on the sculpted skull; no separate head/body cut.
	head.show()
	for child in head.get_children(): child.hide()
	var nose=material(Color("db8b75"))
	ellipsoid(head,Vector3(1.05,-0.18,0),Vector3(0.075,0.245,0.33),nose)
	for side in [-1.0,1.0]:
		ellipsoid(head,Vector3(1.122,-0.15,side*0.125),Vector3(0.018,0.065,0.043),hoof_material)
		ellipsoid(head,Vector3(0.48,0.22,side*0.49),Vector3(0.078,0.108,0.052),hoof_material)
		ellipsoid(head,Vector3(0.50,0.255,side*0.542),Vector3(0.024,0.027,0.014),material(Color("fff1d9")))
		ear_leaf(head,Vector3(-0.02,0.46,side*0.33),side)
		tusk_curve(head,side)
	# A curved, tapered tail with a fur tip, rather than straight linked bars.
	var points=[Vector3(-1.12,1.20,0),Vector3(-1.40,1.22,0),Vector3(-1.47,1.48,0),Vector3(-1.29,1.52,0)]
	curved_tube(trunk,points,0.055,dark)
	fur_tuft(trunk,Vector3(-1.32,1.47,0),0.16,dark)
	camera.size=3.45
	set_pose(0.0)

func make_surface(vertices,normals):
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=surface_colors
	arrays[Mesh.ARRAY_INDEX]=surface_indices
	var mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func set_pose(time: float):
	super(time)
	if rest_vertices.is_empty(): return
	head.rotation=Vector3.ZERO
	var bob=sin(time/CYCLE*TAU*2.0)*0.018
	var origins=[Vector3(0,bob,0)]
	var rotations=[Quaternion.IDENTITY]
	for i in range(legs.size()):
		var leg=legs[i]
		var root=leg.root+Vector3(0,bob,0)
		var joint=leg.knee.position
		var ankle=leg.foot.position
		origins.append(root)
		origins.append(joint)
		rotations.append(Quaternion(bind_directions[i*2+1],(joint-root).normalized()))
		rotations.append(Quaternion(bind_directions[i*2+2],(ankle-joint).normalized()))
	var vertices=PackedVector3Array()
	var normals=PackedVector3Array()
	vertices.resize(rest_vertices.size())
	normals.resize(rest_vertices.size())
	for i in range(rest_vertices.size()):
		var p=Vector3.ZERO
		var n=Vector3.ZERO
		for j in range(4):
			var bone=int(influences[i][j])
			var weight=weights[i][j]
			p+=(origins[bone]+rotations[bone]*(rest_vertices[i]-bind_origins[bone]))*weight
			n+=(rotations[bone]*rest_normals[i])*weight
		vertices[i]=p
		normals[i]=n.normalized()
	var mesh=make_surface(vertices,normals)
	surface_node.mesh=mesh
	surface_node.get_child(0).mesh=mesh
	camera.position=Vector3(time*STRIDE/CYCLE+3.3,2.6,6.0)
	camera.look_at(Vector3(time*STRIDE/CYCLE+0.15,1.0,0),Vector3.UP)

func flat_shape(parent,points,color,normal=Vector3(0,0,1)):
	var vertices=PackedVector3Array(points)
	var normals=PackedVector3Array()
	var indices=PackedInt32Array()
	for point in points: normals.append(normal)
	for i in range(1,points.size()-1):
		var a=0; var b=i; var c=i+1
		if (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).dot(normal)>0:
			var old=b; b=c; c=old
		indices.append_array(PackedInt32Array([a,b,c]))
	var arrays=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mat=material(color); mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	return mesh_node(parent,mesh,mat)

func ear_leaf(parent,root,side):
	var contour=[Vector2(-0.15,0),Vector2(-0.19,0.22),Vector2(-0.13,0.49),Vector2(0.01,0.59),Vector2(0.12,0.42),Vector2(0.13,0.16),Vector2(0.08,0.0)]
	var curved=[]
	for i in range(contour.size()):
		var a=contour[posmod(i-1,contour.size())]; var b=contour[i]
		var c=contour[(i+1)%contour.size()]; var d=contour[(i+2)%contour.size()]
		for step in range(4):
			var t=float(step)/4.0
			curved.append(0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
	contour=curved
	var points=[]
	for p in contour: points.append(root+Vector3(p.x,p.y,side*0.035*sin(p.y/0.59*PI)))
	flat_shape(parent,points,Color("4b2d1d"),Vector3(0,0,side))
	points=[]
	for p in contour: points.append(root+Vector3(p.x*0.70,p.y*0.78+0.05,side*0.045))
	flat_shape(parent,points,Color("9c6350"),Vector3(0,0,side))

func fur_tuft(parent,root,size_value,mat):
	var color=mat.albedo_color
	var points=[root+Vector3(-size_value,0,0.035),root+Vector3(-size_value*1.35,size_value*0.80,0),root+Vector3(-size_value*0.25,size_value*0.50,-0.035),root+Vector3(size_value*0.60,0,0)]
	flat_shape(parent,points,color,Vector3(0,0,1))

func tusk_curve(parent,side):
	var points=[Vector3(0.62,-0.28,side*0.29),Vector3(0.83,-0.29,side*0.39),Vector3(0.90,-0.02,side*0.42),Vector3(0.79,0.16,side*0.39)]
	curved_tube(parent,points,0.09,material(Color("f4e5bb")))

func curved_tube(parent,control,radius,mat):
	var vertices=PackedVector3Array(); var normals=PackedVector3Array(); var indices=PackedInt32Array()
	var segments=16; var sides=10
	for i in range(segments+1):
		var t=float(i)/segments; var omt=1.0-t
		var p=control[0]*pow(omt,3)+control[1]*3*omt*omt*t+control[2]*3*omt*t*t+control[3]*pow(t,3)
		var tangent=((control[1]-control[0])*3*omt*omt+(control[2]-control[1])*6*omt*t+(control[3]-control[2])*3*t*t).normalized()
		var u=tangent.cross(Vector3.FORWARD).normalized(); var v=tangent.cross(u).normalized()
		var width=radius*pow(1.0-t,0.55)+0.002
		for j in range(sides):
			var n=u*cos(float(j)/sides*TAU)+v*sin(float(j)/sides*TAU)
			vertices.append(p+n*width); normals.append(n)
	for i in range(segments):
		for j in range(sides):
			var a=i*sides+j; var b=i*sides+(j+1)%sides; var c=(i+1)*sides+j; var d=(i+1)*sides+(j+1)%sides
			for triangle in [[a,b,c],[b,d,c]]:
				if (vertices[triangle[1]]-vertices[triangle[0]]).cross(vertices[triangle[2]]-vertices[triangle[0]]).dot(normals[triangle[0]])>0:
					indices.append_array(PackedInt32Array([triangle[0],triangle[2],triangle[1]]))
				else: indices.append_array(PackedInt32Array(triangle))
	var arrays=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh_node(parent,mesh,mat)
