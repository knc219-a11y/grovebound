extends Node2D
# Pose baking from the approved native sprites; never used by runtime combat.
var sprite: Texture2D
var mesh: ArrayMesh
var kind=""
var action="attack"
var size=Vector2.ZERO
func configure(species,key):
	kind=species
	action=key
	if kind=="boar":
		var image=Image.load_from_file("res://assets/boar-pixel-idle.png").get_region(Rect2i(12,14,70,48))
		sprite=ImageTexture.create_from_image(image)
	else: sprite=load("res://assets/party-pixel/"+("druid-body-v2" if kind=="druid" else kind)+".png")
	size=sprite.get_size()
func pose(t):
	# Impact is frame zero: gameplay damage/healing is applied immediately.
	var strength=pow(1.0-t,1.5)
	if action=="revive": strength=0.65+0.15*sin(t*TAU)
	var vertices=PackedVector2Array()
	var uv=PackedVector2Array()
	var indices=PackedInt32Array()
	for y in range(int(size.y)+1):
		for x in range(int(size.x)+1):
			var p=Vector2(x,y)
			var d=Vector2.ZERO
			if kind=="druid":
				var upper=1.0-smoothstep(40,65,y)
				d.x+=(2.5 if action=="revive" else -1.0)*strength*upper
				d.y-=1.2*strength*upper if action!="revive" else -1.3*strength*upper
			else:
				var neck=Vector2(size.x*0.67,size.y*0.52)
				var head=smoothstep(size.x*0.55,size.x*0.8,x)
				var paw=1.0-smoothstep(size.y*0.65,size.y,y)
				if action=="capture":
					# Bend the silhouette down while the feet retain their original ground.
					var grounded=1.0-smoothstep(size.y*0.65,size.y,y)
					var breath=0.5-0.5*cos(t*TAU)
					d.y+=(size.y*0.22+breath)*grounded
					d+=((p-neck).rotated(0.12)-(p-neck))*head
				elif kind=="turtle" and action=="guard":
					d.x-=5.0*strength*head
					d.y+=1.2*strength*head
				elif action=="heal" or action=="cast":
					d+=((p-neck).rotated(-0.11*strength)-(p-neck))*head
					d.y-=strength*head
					var tail=1.0-smoothstep(size.x*0.18,size.x*0.44,x)
					d.y-=2.0*strength*tail
				else:
					# A clearer lunge and foreleg swipe while the planted hind feet stay readable.
					var fore=smoothstep(size.x*0.55,size.x*0.72,x)*smoothstep(size.y*0.48,size.y*0.72,y)
					fore*=1.0-smoothstep(size.y*0.88,size.y,y)
					d.x+=4.5*strength*paw+4.0*strength*head+5.0*strength*fore
					d.y+=1.8*strength*pow(sin(float(x)/size.x*PI),2)*paw-3.0*strength*fore
					d+=((p-neck).rotated(-0.18*strength)-(p-neck))*head
			vertices.append(p+d-Vector2(size.x/2,size.y))
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
