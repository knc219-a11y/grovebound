extends Control
const UI=preload("res://ui/grove_ui.gd")
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	var center=Vector2(180,175)
	draw_circle(center,108,Color(0.07,0.11,0.09,0.72))
	draw_arc(center,114,-PI*0.94,-PI*0.06,28,Color(UI.BRONZE,0.65),2,false)
	draw_arc(center,119,-PI*0.91,-PI*0.09,28,Color(UI.BRONZE,0.22),1,false)
	draw_arc(center,114,0.15,PI-0.15,28,Color(UI.BRONZE,0.4),1,false)
	for side in [-1,1]:
		for i in 4:
			var p=center+Vector2(side*(102-i*7),35+i*15)
			UI.leaf(self,p,4,Color(UI.GREEN,0.55))
	draw_line(center+Vector2(-65,123),center+Vector2(-12,123),UI.BRONZE,1,false)
	draw_line(center+Vector2(12,123),center+Vector2(65,123),UI.BRONZE,1,false)
	UI.leaf(self,center+Vector2(0,123),5,UI.GREEN)
