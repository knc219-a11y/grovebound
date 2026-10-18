extends SceneTree
const Source = preload("res://animation/druid_walk_source.gd")
func _initialize():
	call_deferred("bake")
func bake():
	var running="--run" in OS.get_cmdline_user_args()
	var cell=Vector2i(80,96) if running else Vector2i(64,88)
	var ground=Vector2i(36,88) if running else Vector2i(28,80)
	var count=12 if running else 8
	var viewport=SubViewport.new()
	viewport.size=cell
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var source=Source.new()
	source.position=ground
	source.running=running
	viewport.add_child(source)
	var sheet=Image.create(cell.x*4,cell.y*ceili(count/4.0),false,Image.FORMAT_RGBA8)
	for frame in range(count):
		source.pose(float(frame)/count)
		await process_frame
		await RenderingServer.frame_post_draw
		var image=viewport.get_texture().get_image()
		var used=image.get_used_rect()
		if used.position.x<=0 or used.position.y<=0 or used.end.x>=cell.x or used.end.y>=cell.y:
			push_error("Druid walk frame touches cell edge")
			quit(1)
			return
		sheet.blit_rect(image,Rect2i(Vector2i.ZERO,cell),Vector2i(frame%4,frame/4)*cell)
	var path="res://assets/party-pixel/druid-run-v1.png" if running else "res://assets/party-pixel/druid-walk-v1.png"
	if sheet.save_png(path)!=OK:
		quit(1)
		return
	var metadata={"texture":path,"idle":"res://assets/party-pixel/druid.png","cell":[cell.x,cell.y],"ground":[ground.x,ground.y],"columns":4,"count":count,"native_height":72,"stride_pixels":50.0 if running else 16.13,"minimum_cycle_seconds":0.18 if running else 0.46}
	var out=FileAccess.open("res://animation/druid_run_frames.json" if running else "res://animation/druid_walk_frames.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(metadata,"\t")+"\n")
	print("DRUID BAKE PASS: ",count," padded, foot-anchored native pixel frames")
	quit()
