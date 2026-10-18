extends SceneTree
const Rig=preload("res://animation/boar_pixel.gd")
const Source=preload("res://animation/boar_trot_source.gd")
func _initialize():
	var rig=Rig.new()
	var source=Source.new()
	var failures=[]
	for boss in [false,true]:
		var scale_value=2.0 if boss else 1.0
		var a={"pos":Vector2.ZERO,"hp":100,"walk":true,"boss":boss}
		rig.advance(a,0.05)
		a.pos.x+=110.0*scale_value*0.05
		rig.advance(a,0.05)
		if not a.rig_running or absf(a.rig_phase/TAU-5.5/rig.trot_stride)>0.0001: failures.append("distance cadence and boss scale")
		a.pos.x+=42.0*scale_value*0.05
		rig.advance(a,0.05)
		if not a.rig_running: failures.append("trot hysteresis")
		a.pos.x+=30.0*scale_value*0.05
		rig.advance(a,0.05)
		if a.rig_running: failures.append("slow travel uses walk")
		a.pos.x+=50.0*scale_value*0.05
		rig.advance(a,0.05)
		if not a.rig_running: failures.append("resume trot")
		a.wind=0.2
		a.pos.x+=2
		rig.advance(a,0.05)
		if a.rig_moving: failures.append("windup holds stance")
		a.wind=0.0
		a.walk=false
		rig.advance(a,0.05)
		if a.rig_running or a.rig_moving: failures.append("stop clears gait")
		a.walk=true
		a.pos.x+=200
		rig.advance(a,0.05)
		if a.rig_moving: failures.append("teleport stays still")
		a.hp=0
		a.pos.x+=2
		rig.advance(a,0.05)
		if a.rig_moving: failures.append("downed stays still")
	var charge={"pos":Vector2.ZERO,"hp":100,"walk":true,"boss":true,"dash":0.5}
	rig.advance(charge,0.05)
	charge.pos.x+=42.5
	rig.advance(charge,0.05)
	if charge.rig_phase>TAU*0.05/0.18+0.001: failures.append("extreme boss lunge remains readable")
	var hashes={}
	var atlas=rig.trot_texture.get_image()
	for region in rig.trot_frames:
		var frame=atlas.get_region(Rect2i(region))
		var bounds=frame.get_used_rect()
		if bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=96 or bounds.end.y>=72: failures.append("frame clipped")
		hashes[frame.get_data().hex_encode().sha256_text()]=true
	if rig.trot_frames.size()!=12 or hashes.size()!=12: failures.append("12 distinct trot frames")
	var max_error=0.0
	for leg in source.legs:
		var length_total=(51.0 if leg.far else 56.0) if leg.front else (49.0 if leg.far else 55.0)
		for sample in 42:
			var t=float(sample)/100
			var phase=(t-leg.beat)*TAU
			var target=leg.foot+source.foot_path(phase,leg.beat)
			var lift=-source.body_bob*pow(sin(phase*2),2)
			var pose=source.solve(leg.root+Vector2(0,lift),target,leg.front,length_total)
			max_error=maxf(max_error,pose[2].distance_to(target)*0.48)
		var first=source.foot_path((0.05-leg.beat)*TAU,leg.beat).x+0.05*Source.TROT_STRIDE
		var last=source.foot_path((0.35-leg.beat)*TAU,leg.beat).x+0.35*Source.TROT_STRIDE
		if absf(first-last)>0.001: failures.append("contact cancels world travel")
	if max_error>1.0: failures.append("contact reach exceeds one native pixel")
	print("BOAR CONTACT reach error px: ",max_error)
	if failures.is_empty(): print("BOAR GAIT PASS: distance cadence, boss scale, hysteresis, stop/windup/death, 12 unclipped frames, support contact")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
