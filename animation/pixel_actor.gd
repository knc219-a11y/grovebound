extends RefCounted
# Reusable native-pixel frame player. Rigs and source meshes stay build-time only.
var texture: Texture2D
var frames=[]
var cell: Vector2
var ground: Vector2
var native_height: float
var stride: float
var minimum_cycle: float
var run_texture: Texture2D
var run_frames=[]
var run_cell: Vector2
var run_ground: Vector2
var run_stride=50.0
var run_minimum_cycle=0.18
var run_enter_speed=90.0
var run_exit_speed=65.0
func _init(manifest,run_manifest=""):
	var data=JSON.parse_string(FileAccess.get_file_as_string(manifest))
	texture=load(data.texture)
	cell=Vector2(data.cell[0],data.cell[1])
	ground=Vector2(data.ground[0],data.ground[1])
	native_height=data.native_height
	stride=data.stride_pixels
	minimum_cycle=data.minimum_cycle_seconds
	for i in int(data.count):
		frames.append(Rect2(Vector2(i%int(data.columns),i/int(data.columns)).floor()*cell,cell))
	if not run_manifest.is_empty():
		var run=JSON.parse_string(FileAccess.get_file_as_string(run_manifest))
		run_texture=load(run.texture)
		run_cell=Vector2(run.cell[0],run.cell[1])
		run_ground=Vector2(run.ground[0],run.ground[1])
		run_stride=run.stride_pixels
		run_minimum_cycle=run.minimum_cycle_seconds
		run_enter_speed=run.get("run_enter_speed",90.0)
		run_exit_speed=run.get("run_exit_speed",65.0)
		for i in int(run.count):
			run_frames.append(Rect2(Vector2(i%int(run.columns),i/int(run.columns)).floor()*run_cell,run_cell))
func frame_for_phase(phase):
	return posmod(floori(phase*frames.size()),frames.size())
func advance(actor,dt):
	actor.pixel_down=move_toward(actor.get("pixel_down",0.0),1.0 if actor.hp<=0 else 0.0,maxf(0,dt)/0.22)
	var distance=actor.pos.distance_to(actor.get("pixel_last",actor.pos))
	actor.pixel_last=actor.pos
	var moving=actor.get("walk",false) and actor.hp>0 and distance>0.001 and distance<100 and actor.get("wind",0.0)<=0
	if moving:
		var scale_value=2.0 if actor.get("boss",false) else 1.0
		var speed=distance/maxf(dt,0.001)/scale_value
		# Hysteresis prevents walk/run flicker near the speed threshold.
		actor.pixel_running=run_texture!=null and speed>(run_exit_speed if actor.get("pixel_running",false) else run_enter_speed)
		var travel_stride=run_stride if actor.pixel_running else stride
		var cycle_limit=run_minimum_cycle if actor.pixel_running else minimum_cycle
		var cycles=minf(distance/(travel_stride*scale_value),maxf(0,dt)/cycle_limit)
		actor.pixel_phase=fposmod(actor.get("pixel_phase",0.0)+cycles,1.0)
	actor.pixel_moving=moving
	if not moving:
		actor.pixel_phase=0.0
		actor.pixel_running=false
func draw(canvas,position,height,face,tint,actor,idle):
	var scale_value=maxf(1.0,roundf(height/native_height))
	var down=actor.hp<=0
	var moving=actor.get("pixel_moving",false) and not down and actor.get("wind",0.0)<=0
	var tilt=-0.75*face*smoothstep(0.0,1.0,actor.get("pixel_down",1.0 if down else 0.0))
	canvas.draw_set_transform_matrix(Transform2D(tilt,position.round()).scaled_local(Vector2(face,1)*scale_value))
	if moving:
		if actor.get("pixel_running",false) and run_texture!=null:
			var index=posmod(floori(actor.get("pixel_phase",0.0)*run_frames.size()),run_frames.size())
			canvas.draw_texture_rect_region(run_texture,Rect2(-run_ground,run_cell),run_frames[index],tint)
		else:
			canvas.draw_texture_rect_region(texture,Rect2(-ground,cell),frames[frame_for_phase(actor.get("pixel_phase",0.0))],tint)
	else:
		canvas.draw_texture_rect(idle,Rect2(Vector2(-idle.get_width()/2.0,-idle.get_height()),idle.get_size()),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
