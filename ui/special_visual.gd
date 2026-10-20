extends RefCounted
const Special=preload("res://special_companions.gd")
static func color(d): return Color(Special.ELEMENTS.get(Special.element(d),{"color":"efbd69"}).color)
static func aura(g,p,height,d,time):
	var c=color(d)
	g.draw_set_transform(p.round(),0,Vector2(1,0.34))
	g.draw_arc(Vector2.ZERO,23,0,TAU,24,Color(c,0.45),2,false)
	g.draw_arc(Vector2.ZERO,27,0,TAU,24,Color(c,0.15),1,false)
	g.draw_set_transform(Vector2.ZERO)
	for i in 3:
		var a=time*0.8+i*TAU/3
		var point=(p+Vector2(cos(a)*20,sin(a)*6-4)).round()
		g.draw_rect(Rect2(point-Vector2(1,1),Vector2(3,3)),Color(c,0.7))
static func mark(g,p,height,d):
	var c=color(d)
	# Small species-specific rune placements; preserve sprite scale and silhouette.
	var offset={"boar":Vector2(0,-0.6),"turtle":Vector2(0,-0.4),"marten":Vector2(-0.12,-0.55),"wolf":Vector2(0.12,-0.65),"fox":Vector2(-0.12,-0.5),"deer":Vector2(0.12,-0.8),"bat":Vector2(0.18,-0.5)}.get(d.kind,Vector2(0,-0.5))
	var point=(p+offset*height).round()
	g.draw_line(point-Vector2(2,0),point+Vector2(2,0),c,1,false)
	g.draw_line(point-Vector2(0,2),point+Vector2(0,2),c,1,false)
