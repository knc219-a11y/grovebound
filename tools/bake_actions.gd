extends SceneTree
const Source=preload("res://animation/action_source.gd")
const ACTIONS={"boar":["attack"],"wolf":["attack"],"marten":["attack"],"fox":["cast"],"deer":["heal"],"turtle":["attack","guard"],"druid":["support","heal","revive"]}
func _initialize(): call_deferred("bake")
func bake():
	DirAccess.make_dir_recursive_absolute("res://assets/actions-v1")
	var vp=SubViewport.new()
	vp.size=Vector2i(112,104)
	vp.transparent_bg=true
	vp.disable_3d=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(vp)
	var source=Source.new()
	source.position=Vector2(56,94)
	vp.add_child(source)
	var manifest={}
	for kind in ACTIONS:
		var sheet=Image.create(448,208*ACTIONS[kind].size(),false,Image.FORMAT_RGBA8)
		var records={}
		for action_index in ACTIONS[kind].size():
			var action=ACTIONS[kind][action_index]
			source.configure(kind,action)
			var frames=[]
			for frame in range(8):
				var phase=float(frame)/8 if action=="revive" else float(frame)/7
				source.pose(phase)
				await process_frame
				await RenderingServer.frame_post_draw
				var img=vp.get_texture().get_image()
				var used=img.get_used_rect()
				if used.position.x<=0 or used.position.y<=0 or used.end.x>=112 or used.end.y>=104:
					push_error("Action clipped: "+kind+" "+action)
					quit(1)
					return
				var pos=Vector2i(frame%4,(frame/4)+action_index*2)*Vector2i(112,104)
				sheet.blit_rect(img,Rect2i(0,0,112,104),pos)
				frames.append([pos.x,pos.y,112,104])
			records[action]={"frames":frames,"duration":0.42 if action in ["heal","support","guard","cast"] else 0.30,"loop":action=="revive"}
		var path="res://assets/actions-v1/"+kind+".png"
		if sheet.save_png(path)!=OK:
			quit(1)
			return
		manifest[kind]={"texture":path,"height":source.size.y,"ground":[56,94],"actions":records}
		print("ACTION BAKE PASS: ",kind," ",records.keys())
	var out=FileAccess.open("res://animation/actions-v1.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(manifest,"\t")+"\n")
	out.flush()
	out.close()
	quit()
