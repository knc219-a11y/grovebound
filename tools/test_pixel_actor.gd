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
	if a.pixel_down<=0 or a.pixel_down>=1: failures.append("fall starts gradually")
	a.hp=180
	a.pos.x+=1
	rig.advance(a,0.05)
	if not a.pixel_moving: failures.append("revive resumes")
	if a.pixel_down!=0: failures.append("revive returns upright")
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
	for kind in ["wolf","fox","marten","deer","turtle"]:
		var quad=Player.new("res://animation/"+kind+"_walk_frames.json","res://animation/"+kind+"_trot_frames.json")
		var qa={"pos":Vector2.ZERO,"hp":100,"walk":true}
		var qb={"pos":Vector2.ZERO,"hp":100,"walk":false}
		quad.advance(qa,0.05)
		quad.advance(qb,0.05)
		qa.pos.x+=6.5
		quad.advance(qa,0.05)
		quad.advance(qb,0.05)
		if not qa.pixel_running or qb.pixel_moving or qb.pixel_phase!=0: failures.append(kind+" independent duplicate state")
		qa.swing=0.15
		qa.pos.x+=1
		quad.advance(qa,0.05)
		if not qa.pixel_moving: failures.append(kind+" moving strike keeps feet animated")
		qa.swing=0.0
		qa.wind=0.3
		qa.pos.x+=1
		quad.advance(qa,0.05)
		if qa.pixel_moving: failures.append(kind+" windup holds stance")
		qa.wind=0.0
		qa.pos.x+=6.5
		quad.advance(qa,0.05)
		if not qa.pixel_moving or not qa.pixel_running: failures.append(kind+" resumes trot")
		qa.pixel_phase=0.0
		qa.pos.x+=6.5
		quad.advance(qa,0.05)
		var scaled={"pos":Vector2.ZERO,"hp":100,"walk":true,"boss":true}
		quad.advance(scaled,0.05)
		scaled.pos.x+=13.0
		quad.advance(scaled,0.05)
		if absf(scaled.pixel_phase-qa.pixel_phase)>0.001: failures.append(kind+" scaled stride")
		for gait in [false,true]:
			var frames=quad.run_frames if gait else quad.frames
			var atlas=quad.run_texture.get_image() if gait else quad.texture.get_image()
			var cell=quad.run_cell if gait else quad.cell
			var hashes={}
			if frames.size()!=12: failures.append(kind+" 12 frames per gait")
			for region in frames:
				var frame=atlas.get_region(Rect2i(region))
				var bounds=frame.get_used_rect()
				if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=cell.x or bounds.end.y>=cell.y:
					failures.append(kind+" clipped frame")
				hashes[frame.get_data().hex_encode().sha256_text()]=true
			if hashes.size()<(6 if kind=="turtle" else 12): failures.append(kind+" distinct gait frames")
			var skin=load("res://animation/quadruped_source.gd").new()
			skin.configure(kind,gait)
			var support_a=skin.foot_offset(0.05,0).x+skin.stride()*0.05
			var support_b=skin.foot_offset(0.3,0).x+skin.stride()*0.3
			if absf(support_a-support_b)>0.01: failures.append(kind+" support contact")
			if gait and not skin.config.get("no_trot",false) and skin.beats()[0]!=skin.beats()[3]: failures.append(kind+" diagonal trot")
			skin.free()
	if failures.is_empty():
		print("PIXEL ACTOR PASS: distinct frames, bounds, wrap, distance cadence, teleport, stop, down/revive, run cadence, gait hysteresis, support contact")
		quit()
	else:
		push_error(str(failures))
		quit(1)
