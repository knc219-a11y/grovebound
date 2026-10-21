extends RefCounted
const Special=preload("res://special_companions.gd")
static func color(d): return Color(Special.ELEMENTS.get(Special.element(d),{"color":"efbd69"}).color)
static func aura(g,p,height,d,time):
	var c=color(d)
	var element=Special.element(d)
	g.draw_set_transform(p.round(),0,Vector2(1,0.34))
	g.draw_arc(Vector2.ZERO,23,0,TAU,24,Color(c,0.50),2,false)
	if int(d.star)>=5: g.draw_arc(Vector2.ZERO,19,0,TAU,16,Color(c,0.60),1,false)
	g.draw_set_transform(Vector2.ZERO)
	# These small motifs identify the element, never an attack/hit radius.
	for i in 3:
		var a=time*0.8+i*TAU/3
		var point=(p+Vector2(cos(a)*22,sin(a)*6-5)).round()
		match element:
			"fire":
				var rise=fposmod(time*12+i*7,15)
				var spark=point-Vector2(0,rise)
				g.draw_colored_polygon(PackedVector2Array([spark+Vector2(-2,2),spark+Vector2(0,-5),spark+Vector2(3,2)]),Color(c,0.85-rise/28))
			"water":
				g.draw_set_transform(point,0,Vector2(1,0.4))
				g.draw_arc(Vector2.ZERO,3+fposmod(time*3+i,4),0,TAU,12,Color(c,0.65),1,false)
				g.draw_set_transform(Vector2.ZERO)
			"earth":
				g.draw_colored_polygon(PackedVector2Array([point+Vector2(-3,1),point+Vector2(-1,-5),point+Vector2(3,-3),point+Vector2(4,2)]),Color(c,0.8))
			"wind":
				g.draw_set_transform(point,0,Vector2(1,0.5))
				g.draw_arc(Vector2.ZERO,7,a,a+PI*0.85,10,Color(c,0.8),2,false)
				g.draw_set_transform(Vector2.ZERO)
static func mark(g,p,height,d):
	var c=color(d)
	# Small species-specific rune placements; preserve sprite scale and silhouette.
	var offset={"boar":Vector2(0,-0.6),"turtle":Vector2(0,-0.4),"marten":Vector2(-0.12,-0.55),"wolf":Vector2(0.12,-0.65),"fox":Vector2(-0.12,-0.5),"deer":Vector2(0.12,-0.8),"bat":Vector2(0.18,-0.5)}.get(d.kind,Vector2(0,-0.5))
	var point=(p+offset*height).round()
	g.draw_line(point-Vector2(2,0),point+Vector2(2,0),c,1,false)
	g.draw_line(point-Vector2(0,2),point+Vector2(0,2),c,1,false)
	if int(d.star)>=5:
		g.draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color(c,0.8),false,1,false)
