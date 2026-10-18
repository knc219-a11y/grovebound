extends Node2D
# Build-time skin over the approved native sprite. Shared vertices close joints.
var kind="wolf"
var fast=false
var sprite: Texture2D
var mesh: ArrayMesh
var config={}
const CONFIGS={
	"wolf":{"size":Vector2(67,48),"roots":[Vector2(24,25),Vector2(30,28),Vector2(42,27),Vector2(52,27)],"feet":[Vector2(15,46),Vector2(30,45),Vector2(45,48),Vector2(58,46)],"widths":[7.0,5.0,5.0,5.0],"tail":Vector2(23,23),"reach":8.0,"fast_reach":10.0,"lift":3.0,"fast_lift":5.0,"tail_angle":0.045},
	"marten":{"size":Vector2(74,32),"roots":[Vector2(36,20),Vector2(44,20),Vector2(57,18),Vector2(63,18)],"feet":[Vector2(36,31),Vector2(46,29),Vector2(59,32),Vector2(66,30)],"widths":[5.0,4.0,4.0,3.5],"tail":Vector2(32,19),"reach":5.0,"fast_reach":8.0,"lift":2.5,"fast_lift":4.5,"tail_angle":0.07},
	"deer":{"size":Vector2(51,64),"roots":[Vector2(15,39),Vector2(23,40),Vector2(35,39),Vector2(42,38)],"feet":[Vector2(13,64),Vector2(24,61),Vector2(36,64),Vector2(44,62)],"widths":[4.0,3.5,3.5,3.0],"tail":Vector2(13,34),"reach":7.0,"fast_reach":10.0,"lift":3.0,"fast_lift":5.5,"tail_angle":0.025},
	"turtle":{"size":Vector2(56,32),"roots":[Vector2(15,21),Vector2(25,19),Vector2(37,22),Vector2(46,20)],"feet":[Vector2(15,30),Vector2(26,27),Vector2(40,32),Vector2(49,28)],"widths":[5.5,4.0,4.5,3.5],"tail":Vector2(8,21),"reach":2.0,"fast_reach":3.0,"lift":1.0,"fast_lift":1.5,"tail_angle":0.0,"no_trot":true},
	"fox":{"size":Vector2(57,40),"roots":[Vector2(27,20),Vector2(30,24),Vector2(39,23),Vector2(45,23)],"feet":[Vector2(21,39),Vector2(31,37),Vector2(42,40),Vector2(51,39)],"widths":[5.0,4.0,4.0,4.0],"tail":Vector2(25,18),"reach":5.5,"fast_reach":7.6,"lift":2.5,"fast_lift":4.0,"tail_angle":0.075}
}
func configure(species,running):
	kind=species
	fast=running
	config=CONFIGS[kind]
	sprite=load("res://assets/party-pixel/"+kind+".png")
func stride():
	return 2.0*(config.fast_reach if fast else config.reach)/(0.6 if fast and config.get("no_trot",false) else (0.4 if fast else 0.68))
func foot_offset(t,beat):
	t=fposmod(t+beat,1.0)
	var duty=0.6 if fast and config.get("no_trot",false) else (0.4 if fast else 0.68)
	var reach=config.fast_reach if fast else config.reach
	if t<duty: return Vector2(reach-2.0*reach*t/duty,0)
	var s=(t-duty)/(1.0-duty)
	return Vector2(lerpf(-reach,reach,smoothstep(0,1,s)),-(config.fast_lift if fast else config.lift)*sin(PI*s))
func beats():
	# Walk: four evenly staggered feet. Trot: diagonally paired contacts.
	return [0.0,0.5,0.5,0.0] if fast and not config.get("no_trot",false) else [0.0,0.5,0.75,0.25]
func pose(t):
	var size=config.size
	var vertices=PackedVector2Array()
	var uv=PackedVector2Array()
	var indices=PackedInt32Array()
	var phases=beats()
	for y in range(int(size.y)+1):
		for x in range(int(size.x)+1):
			var p=Vector2(x,y)
			var total=0.0
			var weight_total=0.0
			var leg_delta=Vector2.ZERO
			for leg in range(4):
				var root=config.roots[leg]
				var foot=config.feet[leg]
				var v=clampf((y-root.y)/(foot.y-root.y),0,1)
				var center=lerpf(root.x,foot.x,v)
				var influence=(1.0-smoothstep(config.widths[leg]*0.65,config.widths[leg],absf(x-center)))*smoothstep(root.y,root.y+5,y)
				var bend=smoothstep(root.y,foot.y,y)
				leg_delta+=foot_offset(t,phases[leg])*influence*bend
				total+=influence
				weight_total+=influence*bend
			leg_delta/=maxf(1.0,total)
			var bob=-(0.1 if kind=="turtle" else (0.8 if fast else 0.35))*pow(sin(t*TAU*2),2)
			var delta=leg_delta+Vector2(0,bob*(1.0-clampf(weight_total,0,1)))
			var pivot=config.tail
			var tail_line=pivot.y+(pivot.x-x)*0.85
			var tail=(1.0-smoothstep(pivot.x-8,pivot.x,x))*smoothstep(pivot.y-6,pivot.y+2,y)*(1.0-smoothstep(tail_line+4,tail_line+7,y))
			delta+=((p-pivot).rotated(sin((t-0.15)*TAU)*config.tail_angle)-(p-pivot))*tail
			vertices.append(p+delta-Vector2(size.x/2,size.y))
			uv.append(p/size)
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var i=y*(int(size.x)+1)+x
			var row=int(size.x)+1
			indices.append_array(PackedInt32Array([i,i+1,i+row,i+1,i+row+1,i+row]))
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
