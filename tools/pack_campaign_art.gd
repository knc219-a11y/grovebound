extends SceneTree
const KINDS=["bat","slime","golem","skeleton","wraith","guardian"]
const HEIGHTS=[32,30,60,52,50,60]
# Measured opaque components from the generated source; the painted rows are not equal-height cells.
const REGIONS=[
	[[48,114,161,118],[298,61,178,164],[571,49,153,176],[784,75,197,155]],
	[[53,336,156,108],[310,336,163,104],[553,352,164,92],[780,356,224,91]],
	[[38,490,186,204],[289,496,194,197],[539,492,165,203],[772,508,240,187]],
	[[57,740,184,213],[309,740,186,214],[543,743,168,212],[753,743,258,211]],
	[[38,998,184,227],[285,1003,175,223],[523,1003,180,226],[784,1007,220,211]],
	[[38,1260,212,239],[304,1259,203,239],[539,1262,198,238],[757,1268,248,232]]]
func _initialize():
	DirAccess.make_dir_recursive_absolute("res://assets/campaign")
	var args=OS.get_cmdline_user_args()
	assert(args.size()==3,"quarry source, graveyard source, transparent atlas source required")
	for i in 2:
		var image=Image.load_from_file(args[i])
		assert(image!=null)
		image.resize(1450,825,Image.INTERPOLATE_NEAREST)
		image.resize(2900,1650,Image.INTERPOLATE_NEAREST)
		assert(image.save_webp("res://assets/campaign/"+("quarry" if i==0 else "graveyard")+"-v1.webp",false)==OK)
	var source=Image.load_from_file(args[2])
	assert(source!=null and source.get_pixel(0,0).a<0.1,"sprite atlas needs actual transparency")
	for row in 6:
		var union=Rect2i()
		for column in 4:
			var r=REGIONS[row][column]
			var relative=Rect2i(r[0]-column*256,r[1],r[2],r[3])
			union=relative if column==0 else union.merge(relative)
		var ratio=float(HEIGHTS[row])/union.size.y
		var sheet=Image.create_empty(448,104,false,Image.FORMAT_RGBA8)
		for column in 4:
			var r=REGIONS[row][column]
			var frame=Image.create_empty(union.size.x,union.size.y,false,Image.FORMAT_RGBA8)
			frame.blit_rect(source,Rect2i(r[0],r[1],r[2],r[3]),Vector2i(r[0]-column*256-union.position.x,r[1]-union.position.y))
			frame.resize(maxi(1,roundi(union.size.x*ratio)),HEIGHTS[row],Image.INTERPOLATE_NEAREST)
			for y in frame.get_height():
				for x in frame.get_width():
					var color=frame.get_pixel(x,y)
					color.a=1.0 if color.a>=0.5 else 0.0
					frame.set_pixel(x,y,color)
			sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(column*112+56-frame.get_width()/2,94-HEIGHTS[row]))
		assert(sheet.save_png("res://assets/campaign/"+KINDS[row]+"-v1.png")==OK)
	print("CAMPAIGN ART PACK PASS")
	quit()
