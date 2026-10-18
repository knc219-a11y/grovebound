extends RefCounted
# Reusable native-pixel frame player. Rigs and source meshes stay build-time only.
var texture: Texture2D
var frames=[]
var cell: Vector2
var ground: Vector2
var native_height: float
var stride: float
var minimum_cycle: float
func _init(manifest):
	var data=JSON.parse_string(FileAccess.get_file_as_string(manifest))
	texture=load(data.texture)
	cell=Vector2(data.cell[0],data.cell[1])
	ground=Vector2(data.ground[0],data.ground[1])
	native_height=data.native_height
	stride=data.stride_pixels
	minimum_cycle=data.minimum_cycle_seconds
	for i in int(data.count):
		frames.append(Rect2(Vector2(i%int(data.columns),i/int(data.columns)).floor()*cell,cell))
func frame_for_phase(phase):
	return posmod(floori(phase*frames.size()),frames.size())
func advance(actor,dt):
	var distance=actor.pos.distance_to(actor.get("pixel_last",actor.pos))
	actor.pixel_last=actor.pos
	var moving=actor.get("walk",false) and actor.hp>0 and distance>0.001 and distance<100
	if moving:
		var cycles=minf(distance/stride,maxf(0,dt)/minimum_cycle)
		actor.pixel_phase=fposmod(actor.get("pixel_phase",0.0)+cycles,1.0)
	actor.pixel_moving=moving
	if not moving: actor.pixel_phase=0.0
func draw(canvas,position,height,face,tint,actor,idle):
	var scale_value=maxf(1.0,roundf(height/native_height))
	var down=actor.hp<=0
	var moving=actor.get("pixel_moving",false) and not down and actor.get("swing",0.0)<=0
	var tilt=-0.75*face if down else 0.0
	canvas.draw_set_transform_matrix(Transform2D(tilt,position.round()).scaled_local(Vector2(face,1)*scale_value))
	if moving:
		canvas.draw_texture_rect_region(texture,Rect2(-ground,cell),frames[frame_for_phase(actor.get("pixel_phase",0.0))],tint)
	else:
		canvas.draw_texture_rect(idle,Rect2(Vector2(-idle.get_width()/2.0,-idle.get_height()),idle.get_size()),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
