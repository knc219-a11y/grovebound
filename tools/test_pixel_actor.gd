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
	var phase=a.pixel_phase
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
	if failures.is_empty():
		print("PIXEL ACTOR PASS: distinct frames, bounds, wrap, distance cadence, teleport, stop, down/revive")
		quit()
	else:
		push_error(str(failures))
		quit(1)
