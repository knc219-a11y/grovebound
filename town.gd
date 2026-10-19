extends RefCounted
# Separate generated terrain and alpha cottages match the approved meadow.
# Gameplay footprints, 72px druid and camera remain unchanged.
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
static var ground_texture:Texture2D
static var cottages:Array=[]
static var props:Array=[]
static func load_art():
	if ground_texture!=null: return
	ground_texture=load("res://assets/town/leafshade-ground-v1.webp")
	for i in 3:
		cottages.append(load("res://assets/town/cottage-"+str(i)+"-v1.webp"))
		props.append(load("res://assets/town/prop-"+str(i)+"-v1.webp"))
static func ground(g):
	load_art()
	g.draw_texture_rect(ground_texture,Rect2(Vector2.ZERO,SIZE),false)
	# Small props sit below the existing interaction labels; no character zoom.
	g.draw_texture(props[0],POINTS[1]-Vector2(40,22))
	g.draw_texture(props[2],POINTS[1]+Vector2(-106,32))
	g.draw_texture(props[2],POINTS[1]+Vector2(64,32))
	g.draw_texture(props[1],POINTS[2]+Vector2(0,-62))
static func building_rect(i):
	load_art()
	var b=BUILDINGS[i]
	var texture=cottages[i]
	var width=b.size.x+40
	var height=width*texture.get_height()/float(texture.get_width())
	return Rect2(Vector2(b.get_center().x-width/2,b.end.y-height+8),Vector2(width,height))
static func building(g,i):
	g.draw_texture_rect(cottages[i],building_rect(i),false)
static func draw(g):
	g.draw_set_transform(-g.cam.round())
	ground(g)
	var order=[0,1,2,-1]
	order.sort_custom(func(a,b): return (g.player.pos.y if a==-1 else BUILDINGS[a].end.y)<(g.player.pos.y if b==-1 else BUILDINGS[b].end.y))
	for i in order:
		if i==-1:
			g.draw_set_transform(Vector2.ZERO)
			g.weapon_visual.draw(g,g.player.pos-g.cam,72,g.player.face,Color.WHITE,g.player)
			g.druid_rig.draw(g,g.player.pos-g.cam,72,g.player.face,Color.WHITE,g.player,g.druid_body)
			g.draw_set_transform(-g.cam.round())
		else: building(g,i)
	g.draw_set_transform(Vector2.ZERO)
	for i in POINTS.size():
		g.text_at(LABELS[i],POINTS[i]-g.cam+Vector2(-50,32),16,Color("e2d4a7"))
	if not g.tutorial_done or (not g.unlocked and not g.preparation_seen):
		var target=POINTS[2] if not g.tutorial_done else POINTS[0]
		var p=(target-g.cam+Vector2(0,-35)).clamp(Vector2(40,145),Vector2(1320,560))
		var bob=roundf(sin(g.clock*3)*4)
		g.draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-12+bob),p+Vector2(9,-12+bob),p+Vector2(0,bob)]),Color("e2cf8b"))
	g.GroveUI.draw_stick(g,g.stick)
