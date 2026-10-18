extends HBoxContainer
const UI=preload("res://ui/grove_ui.gd")
var accent=UI.BRONZE
func _draw():
	var style=UI.frame(Color("232d29"),Color(accent,0.30))
	style.shadow_size=1
	style.chamfer=9
	style.draw(get_canvas_item(),Rect2(Vector2.ZERO,size))
	UI.medallion(self,Vector2(28,size.y/2),25,accent)
	draw_line(Vector2(62,12),Vector2(62,size.y-12),Color(accent,0.24),1,false)
