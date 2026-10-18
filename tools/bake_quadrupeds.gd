extends SceneTree
const Source=preload("res://animation/quadruped_source.gd")
func _initialize():
	call_deferred("bake")
func bake():
	var viewport=SubViewport.new()
	var cell=Vector2i(96,72)
	var ground=Vector2i(48,62)
	viewport.size=cell
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var source=Source.new()
	source.position=ground
	viewport.add_child(source)
	var species=OS.get_cmdline_user_args()
	if species.is_empty(): species=["wolf","fox","marten","deer","turtle"]
	for kind in species:
		cell=Vector2i(96,88) if kind=="deer" else Vector2i(96,72)
		ground=Vector2i(48,78) if kind=="deer" else Vector2i(48,62)
		viewport.size=cell
		source.position=ground
		for fast in [false,true]:
			source.configure(kind,fast)
			var count=12
			var sheet=Image.create(cell.x*4,cell.y*3,false,Image.FORMAT_RGBA8)
			for frame in count:
				source.pose(float(frame)/count)
				await process_frame
				await RenderingServer.frame_post_draw
				var image=viewport.get_texture().get_image()
				var used=image.get_used_rect()
				if used.position.x<=0 or used.position.y<=0 or used.end.x>=cell.x or used.end.y>=cell.y:
					push_error(kind+" frame touches cell edge")
					quit(1)
					return
				sheet.blit_rect(image,Rect2i(Vector2i.ZERO,cell),Vector2i(frame%4,frame/4)*cell)
			var action="trot" if fast else "walk"
			var path="res://assets/party-pixel/"+kind+"-"+action+"-v1.png"
			if sheet.save_png(path)!=OK:
				quit(1)
				return
			var metadata={"texture":path,"idle":"res://assets/party-pixel/"+kind+".png","cell":[cell.x,cell.y],"ground":[ground.x,ground.y],"columns":4,"count":count,"native_height":source.config.size.y,"stride_pixels":source.stride(),"minimum_cycle_seconds":0.18 if fast else 0.4,"run_enter_speed":60,"run_exit_speed":45}
			var out=FileAccess.open("res://animation/"+kind+"_"+action+"_frames.json",FileAccess.WRITE)
			out.store_string(JSON.stringify(metadata,"\t")+"\n")
			out.flush()
			out.close()
			print("QUADRUPED BAKE PASS: ",kind," ",action," 12 frames; stride ",source.stride())
	quit()
