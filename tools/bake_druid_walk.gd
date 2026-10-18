extends SceneTree
const Source = preload("res://animation/druid_walk_source.gd")
func _initialize():
	call_deferred("bake")
func bake():
	var viewport=SubViewport.new()
	viewport.size=Vector2i(64,88)
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var source=Source.new()
	source.position=Vector2(28,80)
	viewport.add_child(source)
	var sheet=Image.create(256,176,false,Image.FORMAT_RGBA8)
	for frame in range(8):
		source.pose(float(frame)/8)
		await process_frame
		await RenderingServer.frame_post_draw
		var image=viewport.get_texture().get_image()
		var used=image.get_used_rect()
		if used.position.x<=0 or used.position.y<=0 or used.end.x>=64 or used.end.y>=88:
			push_error("Druid walk frame touches cell edge")
			quit(1)
			return
		sheet.blit_rect(image,Rect2i(0,0,64,88),Vector2i(frame%4,frame/4)*Vector2i(64,88))
	var path="res://assets/party-pixel/druid-walk-v1.png"
	if sheet.save_png(path)!=OK:
		quit(1)
		return
	var metadata={"texture":path,"idle":"res://assets/party-pixel/druid.png","cell":[64,88],"ground":[28,80],"columns":4,"count":8,"native_height":72,"stride_pixels":16.13,"minimum_cycle_seconds":0.46}
	var out=FileAccess.open("res://animation/druid_walk_frames.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(metadata,"\t")+"\n")
	print("DRUID BAKE PASS: 8 padded, foot-anchored native pixel frames")
	quit()
