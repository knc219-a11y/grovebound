extends SceneTree
const Player = preload("res://animation/pixel_actor.gd")
func _initialize():
	var rig=Player.new("res://animation/druid_walk_frames.json")
	var failures=[]
	if rig.frames.size()!=8: failures.append("frame count")
	if rig.frame_for_phase(0)!=0 or rig.frame_for_phase(0.999)!=7 or rig.frame_for_phase(1)!=0:
		failures.append("phase wraps")
	var a={"pos":Vector2.ZERO,"hp":180,"walk":true}
	rig.advance(a,0.05)
	if a.pixel_moving: failures.append("no motion on first observation")
	a.pos.x+=2
	rig.advance(a,0.05)
	if not a.pixel_moving or a.pixel_phase<=0: failures.append("distance advances gait")
	a.pos.x+=200
	rig.advance(a,0.05)
	if a.pixel_moving or a.pixel_phase!=0: failures.append("teleport does not animate")
	a.pos.x+=1
	rig.advance(a,0.05)
	a.walk=false
	rig.advance(a,0.05)
	if a.pixel_moving or a.pixel_phase!=0: failures.append("stop returns idle")
	a.walk=true
	a.hp=0
	a.pos.x+=1
	rig.advance(a,0.05)
	if a.pixel_moving: failures.append("downed remains still")
	a.hp=180
	a.pos.x+=1
	rig.advance(a,0.05)
	if not a.pixel_moving: failures.append("revive resumes")
	var image=rig.texture.get_image()
	var unique={}
	for region in rig.frames:
		var frame=image.get_region(Rect2i(region))
		var bounds=frame.get_used_rect()
		if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=rig.cell.x or bounds.end.y>=rig.cell.y:
			failures.append("clipped frame")
		unique[frame.get_data().hex_encode().sha256_text()]=true
	if unique.size()!=8: failures.append("eight distinct frames")
	var runner=Player.new("res://animation/druid_walk_frames.json","res://animation/druid_run_frames.json")
	var r={"pos":Vector2.ZERO,"hp":180,"walk":true}
	runner.advance(r,0.05)
	r.pos.x+=10.5
	runner.advance(r,0.05)
	if not r.pixel_running or absf(r.pixel_phase-0.21)>0.001: failures.append("210px/s run cadence follows distance")
	r.pos.x+=4.0
	runner.advance(r,0.05)
	if not r.pixel_running: failures.append("run hysteresis at 80px/s")
	r.pos.x+=1.5
	runner.advance(r,0.05)
	if r.pixel_running: failures.append("slow travel returns walk")
	r.walk=false
	runner.advance(r,0.05)
	if r.pixel_running or r.pixel_moving: failures.append("run stops")
	if runner.run_frames.size()!=12: failures.append("run frame count")
	var run_image=runner.run_texture.get_image()
	var run_unique={}
	for region in runner.run_frames:
		var frame=run_image.get_region(Rect2i(region))
		var bounds=frame.get_used_rect()
		if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=runner.run_cell.x or bounds.end.y>=runner.run_cell.y:
			failures.append("clipped run frame")
		run_unique[frame.get_data().hex_encode().sha256_text()]=true
	if run_unique.size()!=12: failures.append("12 distinct run frames")
	# In the support phase, world travel and backwards foot travel cancel.
	var source=load("res://animation/druid_walk_source.gd").new()
	source.running=true
	var first=source.foot_offset(0.1).x+runner.run_stride*0.1
	var last=source.foot_offset(0.3).x+runner.run_stride*0.3
	if absf(first-last)>0.01: failures.append("support foot travel matches run stride")
	source.free()
	if failures.is_empty():
		print("PIXEL ACTOR PASS: distinct frames, bounds, wrap, distance cadence, teleport, stop, down/revive, run cadence, gait hysteresis, support contact")
		quit()
	else:
		push_error(str(failures))
		quit(1)
