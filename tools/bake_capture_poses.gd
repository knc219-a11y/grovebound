extends SceneTree
func _initialize(): call_deferred("bake")
func bake():
	DirAccess.make_dir_recursive_absolute("res://assets/capture-v1")
	var vp=SubViewport.new()
	vp.size=Vector2i(112,104)
	vp.transparent_bg=true
	vp.disable_3d=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	var source=load("res://animation/action_source.gd").new()
	source.position=Vector2(56,94)
	vp.add_child(source)
	var manifest={}
	for kind in ["boar","wolf","marten","fox","deer","turtle"]:
		source.configure(kind,"capture")
		var sheet=Image.create(448,104,false,Image.FORMAT_RGBA8)
		for i in 4:
			source.pose(float(i)/4)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame=vp.get_texture().get_image()
			var bounds=frame.get_used_rect()
			if bounds.size==Vector2i.ZERO or bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=112 or bounds.end.y>=104:
				push_error("Capture pose clipped: "+kind)
				quit(1)
				return
			sheet.blit_rect(frame,Rect2i(0,0,112,104),Vector2i(i*112,0))
		var path="res://assets/capture-v1/"+kind+".png"
		if sheet.save_png(path)!=OK:
			quit(1)
			return
		manifest[kind]={"texture":path,"height":source.size.y}
	var file=FileAccess.open("res://animation/capture-v1.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t")+"\n")
	file.close()
	print("CAPTURE BAKE PASS: six species, low resting poses, fixed ground")
	quit()
