extends Button
const UI=preload("res://ui/grove_ui.gd")
var healing=true
var cooldown=0.0
func refresh(wait):
	cooldown=wait
	queue_redraw()
func _draw():
	var font=get_theme_font("font")
	var col=UI.GREEN if healing else Color("d1ad6d")
	var p=Vector2(25,29)
	if healing:
		draw_rect(Rect2(p-Vector2(3,10),Vector2(6,20)),col)
		draw_rect(Rect2(p-Vector2(10,3),Vector2(20,6)),col)
	else:
		draw_colored_polygon(PackedVector2Array([p+Vector2(-9,8),p+Vector2(-6,-7),p+Vector2(10,-10),p+Vector2(7,5)]),col)
		draw_line(p+Vector2(-7,8),p+Vector2(7,-6),UI.INK,2,false)
	draw_string(font,Vector2(44,36),"회복  Q" if healing else "야성  E",HORIZONTAL_ALIGNMENT_LEFT,-1,20,UI.PAPER)
	if cooldown>0:
		draw_string(font,Vector2(17,75),str(ceili(cooldown))+"초",HORIZONTAL_ALIGNMENT_LEFT,-1,25,col)
	else:
		draw_string(font,Vector2(17,75),"사용 가능",HORIZONTAL_ALIGNMENT_LEFT,-1,19,col)
	draw_string(font,Vector2(16,101),"체력 낮은 아군" if healing else "공격력 +60%",HORIZONTAL_ALIGNMENT_LEFT,-1,14,UI.MUTED)
