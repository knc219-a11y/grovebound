extends SceneTree
func _initialize():
	var rig = load("res://animation/boar_cutout.gd").new()
	var max_reach_error = 0.0
	var max_bone_error = 0.0
	var folds = 0
	var image = rig.atlas.get_image()
	for leg in rig.legs:
		var length_total = (51.0 if leg.far else 56.0) if leg.front else (49.0 if leg.far else 55.0)
		var l1 = length_total*0.51
		var l2 = length_total*0.49
		for i in range(32):
			var phase = float(i)/32*TAU
			var lift = -0.45*pow(sin(phase*2),2)
			var root = leg.root+Vector2(0,lift)
			var target = leg.foot+rig.foot_path(phase,leg.beat)
			var pose = rig.solve(root,target,leg.front,length_total)
			max_reach_error = maxf(max_reach_error,pose[2].distance_to(target))
			max_bone_error = maxf(max_bone_error,absf(pose[0].distance_to(pose[1])-l1))
			max_bone_error = maxf(max_bone_error,absf(pose[1].distance_to(pose[2])-l2))
			var vertices = rig.leg_vertices(leg,phase,1,lift)
			var uv = rig.uv_cache[0 if leg.front else 1]
			for j in range(0,rig.index_cache.size(),3):
				var a = rig.index_cache[j]
				var b = rig.index_cache[j+1]
				var c = rig.index_cache[j+2]
				var pixel = Vector2i((uv[a]+uv[b]+uv[c])/3*Vector2(image.get_size()))
				if image.get_pixelv(pixel).a>=0.5 and (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])<=0:
					folds += 1
	var slip = 0.0
	for i in range(20):
		var t = float(i)/40
		var p = rig.foot_path(t*TAU,0)+Vector2(t*rig.STRIDE,0)
		slip = maxf(slip,absf(p.x-rig.STRIDE*rig.DUTY/2))
	print("CUTOUT CHECK: reach error=",max_reach_error," bone error=",max_bone_error," opaque folds=",folds," stance slip=",slip)
	quit(0 if max_reach_error<0.001 and max_bone_error<0.001 and folds==0 and slip<0.001 else 1)
