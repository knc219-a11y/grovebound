extends SceneTree
const KINDS=["thornling","shaman","sentinel","cycle_guardian"]
const HEIGHTS=[46,54,62,66]
func _initialize():
	var args=OS.get_cmdline_user_args()
	assert(args.size()==1,"A transparent four-by-four source atlas path is required")
	var source=Image.load_from_file(args[0])
	assert(source!=null and source.get_pixel(0,0).a<0.1)
	var cell=Vector2i(source.get_width()/4,source.get_height()/4)
	for row in 4:
		var union=Rect2i(); var frames=[]
		for column in 4:
			var frame=source.get_region(Rect2i(Vector2i(column,row)*cell,cell))
			for y in frame.get_height():
				for x in frame.get_width():
					var color=frame.get_pixel(x,y); color.a=1.0 if color.a>=0.5 else 0.0; frame.set_pixel(x,y,color)
			frames.append(frame)
			union=frame.get_used_rect() if column==0 else union.merge(frame.get_used_rect())
		var sheet=Image.create_empty(448,104,false,Image.FORMAT_RGBA8)
		for column in 4:
			var frame=frames[column].get_region(union)
			frame.resize(maxi(1,roundi(float(union.size.x)*HEIGHTS[row]/union.size.y)),HEIGHTS[row],Image.INTERPOLATE_NEAREST)
			sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,frame.get_size()),Vector2i(column*112+56-frame.get_width()/2,94-HEIGHTS[row]))
		assert(sheet.save_png("res://assets/campaign/"+KINDS[row]+"-v1.png")==OK)
	print("FRONTIER ART PACK PASS")
	quit()
