extends RefCounted
# Shared slate / bronze UI. Geometry stays crisp under nearest filtering.
const INK=Color("171d1c")
const SLATE=Color("262e2b")
const BRONZE=Color("8c7855")
const PAPER=Color("e0d5bb")
const MUTED=Color("a4aa96")
const GREEN=Color("9eb780")
const Carved=preload("res://ui/carved_style.gd")
static func frame(color=SLATE,border=BRONZE,width=1):
	var s=Carved.new()
	s.bg_color=color
	s.border_color=border
	s.set_border_width_all(width)
	s.content_margin_left=12
	s.content_margin_right=12
	s.content_margin_top=8
	s.content_margin_bottom=8
	return s
static func bar(color,border,width=0):
	var s=StyleBoxFlat.new()
	s.bg_color=color
	s.border_color=border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.anti_aliasing=false
	s.content_margin_left=0
	s.content_margin_right=0
	s.content_margin_top=0
	s.content_margin_bottom=0
	return s
static func quiet(button,accent=BRONZE):
	for state in ["normal","hover","pressed","disabled","focus"]:
		var s=frame(Color(0,0,0,0),accent,0)
		s.shadow_size=0
		s.bevel=false
		if state in ["hover","pressed","focus"]:
			s.bg_color=Color(accent,0.10 if state!="pressed" else 0.19)
		button.add_theme_stylebox_override(state,s)
static func medallion(canvas,center,radius,color):
	canvas.draw_circle(center,radius,INK)
	canvas.draw_arc(center,radius,0,TAU,16,Color(color,0.65),1,false)
	canvas.draw_arc(center,radius-3,PI*0.95,PI*1.9,12,Color(color,0.24),1,false)
static func leaf(canvas,p,radius,color):
	canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-radius,0),p+Vector2(0,-radius*1.4),p+Vector2(radius,0),p+Vector2(0,radius*0.8)]),color)
	canvas.draw_line(p+Vector2(0,-radius),p+Vector2(0,radius*0.5),INK,1,false)
static func theme(font):
	var t=Theme.new()
	t.default_font=font
	for type in ["Button","Label","OptionButton","PopupMenu","CheckBox","CheckButton","LineEdit","TooltipLabel","SpinBox"]:
		t.set_font("font",type,font)
	t.default_font_size=18
	for state in ["normal","hover","pressed","disabled","focus"]:
		var bg=SLATE
		var border=BRONZE
		if state=="hover": bg=Color("354038"); border=Color("c5ab77")
		if state=="pressed": bg=Color("17231e"); border=GREEN
		if state=="disabled": bg=Color("202623"); border=Color("51584b")
		if state=="focus": border=Color("d9c28f")
		t.set_stylebox(state,"Button",frame(bg,border))
		t.set_stylebox(state,"OptionButton",frame(bg,border))
	t.set_color("font_color","Button",PAPER)
	t.set_color("font_hover_color","Button",Color("f3e7c9"))
	t.set_color("font_pressed_color","Button",GREEN)
	t.set_color("font_disabled_color","Button",Color("858c7b"))
	t.set_stylebox("panel","Panel",frame())
	t.set_stylebox("panel","PopupMenu",frame(INK,BRONZE))
	t.set_stylebox("hover","PopupMenu",bar(Color("3c493c"),GREEN,0))
	t.set_color("font_color","OptionButton",PAPER)
	t.set_color("font_color","PopupMenu",PAPER)
	t.set_color("font_hover_color","PopupMenu",Color("f1e4c5"))
	t.set_constant("h_separation","OptionButton",12)
	t.set_stylebox("background","ProgressBar",bar(INK,Color("4e5647"),1))
	t.set_stylebox("fill","ProgressBar",bar(GREEN,GREEN,0))
	t.set_stylebox("scroll","VScrollBar",bar(INK,INK,0))
	var grabber=bar(Color("6b705b"),Color("6b705b"),0)
	grabber.content_margin_left=6
	grabber.content_margin_right=6
	t.set_stylebox("grabber","VScrollBar",grabber)
	t.set_stylebox("grabber_highlight","VScrollBar",grabber.duplicate())
	t.set_constant("separation","VBoxContainer",8)
	t.set_constant("separation","HBoxContainer",8)
	return t
static func emphasize(button,kind="primary"):
	var bg=Color("354331") if kind=="primary" else Color("362b27")
	var border=Color("b8a16d") if kind=="primary" else Color("916e58")
	button.add_theme_stylebox_override("normal",frame(bg,border))
static func draw_stick(canvas,stick):
	var center=Vector2(140,680)
	canvas.draw_circle(center,81,Color(0.08,0.11,0.10,0.5))
	canvas.draw_arc(center,81,0,TAU,8,Color(0.55,0.47,0.33,0.7),2,false)
	canvas.draw_arc(center,65,0,TAU,8,Color(0.5,0.55,0.46,0.3),1,false)
	var p=center+stick.limit_length()*55
	var points=PackedVector2Array()
	for i in range(8): points.append((p+Vector2.RIGHT.rotated(PI/8+i*TAU/8)*29).round())
	canvas.draw_colored_polygon(points,Color(0.48,0.55,0.46,0.8))
	points.append(points[0])
	canvas.draw_polyline(points,Color("b8a784"),2,false)
