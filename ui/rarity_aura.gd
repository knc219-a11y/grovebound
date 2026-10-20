extends RefCounted
const Loot=preload("res://companion_loot.gd")
static func draw(canvas,position,height,record,time):
	if Loot.Special.ready(record):
		preload("res://ui/special_visual.gd").aura(canvas,position,height,record,time)
		return
	var grade=Loot.grade(record)
	if grade=="common": return
	var c=Loot.color(record)
	var count=2 if grade=="rare" else 3
	var radius=18 if grade=="rare" else 23
	canvas.draw_set_transform(position.round(),0,Vector2(1,0.34))
	canvas.draw_arc(Vector2.ZERO,radius,0,TAU,24,Color(c,0.22 if grade=="rare" else 0.38),1,false)
	if grade=="epic": canvas.draw_arc(Vector2.ZERO,radius+4,0,TAU,24,Color(c,0.13),1,false)
	canvas.draw_set_transform(Vector2.ZERO)
	for i in count:
		var angle=time*1.3+i*TAU/count+record.id*0.7
		var p=position+Vector2(cos(angle)*radius,sin(angle)*6-height*0.45-4)
		canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-2,0),p+Vector2(0,-3),p+Vector2(2,0),p+Vector2(0,2)]),Color(c,0.65))
