extends Node
const COUNT = 8
const CELL = Vector2i(96,72)
var viewport: SubViewport
var painter
func _ready():
	viewport = SubViewport.new()
	viewport.size = CELL
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	painter = preload("res://experiments/pixel/painter.gd").new()
	viewport.add_child(painter)
	call_deferred("export_frames")
func export_frames():
	var sheet = Image.create(CELL.x*4,CELL.y*2,false,Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	var bounds = Rect2i()
	for i in range(COUNT+1):
		painter.actor.rig_phase = float(i%COUNT)/COUNT*TAU
		painter.actor.rig_move = 0.0 if i==COUNT else 1.0
		painter.queue_redraw()
		await RenderingServer.frame_post_draw
		var frame = viewport.get_texture().get_image()
		frame.convert(Image.FORMAT_RGBA8)
		var used = frame.get_used_rect()
		if used.size==Vector2i.ZERO or used.position.x<=0 or used.position.y<=0 or used.end.x>=CELL.x or used.end.y>=CELL.y:
			push_error("Pixel sprite cropped or empty"); get_tree().quit(1); return
		if i<COUNT:
			bounds = used if i==0 else bounds.merge(used)
			sheet.blit_rect(frame,Rect2i(Vector2i.ZERO,CELL),Vector2i(i%4*CELL.x,int(i/4)*CELL.y))
		else: frame.save_png("res://assets/boar-pixel-idle.png")
	if sheet.save_png("res://assets/boar-pixel-walk.png")!=OK:
		push_error("Cannot save pixel sheet");get_tree().quit(1);return
	var data = {"texture":"res://assets/boar-pixel-walk.png","idle":"res://assets/boar-pixel-idle.png","cell":[96,72],"ground":[48,62],"count":8,"columns":4,"cycle_seconds":0.85,"stride_pixels":14.4,"palette_colors":16,"bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]}
	var file = FileAccess.open("res://experiments/pixel/frames.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t")+"\n")
	print("PIXEL EXPORT PASS: 8 frames + idle, 96x72 cells, 16-color shader, shared ground; bounds ",bounds)
	get_tree().quit()
