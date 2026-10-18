extends Node2D
# Build-time continuous skin: shared vertices keep cloak/limb joins closed.
# The original sprite and palette stay intact; no runtime mesh work is needed.
const DUTY = 0.62
var phase = 0.0
var running = false
var sprite = preload("res://assets/party-pixel/druid.png")
var mesh: ArrayMesh

func foot_offset(t):
	t=fposmod(t,1.0)
	var duty=0.36 if running else DUTY
	var reach=9.0 if running else 5.0
	if t<duty: return Vector2(reach-2.0*reach*t/duty,0)
	var swing=(t-duty)/(1.0-duty)
	return Vector2(lerpf(-reach,reach,smoothstep(0,1,swing)),-(7.0 if running else 3.0)*sin(PI*swing))

func pose(t):
	phase=t
	var vertices=PackedVector2Array()
	var uv=PackedVector2Array()
	var indices=PackedInt32Array()
	var near=foot_offset(t)
	var far=foot_offset(t+0.5)
	var lift=-(2.0 if running else 0.65)*pow(sin(t*TAU),2)
	for y in range(73):
		for x in range(49):
			var p=Vector2(x,y)
			var delta=Vector2(0,lift*(1.0-smoothstep(50,68,y)) if running else lift)
			# Under the long cloak, the near boot and far trouser leg alternate.
			var near_weight=1.0-smoothstep(19,23,x)
			var legs=near*smoothstep(54,70,y)*near_weight
			legs+=far*smoothstep(47,65,y)*(1.0-near_weight)*(1.0-smoothstep(32,35,x))
			delta+=legs
			# Lower cloak follows the hip with a delayed, smaller swing.
			delta.x+=sin((t-0.12)*TAU)*(2.2 if running else 0.8)*smoothstep(37,58,y)*(1.0-smoothstep(57,65,y))*(1.0-smoothstep(21,25,x))
			# Free hand counter-swings; staff and gripping hand remain together.
			var hand=smoothstep(33,43,y)*(1.0-smoothstep(48,52,y))
			delta.x-=sin(t*TAU)*(2.0 if running else 0.8)*hand*smoothstep(8,11,x)*(1.0-smoothstep(17,20,x))
			var staff=smoothstep(30,35,x)
			var pivot=Vector2(35,36)
			delta+=( (p-pivot).rotated(sin(t*TAU)*(0.035 if running else 0.015))-(p-pivot))*staff
			if running:
				var hip=Vector2(20,50)
				delta+=((p-hip).rotated(0.09)-(p-hip))*(1.0-smoothstep(50,70,y))
			vertices.append(p+delta-Vector2(24,72))
			uv.append(p/Vector2(48,72))
	for y in range(72):
		for x in range(48):
			var i=y*49+x
			indices.append_array(PackedInt32Array([i,i+1,i+49,i+1,i+50,i+49]))
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	queue_redraw()

func _draw():
	if mesh: draw_mesh(mesh,sprite)
