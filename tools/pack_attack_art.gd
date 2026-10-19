extends SceneTree
# Pack generated poses without overwriting approved original sprites.
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var source=Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("res://assets/attacks-v2")
	var kinds=["boar","wolf"]
	for row in 2:
		var poses=[]
		var largest=0
		var tallest=0
		for col in 3:
			var cell=source.get_region(Rect2i(col*source.get_width()/3,row*source.get_height()/2,source.get_width()/3,source.get_height()/2))
			# Quantize alpha so faint generated edge haze is never part of the sprite bounds.
			for y in cell.get_height():
				for x in cell.get_width():
					var color=cell.get_pixel(x,y)
					color.a=1.0 if color.a>=0.5 else 0.0
					cell.set_pixel(x,y,color)
			var box=cell.get_used_rect()
			assert(box.has_area())
			var pose=cell.get_region(box)
			poses.append(pose)
			largest=maxi(largest,pose.get_width())
			tallest=maxi(tallest,pose.get_height())
		var factor=minf((76.0 if row==0 else 75.0)/largest,48.0/tallest)
		var sheet=Image.create(112*6,104,false,Image.FORMAT_RGBA8)
		var idle=Image.load_from_file("res://assets/boar-pixel-idle.png").get_region(Rect2i(12,14,70,48)) if row==0 else Image.load_from_file("res://assets/party-pixel/wolf.png")
		for frame in 6:
			var pose=idle.duplicate() if frame in [0,5] else poses[0 if frame==1 else 1 if frame in [2,3] else 2].duplicate()
			if frame not in [0,5]: pose.resize(maxi(1,roundi(pose.get_width()*factor)),maxi(1,roundi(pose.get_height()*factor)),Image.INTERPOLATE_NEAREST)
			var offset=4 if frame in [2,3] else -2 if frame==1 else 0
			var at=Vector2i(frame*112+56-pose.get_width()/2+offset,94-pose.get_height())
			assert(at.y>0 and pose.get_height()<=52)
			sheet.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),at)
		assert(sheet.save_png("res://assets/attacks-v2/"+kinds[row]+".png")==OK)
		print("ATTACK ART PACK PASS: ",kinds[row]," 6 native-size frames")
	quit()
