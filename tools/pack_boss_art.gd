extends SceneTree
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var source=Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	# Generated front hooves may extend past the nominal half-row. Cut in the blank gutter.
	var cut=source.get_height()/2
	var fewest=2147483647
	for y in range(int(source.get_height()*0.5),int(source.get_height()*0.64)):
		var count=0
		for x in source.get_width():
			if source.get_pixel(x,y).a>=0.5: count+=1
		if count<fewest:
			fewest=count
			cut=y
	var poses=[]
	for row in 2:
		for col in 3:
			var cell=source.get_region(Rect2i(col*source.get_width()/3,0 if row==0 else cut,source.get_width()/3,cut if row==0 else source.get_height()-cut))
			for y in cell.get_height():
				for x in cell.get_width():
					var color=cell.get_pixel(x,y)
					color.a=1.0 if color.a>=0.5 else 0.0
					cell.set_pixel(x,y,color)
			assert(cell.get_used_rect().has_area())
			poses.append(cell.get_region(cell.get_used_rect()))
	# Grounded impact is the original 48px boar; raised front legs may occupy more height.
	var factor=minf(70.0/poses[1].get_width(),48.0/poses[1].get_height())
	for pose in poses: factor=minf(factor,minf(88.0/pose.get_width(),64.0/pose.get_height()))
	var sheet=Image.create(112*3,104*2,false,Image.FORMAT_RGBA8)
	for i in poses.size():
		var pose=poses[i]
		pose.resize(maxi(1,roundi(pose.get_width()*factor)),maxi(1,roundi(pose.get_height()*factor)),Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i((i%3)*112+56-pose.get_width()/2,(i/3)*104+94-pose.get_height()))
	assert(sheet.save_png("res://assets/attacks-v2/boar-boss.png")==OK)
	print("BOSS ART PACK PASS: six distinct poses, common scale, grounded impact <=48px, raised pose <=64px")
	quit()
