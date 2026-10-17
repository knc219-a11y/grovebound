extends Node
const Model=preload("res://experiments/boar3d/boar_model.gd")
const COUNT=16
const SIZE=Vector2i(512,384)
var viewport: SubViewport
var model

func _ready():
	viewport=SubViewport.new()
	viewport.size=SIZE
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	add_child(viewport)
	model=Model.new()
	viewport.add_child(model)
	call_deferred("export_cycle")

func export_cycle():
	var sheet=Image.create(SIZE.x*4,SIZE.y*4,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var bounds=Rect2i()
	var images=[]
	for i in range(COUNT):
		model.set_pose(float(i)/COUNT*Model.CYCLE)
		await RenderingServer.frame_post_draw
		var frame=viewport.get_texture().get_image()
		frame.convert(Image.FORMAT_RGBA8)
		images.append(frame)
		bounds=frame.get_used_rect() if i==0 else bounds.merge(frame.get_used_rect())
		var used=frame.get_used_rect()
		if used.size==Vector2i.ZERO or used.position.x<=0 or used.end.x>=SIZE.x or used.position.y<=0 or used.end.y>=SIZE.y:
			push_error("3D sprite touches camera edge"); get_tree().quit(1); return
	for i in range(COUNT):
		sheet.blit_rect(images[i],Rect2i(Vector2i.ZERO,SIZE),Vector2i(i%4*SIZE.x,int(i/4)*SIZE.y))
	var target="res://assets/boar3d-walk-sheet.png"
	if sheet.save_png(target)!=OK:
		push_error("Cannot save 3D sheet"); get_tree().quit(1); return
	model.set_pose(0.0)
	var ground=model.camera.unproject_position(Vector3(0,0,0))
	var metadata={"texture":target,"count":COUNT,"columns":4,"rows":4,"cell":[SIZE.x,SIZE.y],"cycle_seconds":Model.CYCLE,"crop":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"ground":[ground.x-bounds.position.x,ground.y-bounds.position.y]}
	var file=FileAccess.open("res://experiments/boar3d/frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata,"\t")+"\n")
	print("3D EXPORT PASS: 16 orthographic transparent frames; shared crop ",bounds)
	get_tree().quit()
