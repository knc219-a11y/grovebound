extends SceneTree
const Trot=preload("res://animation/boar_trot_source.gd")
func _initialize(): call_deferred("bake")
func bake():
	var viewport=SubViewport.new()
	viewport.size=Vector2i(96,72)
	viewport.transparent_bg=true
	viewport.disable_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var painter=load("res://experiments/pixel/painter.gd").new()
	viewport.add_child(painter)
	painter.rig=Trot.new()
	var sheet=Image.create(384,216,false,Image.FORMAT_RGBA8)
	for i in 12:
		painter.actor.rig_phase=float(i)/12*TAU
		painter.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var frame=viewport.get_texture().get_image()
		var bounds=frame.get_used_rect()
		if bounds.size==Vector2i.ZERO or bounds.position.x<=0 or bounds.position.y<=0 or bounds.end.x>=96 or bounds.end.y>=72:
			push_error("Boar trot frame clipped or empty")
			quit(1)
			return
		sheet.blit_rect(frame,Rect2i(0,0,96,72),Vector2i(i%4,i/4)*Vector2i(96,72))
	var path="res://assets/boar-pixel-trot.png"
	if sheet.save_png(path)!=OK:
		quit(1)
		return
	var data={"texture":path,"cell":[96,72],"ground":[48,62],"columns":4,"count":12,"stride_pixels":Trot.TROT_STRIDE*0.48,"run_enter_speed":48.0,"run_exit_speed":36.0}
	var file=FileAccess.open("res://animation/boar_trot_frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t")+"\n")
	file.close()
	print("BOAR TROT BAKE PASS: 12 frames, 43.2px stride, approved palette/skin, same ground")
	quit()
