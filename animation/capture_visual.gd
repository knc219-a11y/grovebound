extends RefCounted
const Loot=preload("res://companion_loot.gd")
var catalog={}
var textures={}
func _init():
	var path="res://animation/capture-v1.json"
	if not FileAccess.file_exists(path): return
	catalog=JSON.parse_string(FileAccess.get_file_as_string(path))
	for kind in catalog: textures[kind]=load(catalog[kind].texture)
func draw(canvas,position,kind,height,time,near,grade="common"):
	if not catalog.has(kind): return
	var p=position.round()
	var color=Loot.COLORS.get(grade,Loot.COLORS.common)
	if not near: color=color.darkened(0.12)
	canvas.draw_set_transform(p,0,Vector2(1,0.35))
	canvas.draw_circle(Vector2.ZERO,22,Color(0.12,0.21,0.12,0.4))
	canvas.draw_arc(Vector2.ZERO,25,0,TAU,20,color,2,false)
	if grade!="common": canvas.draw_arc(Vector2.ZERO,31,0,TAU,24,color,1,false)
	canvas.draw_set_transform(Vector2.ZERO)
	if grade=="epic":
		canvas.draw_rect(Rect2(p+Vector2(-5,-height-12),Vector2(10,height+9)),Color(color,0.10))
		for i in 6:
			var q=p+Vector2(sin(time+i)*19,-fposmod(time*16+i*13,height+25))
			canvas.draw_rect(Rect2(q.round(),Vector2(2,3)),Color(color,0.8))
	elif grade=="rare":
		for i in 3:
			var q=p+Vector2(sin(time+i*2)*21,-fposmod(time*11+i*15,height+15))
			canvas.draw_rect(Rect2(q.round(),Vector2(2,2)),color)
	var scale_value=maxf(1.0,roundf(height/catalog[kind].height))
	var index=posmod(floori(time/0.55),4)
	canvas.draw_set_transform(p,0,Vector2.ONE*scale_value)
	canvas.draw_texture_rect_region(textures[kind],Rect2(-56,-94,112,104),Rect2(index*112,0,112,104),Color("c1c4af"))
	canvas.draw_set_transform(Vector2.ZERO)
	# A small leaf above the resting animal replaces the oversized gold halo.
	var marks=Loot.COUNTS.get(grade,1)
	for i in marks:
		var leaf=p+Vector2((i-(marks-1)/2.0)*12,-height-7)
		canvas.draw_colored_polygon(PackedVector2Array([leaf+Vector2(-5,0),leaf+Vector2(0,-7),leaf+Vector2(5,-1),leaf+Vector2(0,4)]),color)
		canvas.draw_line(leaf+Vector2(0,2),leaf+Vector2(0,-4),Color("344e35"),1,false)
