extends RefCounted
# Production stage objectives; does not read or write saves.
var route={}
var data={}
var points=[]
var side=Vector2.ZERO
var rest=Vector2.ZERO
var visited={}
var campaign_id=1
var rest_name="물길 쉼터"
var milestone_time=0.0
var milestone=""
var sign:Texture2D
var fire:Texture2D
func configure_route(c,p):
	route=c.duplicate(true); data=p.duplicate(true); points=data.points
	side=points[0]+Vector2(60,-235 if points[0].y>700 else 235)
	rest=points[mini(1,points.size()-1)]+Vector2(-180,-200 if points[1].y>750 else 210)
func reset():
	visited.clear(); milestone=""; milestone_time=0.0
func engageable(e):
	if e.get("stage_entry",false) and not visited.has("boss_intro"): return false
	return int(e.get("pack",-1))!=8 or visited.has("side")
func cleared_pack(enemies,pack):
	var found=false
	for e in enemies:
		if int(e.get("pack",-1))==pack:
			found=true
			if e.hp>0: return false
	return found
func core_progress(enemies):
	var cleared=0
	for pack in points.size():
		if cleared_pack(enemies,pack): cleared+=1
	return {"cleared":cleared,"total":points.size()}
func progress_text(enemies):
	var p=core_progress(enemies)
	return "길목 %d/%d" % [p.cleared,p.total]
func ready_to_clear(enemies):
	return core_progress(enemies).cleared==points.size()
func near_rest(p): return p.distance_to(rest)<100
func near_exit(p): return p.distance_to(data.exit)<105
func next_stop(enemies):
	for pack in points.size():
		if not cleared_pack(enemies,pack): return {"pos":points[pack],"name":data.boss if data.has("boss") and pack==points.size()-1 else "%d번째 길목" % (pack+1),"pack":pack}
	return {"pos":data.exit,"name":"물길 표식 · 탐험 완료 [F]","pack":-1}
func objective(enemies,p):
	if ready_to_clear(enemies): return "물길 표식으로 이동 · [F] 길 잇기"
	return "다음 · "+next_stop(enemies).name
func area(_p): return "1-%d · %s" % [int(route.stage),data.name]
func begin_boss_intro(g):
	if visited.has("boss_intro"): return false
	for pack in points.size()-1:
		if not cleared_pack(g.enemies,pack): return false
	visited.boss_intro=true
	for e in g.enemies:
		if e.boss:
			e.active=true; e.intro=1.35; e.cd=maxf(e.cd,0.8); e.wind=0.0; e.dash=0.0
			g.notify(data.boss+" · "+("발구르기의 원 밖으로 이동하세요." if data.get("midboss",false) else "발구르기와 직선 돌진의 예고를 살피세요."))
	return true
func update(g,dt=0.0):
	milestone_time=maxf(0,milestone_time-dt)
	if g.player.pos.distance_to(side)<165: visited.side=true
	if near_rest(g.player.pos) and not visited.has("rest"):
		visited.rest=true; g.notify(rest_name+" · 비전투 중 편성을 점검하세요.")
	for pack in points.size():
		if cleared_pack(g.enemies,pack) and not visited.has(pack):
			visited[pack]=true; milestone="길목 제압 · "+progress_text(g.enemies); milestone_time=2.5
	if data.has("boss") and g.player.pos.distance_to(points[-1])<320: begin_boss_intro(g)
func draw_guidance(g):
	if g.in_combat or g.overlay.visible: return
	var target=next_stop(g.enemies)
	var p=(target.pos-g.cam+Vector2(0,-65)).clamp(Vector2(80,270),Vector2(1270,565)).round()
	g.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,-9),p+Vector2(7,-9),p]),Color("c4d99e"))
	g.text_at(target.name,p+Vector2(-80,-18),15,Color("e0d5bb"))
func draw(g):
	if sign==null:
		sign=load("res://assets/town/prop-1-v1.webp"); fire=load("res://assets/town/prop-0-v1.webp")
	# Small route markers and stepping stones fit the existing character scale.
	var path=[Vector2(340,800)]+points+[data.exit]
	for i in path.size()-1:
		var steps=maxi(1,int(path[i].distance_to(path[i+1])/85))
		for j in steps:
			var p=(path[i].lerp(path[i+1],float(j+1)/(steps+1))-g.cam).snapped(Vector2(2,2))
			g.draw_rect(Rect2(p,Vector2(10,4)),Color("888368"))
	for point in points:
		g.draw_texture(sign,point-g.cam-Vector2(25,90))
	g.draw_texture(fire,rest-g.cam-Vector2(30,30))
	g.text_at(rest_name,rest-g.cam+Vector2(-45,45),14,Color("d9cda8"))
	g.text_at("옆길 · 사슴과 거북",side-g.cam+Vector2(-60,-75),14,Color("c3c9ac"))
	var exit=data.exit-g.cam
	var ready=ready_to_clear(g.enemies)
	g.draw_arc(exit,40,0,TAU,20,Color("b8d99c") if ready else Color("777e66"),2,false)
	g.draw_texture(sign,exit-Vector2(20,48))
	g.text_at("길 잇기 [F]" if ready else "길목을 제압하세요",exit+Vector2(-65,40),15,Color("d9d7ab"))
func draw_minimap(g):
	var origin=Vector2(1230,46); var scale_map=Vector2(0.061,0.067)
	g.draw_style_box(g.GroveUI.frame(Color("18221eef")),Rect2(origin-Vector2(10,10),Vector2(195,110)))
	var path=[Vector2(340,800)]+points+[data.exit]
	for i in path.size()-1: g.draw_line(origin+path[i]*scale_map,origin+path[i+1]*scale_map,Color("8e9c72"),2,false)
	for i in points.size(): g.draw_circle(origin+points[i]*scale_map,3,Color("6c795f") if cleared_pack(g.enemies,i) else Color("ddbd7c"))
	g.draw_circle(origin+side*scale_map,2,Color("98b9a8"))
	g.draw_circle(origin+data.exit*scale_map,4,Color("c2dc8d"))
	g.draw_circle(origin+g.player.pos*scale_map,3,Color.WHITE)
