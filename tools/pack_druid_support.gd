extends SceneTree
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var source=Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	var poses=[]
	var tallest=0
	for col in 3:
		var cell=source.get_region(Rect2i(col*source.get_width()/3,0,source.get_width()/3,source.get_height()))
		for y in cell.get_height():
			for x in cell.get_width():
				var c=cell.get_pixel(x,y)
				c.a=1 if c.a>=0.5 else 0
				cell.set_pixel(x,y,c)
		var pose=cell.get_region(cell.get_used_rect())
		poses.append(pose)
		tallest=maxi(tallest,pose.get_height())
	var factor=72.0/tallest
	var sheet=Image.create(672,312,false,Image.FORMAT_RGBA8)
	var idle=Image.load_from_file("res://assets/party-pixel/druid-body-v2.png")
	for row in 3:
		var pose=poses[row]
		pose.resize(roundi(pose.get_width()*factor),roundi(pose.get_height()*factor),Image.INTERPOLATE_NEAREST)
		assert(pose.get_width()<100 and pose.get_height()<=72)
		for frame in 6:
			var image=pose if row==2 or frame<4 else idle
			var at=Vector2i(frame*112+56-image.get_width()/2,row*104+94-image.get_height())
			sheet.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),at)
	assert(sheet.save_png("res://assets/attacks-v2/druid-support.png")==OK)
	print("DRUID SUPPORT PACK PASS: heal/buff/revive body-only, shared scale, native height <=72")
	quit()
