extends RefCounted
# Runtime uses only baked pixel sprites. Source rigs/tools are not needed to play.
const SOURCE_HEIGHT = 48.0
var walk_texture: Texture2D
var idle_texture: Texture2D
var walk_frames = []
var cell = Vector2(96,72)
var ground = Vector2(48,62)
var stride_pixels = 14.4

func _init(_legacy=null):
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://animation/boar_pixel_frames.json"))
	walk_texture = load(data.texture)
	idle_texture = load(data.idle)
	cell = Vector2(data.cell[0],data.cell[1])
	ground = Vector2(data.ground[0],data.ground[1])
	stride_pixels = data.stride_pixels
	for i in range(int(data.count)):
		walk_frames.append(Rect2(Vector2(i%int(data.columns),int(i/int(data.columns)))*cell,cell))

func display_scale(height: float):
	return maxf(1.0,roundf(height/SOURCE_HEIGHT))

func portrait():
	var result = AtlasTexture.new()
	result.atlas = idle_texture
	result.region = Rect2(12,14,70,48)
	return result

func frame_for_phase(phase: float):
	return posmod(floori(phase/TAU*walk_frames.size()),walk_frames.size())

func advance(actor,dt):
	var last = actor.get("rig_last",actor.pos)
	var distance = actor.pos.distance_to(last)
	actor.rig_last = actor.pos
	var moving = actor.get("walk",false) and actor.hp>0 and distance>0.001 and distance<100
	var height = 96.0 if actor.get("boss",false) else 48.0
	var stride = stride_pixels*display_scale(height)
	if moving:
		# Fast combat travel exceeds a walk's speed: cap cadence instead of flickering.
		var cycles = minf(distance/stride,maxf(0,dt)/0.36)
		actor.rig_phase = fposmod(actor.get("rig_phase",0.0)+cycles*TAU,TAU)
	actor.rig_move = lerpf(actor.get("rig_move",0.0),1.0 if moving else 0.0,1-exp(-dt*12))
	actor.rig_time = actor.get("rig_time",0.0)+dt
	actor.rig_down = move_toward(actor.get("rig_down",0.0),1.0 if actor.hp<=0 else 0.0,dt/0.3)

func draw(canvas: Node2D, position: Vector2, height: float, face: float, tint: Color, actor):
	var scale_value = display_scale(height)
	var down = actor.get("rig_down",0.0)
	var swing = actor.get("swing",0.0)
	var acting = actor.get("wind",0.0)>0
	var moving = actor.get("walk",false) and actor.get("rig_move",0.0)>0.25 and down<0.01 and not acting
	var nudge = roundf(sin(clampf(swing/0.22,0,1)*PI)*2)*scale_value if swing>0 and not actor.get("walk",false) else 0.0
	var p = position.round()+Vector2(face*nudge,0)
	canvas.draw_set_transform_matrix(Transform2D(-0.7*face*down,p).scaled_local(Vector2(face,1)*scale_value))
	var old_filter = canvas.texture_filter
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dest = Rect2(-ground,cell)
	if moving:
		canvas.draw_texture_rect_region(walk_texture,dest,walk_frames[frame_for_phase(actor.get("rig_phase",0.0))],tint)
	else:
		canvas.draw_texture_rect(idle_texture,dest,false,tint)
	canvas.texture_filter = old_filter
	canvas.draw_set_transform(Vector2.ZERO)
