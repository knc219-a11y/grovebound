extends RefCounted
var catalog={}
var textures={}
func _init():
	var path="res://animation/capture-v1.json"
	if not FileAccess.file_exists(path): return
	catalog=JSON.parse_string(FileAccess.get_file_as_string(path))
	for kind in catalog: textures[kind]=load(catalog[kind].texture)
func draw(canvas,position,kind,height,time,near):
	if not catalog.has(kind): return
	var p=position.round()
	var color=Color("b8d59c") if near else Color("779b73")
	canvas.draw_set_transform(p,0,Vector2(1,0.35))
	canvas.draw_circle(Vector2.ZERO,22,Color(0.12,0.21,0.12,0.4))
	canvas.draw_arc(Vector2.ZERO,25,0,TAU,20,color,2,false)
	canvas.draw_set_transform(Vector2.ZERO)
	var scale_value=maxf(1.0,roundf(height/catalog[kind].height))
	var index=posmod(floori(time/0.55),4)
	canvas.draw_set_transform(p,0,Vector2.ONE*scale_value)
	canvas.draw_texture_rect_region(textures[kind],Rect2(-56,-94,112,104),Rect2(index*112,0,112,104),Color("c1c4af"))
	canvas.draw_set_transform(Vector2.ZERO)
	# A small leaf above the resting animal replaces the oversized gold halo.
	var leaf=p+Vector2(0,-height-7)
	canvas.draw_colored_polygon(PackedVector2Array([leaf+Vector2(-5,0),leaf+Vector2(0,-7),leaf+Vector2(5,-1),leaf+Vector2(0,4)]),color)
	canvas.draw_line(leaf+Vector2(0,2),leaf+Vector2(0,-4),Color("344e35"),1,false)
