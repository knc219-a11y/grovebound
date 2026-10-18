extends StyleBox
# Resolution-independent geometry with integer edges and clipped corners.
var bg_color=Color("262e2b")
var border_color=Color("8c7855")
var border_width=1
var chamfer=8.0
var shadow_size=3.0
var bevel=true
func set_border_width_all(value): border_width=value
func polygon(rect,inset=0.0):
	var r=rect.grow(-inset)
	var c=minf(chamfer,minf(r.size.x,r.size.y)/3)
	var a=r.position.round()
	var b=r.end.round()
	if c<=0: return PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
	return PackedVector2Array([a+Vector2(c,0),Vector2(b.x-c,a.y),Vector2(b.x,a.y+c),Vector2(b.x,b.y-c),b-Vector2(c,0),Vector2(a.x+c,b.y),Vector2(a.x,b.y-c),a+Vector2(0,c)])
func _draw(item,rect):
	if shadow_size>0:
		RenderingServer.canvas_item_add_polygon(item,polygon(Rect2(rect.position+Vector2(0,shadow_size),rect.size)),PackedColorArray([Color(0.03,0.04,0.03,0.60)]))
	var points=polygon(rect)
	RenderingServer.canvas_item_add_polygon(item,points,PackedColorArray([bg_color]))
	if bevel and rect.size.y>20:
		var top=rect.position.round()
		var right=rect.end.round()
		var light=bg_color.lightened(0.045)
		light.a=bg_color.a
		RenderingServer.canvas_item_add_polygon(item,PackedVector2Array([points[0],points[1],points[2],Vector2(right.x,top.y+minf(30,rect.size.y*0.35)),Vector2(top.x,top.y+minf(30,rect.size.y*0.35)),points[7]]),PackedColorArray([light]))
	if border_width>0:
		var outline=polygon(rect,0.5)
		outline.append(outline[0])
		RenderingServer.canvas_item_add_polyline(item,outline,PackedColorArray([border_color]),border_width,false)
		if bevel:
			RenderingServer.canvas_item_add_line(item,points[0]+Vector2(1,2),points[1]+Vector2(-1,2),Color(border_color,0.28),1,false)
