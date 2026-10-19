extends SceneTree
# Pack generated poses without overwriting approved original sprites.
func gap(image,start,end,vertical):
	var best=start
	var smallest=2147483647
	for line in range(start,end):
		var count=0
		for pixel in (image.get_height() if vertical else image.get_width()):
			var color=image.get_pixel(line,pixel) if vertical else image.get_pixel(pixel,line)
			if color.a>=0.5: count+=1
		if count<smallest:
			smallest=count
			best=line
	return best
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var source=Image.load_from_file(args[0])
	source.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute("res://assets/attacks-v2")
	var kinds=[args[1],args[2]] if args.size()>=3 else ["boar","wolf"]
	# Tall antlers may cross the nominal half-row; split support sources in blank gutters.
	var support=kinds==["deer","turtle"]
	var cut=gap(source,int(source.get_height()*0.5),int(source.get_height()*0.7),false) if support else source.get_height()/2
	for row in 2:
		var strip=source.get_region(Rect2i(0,0 if row==0 else cut,source.get_width(),cut if row==0 else source.get_height()-cut))
		var columns=[0,source.get_width()/3,source.get_width()*2/3,source.get_width()]
		if support:
			for boundary in [1,2]: columns[boundary]=gap(strip,int(source.get_width()*(boundary/3.0-0.04)),int(source.get_width()*(boundary/3.0+0.04)),true)
		var poses=[]
		var largest=0
		var tallest=0
		for col in 3:
			var cell=strip.get_region(Rect2i(columns[col],0,columns[col+1]-columns[col],strip.get_height()))
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
		var height={"boar":48.0,"wolf":48.0,"marten":32.0,"fox":40.0,"deer":64.0,"turtle":32.0}[kinds[row]]
		var width={"boar":76.0,"wolf":75.0,"marten":80.0,"fox":65.0,"deer":57.0,"turtle":56.0}[kinds[row]]
		var factor=minf(width/largest,height/tallest)
		var sheet=Image.create(112*6,104,false,Image.FORMAT_RGBA8)
		var idle=Image.load_from_file("res://assets/boar-pixel-idle.png").get_region(Rect2i(12,14,70,48)) if kinds[row]=="boar" else Image.load_from_file("res://assets/party-pixel/"+kinds[row]+".png")
		for frame in 6:
			var pose=idle.duplicate() if frame in [0,5] else poses[0 if frame==1 else 1 if frame in [2,3] else 2].duplicate()
			if frame not in [0,5]: pose.resize(maxi(1,roundi(pose.get_width()*factor)),maxi(1,roundi(pose.get_height()*factor)),Image.INTERPOLATE_NEAREST)
			var offset=4 if frame in [2,3] else -2 if frame==1 else 0
			if kinds[row] in ["deer","turtle"]: offset=0
			var at=Vector2i(frame*112+56-pose.get_width()/2+offset,94-pose.get_height())
			assert(at.y>0 and pose.get_height()<=height)
			sheet.blit_rect(pose,Rect2i(Vector2i.ZERO,pose.get_size()),at)
		assert(sheet.save_png("res://assets/attacks-v2/"+kinds[row]+".png")==OK)
		print("ATTACK ART PACK PASS: ",kinds[row]," 6 native-size frames")
	quit()
