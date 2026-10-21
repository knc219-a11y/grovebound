extends Button
var symbol="hamburger"
func _draw():
	var c=Color("827b68") if disabled else Color("d8ccab")
	var p=Vector2(size.x/2,29)
	match symbol:
		"hamburger":
			for y in [-8,0,8]: draw_line(p+Vector2(-12,y),p+Vector2(12,y),c,3)
		"menu":
			draw_arc(p,14,0,TAU,24,c,2)
			draw_colored_polygon(PackedVector2Array([p+Vector2(7,-9),p+Vector2(2,4),p+Vector2(-7,9),p+Vector2(-2,-4)]),c)
		"inventory", "materials":
			draw_rect(Rect2(p+Vector2(-12,-9),Vector2(24,24)),c,false,2)
			draw_arc(p+Vector2(0,-9),6,PI,TAU,12,c,2)
			draw_line(p+Vector2(-8,4),p+Vector2(8,4),c,2)
			if symbol=="materials": draw_circle(p,4,c)
		"companions":
			draw_circle(p+Vector2(0,6),8,c)
			for q in [Vector2(-11,-5),Vector2(-4,-12),Vector2(5,-12),Vector2(12,-4)]: draw_circle(p+q,4,c)
		"collection":
			for x in [-13,1]: draw_rect(Rect2(p+Vector2(x,-10),Vector2(12,25)),c,false,2)
			draw_line(p+Vector2(0,-7),p+Vector2(0,17),c,2)
		"druid":
			draw_circle(p+Vector2(0,-7),6,c)
			draw_arc(p+Vector2(0,13),12,PI,TAU,12,c,3)
		"equipment":
			draw_polyline(PackedVector2Array([p+Vector2(-12,-12),p+Vector2(0,-6),p+Vector2(12,-12),p+Vector2(9,9),p+Vector2(0,16),p+Vector2(-9,9),p+Vector2(-12,-12)]),c,2)
		"skills":
			draw_line(p+Vector2(-9,14),p+Vector2(7,-12),c,3)
			draw_circle(p+Vector2(7,-12),5,c,false,2)
		"shop":
			draw_circle(p,14,c,false,2)
			draw_line(p+Vector2(0,-9),p+Vector2(0,9),c,3)
			draw_arc(p,6,-PI/2,PI/2,8,c,2)
		"controls":
			draw_rect(Rect2(p+Vector2(-15,-8),Vector2(30,20)),c,false,2)
			draw_line(p+Vector2(-11,2),p+Vector2(-3,2),c,2)
			draw_line(p+Vector2(-7,-2),p+Vector2(-7,6),c,2)
			draw_circle(p+Vector2(8,2),3,c)
		"home":
			draw_polyline(PackedVector2Array([p+Vector2(-15,1),p+Vector2(0,-13),p+Vector2(15,1)]),c,2)
			draw_rect(Rect2(p+Vector2(-10,1),Vector2(20,15)),c,false,2)
