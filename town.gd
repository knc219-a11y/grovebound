extends RefCounted
# Pixel coordinates stay on a 4px grid. Doors are 44x64 beside a 72px druid.
const SIZE=Vector2(1800,1100)
const SPAWN=Vector2(850,700)
const BUILDINGS=[Rect2(420,350,232,110),Rect2(1040,290,200,100),Rect2(1120,760,184,96)]
const POINTS=[Vector2(540,510),Vector2(850,640),Vector2(1580,570)]
const LABELS=["동료 쉼터","야영 자리","초록물 사냥길"]
static func move(p:Vector2,delta:Vector2)->Vector2:
	var result=p
	for axis in 2:
		var next=result
		next[axis]+=delta[axis]
		next=next.clamp(Vector2(80,190),SIZE-Vector2(80,90))
		var blocked=false
		for box in BUILDINGS:
			if box.grow(13).has_point(next): blocked=true
		if not blocked: result=next
	return result
static func nearest(p:Vector2)->int:
	for i in POINTS.size():
		if p.distance_to(POINTS[i])<110: return i
	return -1
static func rect(g,p,s,c): g.draw_rect(Rect2(p,s),Color(c))
static func ground(g):
	rect(g,Vector2.ZERO,SIZE,"435747")
	var r=RandomNumberGenerator.new()
	r.seed=382
	for i in 650:
		var p=Vector2(r.randi_range(20,445)*4,r.randi_range(40,265)*4)
		rect(g,p,Vector2(8,4),"4a604a" if i%2 else "3c5041")
	# Quiet earth lanes form a loop, with broad passing spaces.
	rect(g,Vector2(240,540),Vector2(1410,108),"897b59")
	rect(g,Vector2(740,430),Vector2(200,460),"897b59")
	rect(g,Vector2(460,470),Vector2(168,110),"897b59")
	for i in 95:
		var p=Vector2(r.randi_range(65,400)*4,r.randi_range(138,157)*4)
		rect(g,p,Vector2(12,4),"978765")
	for x in range(100,1700,64):
		rect(g,Vector2(x,180),Vector2(8,36),"756548")
		rect(g,Vector2(x,194),Vector2(64,8),"655b43")
	for p in [Vector2(170,350),Vector2(300,850),Vector2(1440,310),Vector2(1520,890),Vector2(160,950)]:
		g.draw_texture_rect(g.textures.tree,Rect2(p-Vector2(40,95),Vector2(80,104)),false)
	for i in 36:
		var p=Vector2(120+r.randi_range(0,390)*4,240+r.randi_range(0,175)*4)
		if p.y>500 and p.y<700: continue
		for j in 3:
			rect(g,p+Vector2(j*8,-j%2*4),Vector2(12,8),"657956")
	# Central camp: low stone ring, logs and a small canopy-free gathering place.
	for i in 8:
		var a=i*TAU/8
		rect(g,Vector2(850,640)+Vector2(cos(a)*27,sin(a)*14).snapped(Vector2(4,4)),Vector2(12,8),"a39c80")
	rect(g,Vector2(840,628),Vector2(24,12),"bb9558")
	rect(g,Vector2(760,672),Vector2(48,12),"675641")
	rect(g,Vector2(904,672),Vector2(48,12),"675641")
	for p in [Vector2(1520,530),Vector2(1630,530)]:
		rect(g,p,Vector2(12,68),"65543e")
		rect(g,p+Vector2(-8,0),Vector2(28,12),"b8ac7a")
static func building(g,i):
	var b=BUILDINGS[i]
	var p=b.position
	var w=b.size.x
	rect(g,p+Vector2(-12,16),b.size+Vector2(24,8),"344338")
	rect(g,p-Vector2(0,48),b.size+Vector2(0,48),"aa9971")
	rect(g,p+Vector2(0,72),Vector2(w,38),"817654")
	for x in range(12,int(w)-12,32):
		rect(g,p+Vector2(x,-28),Vector2(8,134),"655d43")
	var roof=PackedVector2Array([p+Vector2(-20,-40),p+Vector2(w/2,-112),p+Vector2(w+20,-40),p+Vector2(w+12,0),p+Vector2(-12,0)])
	g.draw_colored_polygon(roof,Color("384c48"))
	for row in range(5):
		var y=-68+row*16
		var inset=maxf(0,(-y-40)*1.5)
		for x in range(int(inset),int(w-inset),24):
			rect(g,p+Vector2(x,y),Vector2(20,4),"455b51")
	for y in range(-40,0,12): rect(g,p+Vector2(-8,y),Vector2(w+16,4),"52645a")
	rect(g,p+Vector2(w/2-26,46),Vector2(52,64),"504937")
	for y in range(8,96,16): rect(g,p+Vector2(8,y),Vector2(w-16,4),"998861")
	rect(g,p+Vector2(w/2-20,50),Vector2(40,60),"353f35")
	rect(g,p+Vector2(24,26),Vector2(32,28),"4e655a")
	rect(g,p+Vector2(28,30),Vector2(24,16),"a5ac80")
	rect(g,p+Vector2(w/2-34,110),Vector2(68,8),"b0a17b")
static func draw(g):
	g.draw_set_transform(-g.cam.round())
	ground(g)
	var order=[0,1,2,-1]
	order.sort_custom(func(a,b): return (g.player.pos.y if a==-1 else BUILDINGS[a].end.y)<(g.player.pos.y if b==-1 else BUILDINGS[b].end.y))
	for i in order:
		if i==-1:
			g.draw_set_transform(Vector2.ZERO)
			g.druid_rig.draw(g,g.player.pos-g.cam,72,g.player.face,Color.WHITE,g.player,g.textures.druid)
			g.draw_set_transform(-g.cam.round())
		else: building(g,i)
	g.draw_set_transform(Vector2.ZERO)
	for i in POINTS.size():
		g.text_at(LABELS[i],POINTS[i]-g.cam+Vector2(-50,32),16,Color("e2d4a7"))
	g.GroveUI.draw_stick(g,g.stick)
