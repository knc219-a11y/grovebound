extends RefCounted
# Cosmetic only: no damage, timers, targeting or saves are changed here.
const MAX_EVENTS=80
const MAX_NUMBERS=32
var events=[]
var numbers=[]
func clear():
	events.clear()
	numbers.clear()
func emit(kind,source,target,amount=0.0,options={}):
	var duration=0.28
	if kind in ["heal","buff","guard","revive"]: duration=0.75
	elif kind=="stomp": duration=0.45
	if events.size()>=MAX_EVENTS: events.pop_front()
	events.append({"kind":kind,"a":source,"b":target,"age":0.0,"duration":duration,"radius":options.get("radius",130.0)})
	if amount<=0: return
	var category="heal" if kind=="heal" else ("hurt" if kind in ["hurt","block"] else "damage")
	var id=options.get("target_id",str(target.round()))
	for n in numbers:
		if n.category==category and n.target_id==id and n.age<0.12 and n.blocked==(kind=="block"):
			n.amount+=amount
			return
	if numbers.size()>=MAX_NUMBERS: numbers.pop_front()
	# Offset simultaneous opposite types so a heal cannot cover damage text.
	var offset=14 if category=="heal" else (-12 if category=="hurt" else 0)
	var lane=0
	for old in numbers:
		if old.target_id==id and old.age<0.45: lane+=1
	lane=mini(lane,2)
	var height_offset=maxf(0,options.get("height",44)-44)
	numbers.append({"category":category,"target_id":id,"amount":amount,"pos":target+Vector2(offset+lane*4,-height_offset-lane*16),"age":0.0,"duration":0.8,"blocked":kind=="block"})
func advance(dt):
	for collection in [events,numbers]:
		for i in range(collection.size()-1,-1,-1):
			collection[i].age+=maxf(0,dt)
			if collection[i].age>=collection[i].duration: collection.remove_at(i)
func color_for(kind):
	match kind:
		"heal","revive": return Color("b5d99a")
		"guard","block": return Color("a0c9d2")
		"fox","buff": return Color("e2b46c")
		"hurt": return Color("df907b")
		_: return Color("ded1ae")
func shield(canvas,p,r,col):
	var points=PackedVector2Array()
	for i in range(7): points.append(p+Vector2(cos(-PI/2+i*TAU/6),sin(-PI/2+i*TAU/6))*r)
	canvas.draw_polyline(points,col,2,false)
	canvas.draw_line(p+Vector2(-r*0.35,0),p+Vector2(0,r*0.3),col,2,false)
	canvas.draw_line(p+Vector2(0,r*0.3),p+Vector2(r*0.4,-r*0.3),col,2,false)
