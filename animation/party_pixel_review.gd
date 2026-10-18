extends Node2D
var sprites = []
var names = ["Druid","Boar","Marten","Fox","Tortoise","Deer","Wolf"]
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["druid","boar","marten","fox","turtle","deer","wolf"]:
		sprites.append(load("res://assets/boar-pixel-idle.png" if kind=="boar" else "res://assets/party-pixel/"+kind+".png"))
	queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(75,110),"GROVEBOUND / PARTY PIXEL ART",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("e0d2b2"))
	draw_string(font,Vector2(75,158),"Runtime sprites / 3x nearest / shared 32-color palette",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("98a18a"))
	for i in sprites.size():
		var t=sprites[i]
		var p=Vector2(125+i*195,490)
		draw_line(p+Vector2(-85,1),p+Vector2(85,1),Color("4c5c43"),2)
		if i==1:
			draw_texture_rect_region(t,Rect2(p-Vector2(105,144),Vector2(210,144)),Rect2(12,14,70,48))
		else:
			var size=Vector2(t.get_size())*3
			draw_texture_rect(t,Rect2(p-Vector2(size.x/2,size.y),size),false)
		draw_string(font,p+Vector2(-45,55),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e0d2b2"))
	draw_string(font,Vector2(75,680),"Six new appearances / dedicated walk cycles are next",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("98a18a"))
