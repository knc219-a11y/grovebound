extends SceneTree
func foot_center(image):
	var height=maxi(2,roundi(image.get_height()*0.10))
	return image.get_region(Rect2i(0,image.get_height()-height,image.get_width(),height)).get_used_rect().get_center().x
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var source=Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	var cut=source.get_height()/2
	var fewest=2147483647
	for y in range(int(source.get_height()*0.43),int(source.get_height()*0.60)):
		var count=0
		for x in source.get_width():
			if source.get_pixel(x,y).a>=0.5: count+=1
		if count<fewest: fewest=count; cut=y
	var poses=[]
	var tallest=0
	for row in 2:
		for col in 3:
			var cell=source.get_region(Rect2i(col*source.get_width()/3,0 if row==0 else cut,source.get_width()/3,cut if row==0 else source.get_height()-cut))
			for y in cell.get_height():
				for x in cell.get_width():
					var color=cell.get_pixel(x,y)
					color.a=1 if color.a>=0.5 else 0
					cell.set_pixel(x,y,color)
			var bounds=cell.get_used_rect()
			assert(bounds.has_area())
			var pose=cell.get_region(bounds)
			poses.append(pose)
			tallest=maxi(tallest,pose.get_height())
	var idle=Image.load_from_file("res://assets/party-pixel/druid-body-v2.png")
	var factor=float(idle.get_used_rect().size.y)/tallest
	var anchor=56-idle.get_width()/2.0+foot_center(idle)
	var sheet=Image.create(112*8,104,false,Image.FORMAT_RGBA8)
	for i in 8:
		var pose=idle.duplicate() if i in [0,7] else poses[i-1].duplicate()
		if i not in [0,7]: pose.resize(roundi(pose.get_width()*factor),roundi(pose.get_height()*factor),Image.INTERPOLATE_NEAREST)
		var x=56-idle.get_width()/2 if i in [0,7] else roundi(anchor-foot_center(pose))
		if i not in [0,7]: assert(pose.get_height()<=60 and x>0)
		sheet.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),Vector2i(i*112+x,94-pose.get_height()))
	assert(sheet.save_png("res://assets/attacks-v2/druid-attack-v1.png")==OK)
	print("DRUID ATTACK PACK PASS: six new sequential poses + original idle endpoints, shared60px body scale and grounded feet anchor")
	quit()
