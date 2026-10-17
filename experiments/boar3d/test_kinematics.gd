extends SceneTree
const Model=preload("res://experiments/boar3d/boar_model.gd")

func _initialize():
	var failures=[]
	# During stance, advancing the body must leave the foot fixed in world space.
	for beat in [0.0,0.25,0.5,0.75]:
		var t=(2.2-beat)*Model.CYCLE
		var dt=0.001
		var a=Model.foot_offset(t,beat)
		var b=Model.foot_offset(t+dt,beat)
		var world_a=t*Model.STRIDE/Model.CYCLE+a.x
		var world_b=(t+dt)*Model.STRIDE/Model.CYCLE+b.x
		if absf(world_a-world_b)>0.00001 or a.y!=0.0 or b.y!=0.0: failures.append("stance foot drift")
	# Both bone lengths must stay invariant throughout the whole cycle.
	for sample in range(128):
		var t=float(sample)/128.0*Model.CYCLE
		var offset=Model.foot_offset(t,0.0)
		var repeat=Model.foot_offset(t+Model.CYCLE,0.0)
		if not offset.is_equal_approx(repeat): failures.append("loop discontinuity")
		for bend in [-1.0,1.0]:
			var root=Vector3(0,0.91+sin(t/Model.CYCLE*TAU*2)*0.018,0.38)
			var foot=Vector3(offset.x,0.12+offset.y,0.38)
			var knee=Model.solve_knee(root,foot,bend)
			if absf(root.distance_to(knee)-Model.UPPER)>0.00001 or absf(knee.distance_to(foot)-Model.LOWER)>0.00001:
				failures.append("bone stretch")
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://experiments/boar3d/frames.json"))
	var image=Image.load_from_file(data.texture)
	if data.count!=16 or image.get_size()!=Vector2i(2048,1536) or image.get_pixel(0,0).a!=0.0:
		failures.append("transparent sheet")
	if failures.is_empty(): print("3D STUDY PASS: stance foot lock, invariant bone lengths, periodic gait, transparent 16-frame export")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
