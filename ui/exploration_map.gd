extends Control
# Decorative geography shares the project's quiet palette. Buttons own input.
var theme_id=0
var points=[]
var cleared=[]
var selected=0
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color("222c25"))
	# Low-contrast contour islands and a river keep the route readable.
	for i in 7:
		var center=Vector2(65+i*82,100+(i%3)*72)
		var polygon=PackedVector2Array()
		for j in 8: polygon.append((center+Vector2(cos(j*TAU/8)*82,sin(j*TAU/8)*46)).snapped(Vector2(4,4)))
		draw_colored_polygon(polygon,Color("29372a"))
	var river=PackedVector2Array([Vector2(15,300),Vector2(110,270),Vector2(210,310),Vector2(320,240),Vector2(430,260),Vector2(550,185),Vector2(660,210)])
	draw_polyline(river,Color("36514a"),12,false)
	draw_polyline(river,Color("52695b"),2,false)
	for i in points.size()-1:
		var delta=points[i+1]-points[i]
		var steps=maxi(1,int(delta.length()/12))
		for j in steps:
			var p=points[i].lerp(points[i+1],float(j)/steps)
			draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(5,3)),Color("b8a779") if i in cleared else Color("666b52"))
	for i in points.size():
		var p=points[i]
		var color=Color("c6d69c") if i in cleared else Color("999b79")
		draw_arc(p,35 if theme_id==0 else 27,0,TAU,16,color,2,false)
		if i==selected: draw_arc(p,41 if theme_id==0 else 33,0,TAU,16,Color("d7bd83"),2,false)
		if theme_id>0 and i in [3,7]:
			# Small crown silhouette distinguishes middle and theme bosses.
			var crown=p+Vector2(0,-42)
			draw_colored_polygon(PackedVector2Array([crown+Vector2(-10,6),crown+Vector2(-12,-4),crown+Vector2(-4,0),crown+Vector2(0,-9),crown+Vector2(4,0),crown+Vector2(12,-4),crown+Vector2(10,6)]),Color("bf9971") if i==3 else Color("d9bd7b"))
	# Pixel compass, not an interactive control.
	draw_line(Vector2(610,42),Vector2(610,72),Color("b7ad8a"),2,false)
	draw_line(Vector2(598,57),Vector2(622,57),Color("b7ad8a"),2,false)
	draw_colored_polygon(PackedVector2Array([Vector2(610,34),Vector2(605,46),Vector2(615,46)]),Color("d2c493"))
