extends Node2D
var stage
var viewport: SubViewport
var font = preload("res://assets/Korean.ttf")
func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport = SubViewport.new()
	viewport.size = Vector2i(720,405)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	stage = preload("res://experiments/pixel/stage.gd").new()
	viewport.add_child(stage)
func _process(_dt):
	queue_redraw()
func _draw():
	draw_texture_rect(viewport.get_texture(),Rect2(0,0,1440,810),false)
	draw_rect(Rect2(20,20,1400,83),Color(0.06,0.07,0.08,0.94))
	draw_string(font,Vector2(45,57),"GROVEBOUND · 어두운 도트 그림체 / 걷기 검토",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("e0d2b2"))
	draw_string(font,Vector2(45,88),"고정 픽셀 격자 · 16색 · 걷기 8프레임 · 실제 Godot 재생",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("b29e88"))
	draw_rect(Rect2(20,445,430,340),Color("202326"))
	draw_string(font,Vector2(40,478),"확대 4배 · 같은 출력 프레임",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("c9b69b"))
	stage.sprite(self,Vector2(235,737),4,stage.face,stage.moving)
	draw_rect(Rect2(480,738,930,47),Color(0.06,0.07,0.08,0.92))
	draw_string(font,Vector2(500,769),"정지 → 오른쪽 걷기 → 왼쪽 걷기 / 본편 교체 전 별도 검토 장면",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("c9b69b"))