func draw(canvas,cam,font):
	for event in events:
		var t=event.age/event.duration
		var p=(event.b-cam-Vector2(0,22)).round()
		var a=(event.a-cam-Vector2(0,28)).round()
		var c=color_for(event.kind)
		c.a=1.0-smoothstep(0.45,1.0,t)
		match event.kind:
			"melee","hurt":
				var direction=(p-a).normalized()
				if direction.length()<0.1: direction=Vector2.RIGHT
				var side=direction.orthogonal()
				for i in range(3):
					var mid=p+side*(i-1)*5
					canvas.draw_line((mid-side*9-direction*(2+i)+direction*t*4).round(),(mid+side*5+direction*(4+i)+direction*t*4).round(),c,2,false)
				for i in range(4):
					var q=p+Vector2.RIGHT.rotated(i*TAU/4+0.3)*(6+t*16)
					canvas.draw_rect(Rect2(q.round(),Vector2(2,2)),c)
			"fox","support":
				# Immediate ray and contact burst match the existing instant hit rule.
				if t<0.3:
					for i in range(5):
						var q=a.lerp(p,float(i+1)/6)
						canvas.draw_rect(Rect2(q.round(),Vector2(3,3)),c)
				for i in range(6):
					var dir=Vector2.RIGHT.rotated(i*TAU/6)
					canvas.draw_line((p+dir*(3+t*7)).round(),(p+dir*(8+t*14)).round(),c,2,false)
			"heal","revive":
				for i in range(5):
					var q=p+Vector2((i-2)*6+sin(t*TAU+i)*3,12-t*32-float(i%2)*9)
					canvas.draw_rect(Rect2(q.round(),Vector2(3,5)),c)
					if i%2==0: canvas.draw_rect(Rect2((q+Vector2(-2,1)).round(),Vector2(7,2)),c)
				if event.kind=="revive": canvas.draw_arc(event.b-cam,18+t*15,0,TAU,24,c,2,false)
			"guard","block": shield(canvas,p,16+t*5,c)
			"buff":
				for i in range(3):
					var q=p+Vector2(0,10-i*9-t*18)
					canvas.draw_polyline(PackedVector2Array([q+Vector2(-7,4),q,q+Vector2(7,4)]),c,2,false)
			"stomp": canvas.draw_arc(event.b-cam,event.radius*(0.7+0.3*t),0,TAU,48,c,3,false)
	for n in numbers:
		var col=Color("b5d99a") if n.category=="heal" else (Color("e49a88") if n.category=="hurt" else Color("eee1c2"))
		if n.blocked: col=Color("a0c9d2")
		col.a=1-smoothstep(0.5,0.8,n.age)
		var label=("+" if n.category=="heal" else "−")+str(maxi(1,roundi(n.amount)))
		if n.blocked: label="방어 "+label
		var p=(n.pos-cam+Vector2(-12,-62-n.age*28)).round()
		canvas.draw_string(font,p+Vector2(1,1),label,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color(0.05,0.06,0.05,col.a))
		canvas.draw_string(font,p,label,HORIZONTAL_ALIGNMENT_LEFT,-1,19,col)
func draw_channel(canvas,source,target,progress,cam):
	var a=source-cam-Vector2(0,34)
	var b=target-cam-Vector2(0,16)
	var ratio=clampf(progress/3.0,0,1)
	for i in range(9):
		var t=float(i)/8
		var p=a.lerp(b,t)+Vector2(0,-sin(t*PI)*13)
		canvas.draw_rect(Rect2(p.round(),Vector2(2,2)),Color("d0e4b9") if t<=ratio else Color("526649"))
	canvas.draw_arc(target-cam,23,-PI/2,-PI/2+maxf(0.001,ratio*TAU),32,Color("bedb9e"),2,false)
func draw_tell(canvas,enemy,cam):
	if enemy.hp<=0 or enemy.wind<=0: return
	var duration=enemy.get("wind_total",1.25 if enemy.attack_kind=="charge" else (1.15 if enemy.attack_kind=="stomp" else 0.65))
	var ratio=clampf(1.0-enemy.wind/maxf(0.001,duration),0,1)
	var fill=Color(0.72,0.22,0.14,0.16+ratio*0.12)
	var edge=Color("f0c08a") if enemy.wind>0.2 else Color("f3e4bc")
	var p=enemy.aim-cam
	if enemy.attack_kind=="charge":
		var a=enemy.origin-cam
		var direction=(p-a).normalized()
		var side=direction.orthogonal()*48
		canvas.draw_colored_polygon(PackedVector2Array([a+side,p+side,p-side,a-side]),fill)
		canvas.draw_circle(a,48,fill)
		canvas.draw_circle(p,48,fill)
		canvas.draw_line(a+side,p+side,edge,2,false)
		canvas.draw_line(a-side,p-side,edge,2,false)
		canvas.draw_arc(p,48,direction.angle()-PI/2,direction.angle()+PI/2,24,edge,2,false)
		for t in [0.25,0.5,0.75]:
			var q=a.lerp(p,t)
			canvas.draw_polyline(PackedVector2Array([q-direction*9+side*0.18,q+direction*3,q-direction*9-side*0.18]),edge,2,false)
		canvas.draw_line(a,a.lerp(p,ratio),edge,3,false)
	else:
		var radius=130.0 if enemy.attack_kind=="stomp" else 56.0
		canvas.draw_circle(p,radius,fill)
		canvas.draw_arc(p,radius,0,TAU,48,Color("b88a67"),2,false)
		canvas.draw_arc(p,radius,-PI/2,-PI/2+maxf(0.001,ratio*TAU),48,edge,3,false)
