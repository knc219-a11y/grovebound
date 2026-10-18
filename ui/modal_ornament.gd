extends Control
const UI=preload("res://ui/grove_ui.gd")
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	var w=size.x
	var bronze=UI.BRONZE
	draw_line(Vector2(30,110),Vector2(w-30,110),Color(bronze,0.5),1,false)
	draw_line(Vector2(30,size.y-102),Vector2(w-30,size.y-102),Color(bronze,0.25),1,false)
	for side in [-1,1]:
		var x=w/2+side*22
		draw_line(Vector2(x,-2),Vector2(w/2+side*105,-2),bronze,1,false)
		UI.leaf(self,Vector2(w/2+side*115,-2),3,bronze)
	UI.medallion(self,Vector2(w/2,-2),16,bronze)
	UI.leaf(self,Vector2(w/2,-2),8,UI.GREEN)
	for p in [Vector2(18,18),Vector2(w-18,18),Vector2(18,size.y-18),Vector2(w-18,size.y-18)]:
		draw_rect(Rect2(p-Vector2(1,1),Vector2(3,3)),bronze)
