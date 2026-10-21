extends RefCounted
# Presentation-only events. A radius is supplied only by a real area effect.
const Special=preload("res://special_companions.gd")
const MAX_EVENTS=40
var events=[]
func clear(): events.clear()
func emit(record,source,target,is_skill=false,radius=0.0):
	if not Special.ready(record): return
	if events.size()>=MAX_EVENTS: events.pop_front()
	events.append({"element":Special.element(record),"a":source,"b":target,"age":0.0,"duration":0.65 if is_skill else 0.26,"skill":is_skill,"radius":maxf(0.0,radius)})
func advance(dt):
	for i in range(events.size()-1,-1,-1):
		events[i].age+=maxf(0.0,dt)
		if events[i].age>=events[i].duration: events.remove_at(i)
func draw(g,cam):
	for event in events: draw_event(g,event,cam)
static func draw_event(g,event,cam):
	var t=clampf(event.age/event.duration,0.0,1.0)
	var c=Color(Special.ELEMENTS[event.element].color)
	c.a=1.0-t
	var p=(event.b-cam-Vector2(0,20)).round()
	var burst=1.0-pow(1.0-t,3)
	var scale_value=1.5 if event.skill else 1.0
	# Small impact marks: all particles remain cosmetic and cause no extra hits.
	match event.element:
		"fire":
			for i in 6:
				var direction=Vector2.RIGHT.rotated(i*TAU/6-PI/2)
				var q=(p+direction*(5+burst*16)*scale_value-Vector2(0,t*12)).round()
				g.draw_colored_polygon(PackedVector2Array([q+Vector2(-2,2),q+Vector2(0,-6*(1-t)),q+Vector2(3,2)]),c)
		"water":
			for i in 2:
				g.draw_set_transform(p+Vector2(0,i*5),0,Vector2(1,0.55))
				g.draw_arc(Vector2.ZERO,(5+burst*(16+i*5))*scale_value,0,TAU,20,c,2,false)
				g.draw_set_transform(Vector2.ZERO)
		"earth":
			for i in 5:
				var q=(p+Vector2((i-2)*(5+burst*4),-sin(i*1.7)*6-t*10)*scale_value).round()
				g.draw_colored_polygon(PackedVector2Array([q+Vector2(-3,3),q+Vector2(-2,-4),q+Vector2(3,-2),q+Vector2(4,3)]),c)
		"wind":
			for i in 3:
				g.draw_arc(p+Vector2(0,(i-1)*5),(8+burst*15)*scale_value,-PI*0.8+t*2+i*0.4,PI*0.1+t*2+i*0.4,14,c,2,false)
	if event.radius>0 and event.skill:
		# Actual world-space effect boundary; never inflate the effective radius.
		var edge=Color(c,c.a*0.45)
		g.draw_arc((event.b-cam).round(),event.radius,0,TAU,64,edge,1,false)
