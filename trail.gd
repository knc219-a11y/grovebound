extends RefCounted
const Campaign=preload("res://campaign.gd")
# Reuses the approved meadow and original reward-bearing encounters.
# Main-path waves alternate dense packs with a small encounter and a rest.
const PACKS=[Vector2(650,790),Vector2(1000,850),Vector2(1100,510),Vector2(1500,820),Vector2(1850,1040),Vector2(2190,760)]
# Added followers share the existing reward budget: kills only, no extra XP/loot/bonds.
const FOLLOWERS={0:4,3:5,5:7}
const FOLLOWER_OFFSETS=[Vector2(-75,-35),Vector2(-20,42),Vector2(50,-42),Vector2(100,35),Vector2(20,-80),Vector2(110,-55),Vector2(-55,80)]
const FORMATIONS={
	0:[Vector2(-80,-20),Vector2(-25,15),Vector2(35,-15),Vector2(95,20)],
	3:[Vector2(-110,-45),Vector2(-110,35),Vector2(-60,-10),Vector2(-40,65),Vector2(25,-65)],
	5:[Vector2(-100,-65),Vector2(-50,-45),Vector2(10,-65),Vector2(-100,65),Vector2(-40,45),Vector2(25,65),Vector2(90,-25)]}
const ENCOUNTERS={
	0:{"name":"입구 무리","hint":"관통 돌진으로 길을 여세요"},
	1:{"name":"작은 길목","hint":"적은 수의 야수와 짧은 교전"},
	3:{"name":"굽은 풀길","hint":"전열을 모아 범위 스킬로 제압"},
	5:{"name":"늑대 집결지","hint":"두 갈래 무리를 모아 한 번에"}}
const KINDS=["boar","turtle","deer","fox","marten","wolf"]
# Four main-path encounters describe progress. North/south packs stay optional.
const CORE_PACKS=[0,1,3,5]
const OPTIONAL_PACKS=[2,4]
const REST=Vector2(1650,540)
const NORTH=Vector2(1100,510)
const SOUTH=Vector2(1850,1040)
var visited={}
var sign:Texture2D
var bench:Texture2D
var fire:Texture2D
var milestone=""
var milestone_time=0.0
var campaign_id=1
var encounters=ENCOUNTERS
var rest_name="풀그늘 쉼터"
func configure(id):
	campaign_id=id
	rest_name="풀그늘 쉼터" if id==1 else "채굴터 쉼터" if id==2 else "옛 묘지기 쉼터"
	encounters=ENCOUNTERS
	if id>1:
		encounters={}
		for pack in CORE_PACKS: encounters[pack]={"name":Campaign.STAGES[id].names[pack],"hint":Campaign.STAGES[id].hints[pack]}
func reset():
	visited.clear()
	milestone=""
	milestone_time=0.0
static func follower_offsets(pack): return FORMATIONS.get(pack,FOLLOWER_OFFSETS)
static func escort_offset(pack): return Vector2(-65,15) if pack==3 else Vector2(85,60)
func engageable(e):
	if e.get("stage_entry",false) and not visited.has("boss_intro"): return false
	var pack=int(e.get("pack",-1))
	return pack not in OPTIONAL_PACKS or visited.has("engaged_"+str(pack))
func unlock_paths(p):
	# Entering the marked side clearing is the player's explicit route choice.
	for pack in OPTIONAL_PACKS:
		if p.distance_to(PACKS[pack])<175: visited["engaged_"+str(pack)]=true
func cleared_pack(enemies,pack):
	var found=false
	for e in enemies:
		if int(e.get("pack",-1))!=pack: continue
		found=true
		if e.hp>0: return false
	return found
func core_progress(enemies):
	var cleared=0
	for pack in CORE_PACKS:
		if cleared_pack(enemies,pack): cleared+=1
	return {"cleared":cleared,"total":CORE_PACKS.size()}
func progress_text(enemies):
	var p=core_progress(enemies)
	return "길목 %d/%d" % [p.cleared,p.total]
func pack_status(enemies,pack):
	var total=0
	var alive=0
	for e in enemies:
		if int(e.get("pack",-1))!=pack: continue
		total+=1
		if e.hp>0: alive+=1
	return {"total":total,"alive":alive}
func next_stop(enemies):
	for pack in CORE_PACKS:
		if pack_status(enemies,pack).alive>0:
			if pack==5 and not visited.has("rest"):
				return {"pos":REST,"name":rest_name+" · 선택 휴식","pack":-1}
			return {"pos":PACKS[pack],"name":encounters[pack].name,"pack":pack}
	return {"pos":Vector2(2380,820),"name":"우두머리 공터","pack":-2}
func nearby_pack(enemies,player_pos):
	var result=-1
	var distance=300.0
	for pack in CORE_PACKS:
		var next_distance=player_pos.distance_to(PACKS[pack])
		if next_distance<distance and pack_status(enemies,pack).alive>0:
			distance=next_distance
			result=pack
	return result
func objective(enemies,player_pos):
	if visited.has("boss_intro"):
		for e in enemies:
			if e.boss and e.hp>0: return "우두머리 · 예고를 보고 회피"
	var pack=nearby_pack(enemies,player_pos)
	if pack>=0:
		var status=pack_status(enemies,pack)
		return "%s · 남은 %d/%d" % [encounters[pack].name,status.alive,status.total]
	if player_pos.distance_to(REST)<150:
		return "비전투 중 [F] 편성 · 회복 스킬로 정비"
	return "다음 · "+next_stop(enemies).name
func update_progress(g,dt):
	milestone_time=maxf(0,milestone_time-dt)
	for pack in CORE_PACKS:
		var key="cleared_"+str(pack)
		if not visited.has(key) and cleared_pack(g.enemies,pack):
			visited[key]=true
			milestone=encounters[pack].name+" 제압 · "+progress_text(g.enemies)
			milestone_time=2.6
func begin_boss_intro(g):
	if visited.has("boss_intro"): return false
	visited.boss_intro=true
	for e in g.enemies:
		if e.boss and e.hp>0:
			e.active=true
			e.intro=1.35
			e.wind=0.0
			e.dash=0.0
			e.cd=maxf(e.cd,0.8)
			g.notify("거대한 발자국의 주인이 모습을 드러냈습니다. 발구르기와 돌진을 살피세요." if campaign_id==1 else Campaign.STAGES[campaign_id].boss+" · 지면의 공격 예고를 보고 피하세요.")
			return true
	return false
func area(p):
	if campaign_id>1:
		var names=Campaign.STAGES[campaign_id].names
		if p.distance_to(NORTH)<175: return "선택 · "+names[2]
		if p.distance_to(SOUTH)<175: return "선택 · "+names[4]
		if p.distance_to(REST)<150: return rest_name
		if p.x>2300: return "우두머리 공터"
		return names[0] if p.x<900 else names[1] if p.x<1400 else names[3] if p.x<1850 else names[5]
	if p.distance_to(NORTH)<175: return "옆길 · 고요한 풀밭"
	if p.distance_to(SOUTH)<175: return "옆길 · 낮은 덤불길"
	if p.distance_to(REST)<150: return "풀그늘 쉼터 · 편성 점검"
	if p.x<900: return "01 초록물 입구"
	if p.x<1400: return "02 두갈래 초지"
	if p.x<1850: return "03 굽은 풀길"
	if p.x<2300: return "04 깊은 풀길"
	return "05 우두머리 공터"
func near_rest(p): return p.distance_to(REST)<100
func update(g,dt=0.0):
	unlock_paths(g.player.pos)
	update_progress(g,dt)
	for entry in [["north",NORTH,"북쪽 옆길 · 사슴과 늑대가 머무는 조용한 풀밭입니다."],["south",SOUTH,"남쪽 옆길 · 담비가 숨어 있는 낮은 덤불길입니다."],["rest",REST,"풀그늘 쉼터 · 전투 밖에서 동행 편성을 점검할 수 있습니다."]]:
		if g.player.pos.distance_to(entry[1])<160 and not visited.has(entry[0]):
			visited[entry[0]]=true
			g.notify(entry[2] if campaign_id==1 else rest_name+" · 비전투 중 편성을 점검하세요." if entry[0]=="rest" else "선택 길 · "+Campaign.STAGES[campaign_id].names[2 if entry[0]=="north" else 4])
	if g.player.pos.x>2290 and not visited.has("boss"):
		visited.boss=true
		g.notify("앞은 "+Campaign.STAGES[campaign_id].boss+"의 공터입니다. "+progress_text(g.enemies)+" · 지원 스킬을 확인하세요.")
	if g.player.pos.x>2350: begin_boss_intro(g)
func draw_guidance(g):
	if milestone_time>0 and not g.boss_panel.visible:
		var width=g.font.get_string_size(milestone,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+32
		var rect=Rect2(Vector2(720-width/2,120),Vector2(width,35))
		g.draw_style_box(g.GroveUI.frame(Color("26382aee")),rect)
		g.text_at(milestone,rect.position+Vector2(16,24),18,Color("cde5a7"))
	if g.in_combat or g.overlay.visible: return
	var stop=next_stop(g.enemies)
	var target=stop.pos-g.cam
	if g.player.pos.distance_to(stop.pos)<90: return
	var p=(target+Vector2(0,-58)).clamp(Vector2(60,270),Vector2(1320,570)).round()
	g.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,-9),p+Vector2(7,-9),p]),Color("d9c68e"))
	if stop.pack>=0 and g.player.pos.distance_to(stop.pos)<500: return
	var width=g.font.get_string_size(stop.name,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
	var caption=p+Vector2(-width/2,-17)
	caption.x=clampf(caption.x,24,1416-width)
	g.text_at(stop.name,caption,15,Color("e5dbb7"))
func draw(g):
	if sign==null:
		sign=load("res://assets/town/prop-1-v1.webp")
		bench=load("res://assets/town/prop-2-v1.webp")
		fire=load("res://assets/town/prop-0-v1.webp")
	var focus=nearby_pack(g.enemies,g.player.pos)
	if focus<0: focus=next_stop(g.enemies).pack
	for pack in CORE_PACKS:
		if pack!=focus or g.in_combat or cleared_pack(g.enemies,pack) or g.player.pos.distance_to(PACKS[pack])>500: continue
		var p=PACKS[pack]-g.cam+Vector2(-75,-115)
		if p.x<20 or p.x>1200 or p.y<245 or p.y>570: continue
		var status=pack_status(g.enemies,pack)
		if status.total==0: continue
		g.text_at(encounters[pack].name+" · "+str(status.total)+"마리",p,16,Color("e2d3ab"))
		g.text_at(encounters[pack].hint,p+Vector2(0,22),14,Color("b8c7a0"))
	# Sparse stepping stones suggest branches without repainting the whole map.
	for path in [[Vector2(950,790),Vector2(1050,650),NORTH],[Vector2(1720,820),Vector2(1790,970),SOUTH]]:
		for segment in 2:
			for step in 4:
				var p=path[segment].lerp(path[segment+1],(step+0.5)/4.0)-g.cam
				p=p.snapped(Vector2(2,2))
				g.draw_rect(Rect2(p+Vector2(-5,1),Vector2(12,6)),Color("4e5741"))
				g.draw_rect(Rect2(p+Vector2(-5,-2),Vector2(10,5)),Color("989576"))
	for p in [Vector2(950,790),Vector2(1720,820),Vector2(2310,760)]:
		g.draw_texture(sign,p-g.cam-Vector2(20,42))
	g.draw_texture(fire,REST-g.cam-Vector2(40,25))
	g.draw_texture(bench,REST-g.cam+Vector2(35,20))
	g.text_at(rest_name,REST-g.cam+Vector2(-55,68),15,Color("e0d5bb"))
	g.text_at(("북쪽 풀밭" if campaign_id==1 else Campaign.STAGES[campaign_id].names[2])+" · 접근 시 교전",Vector2(1010,690)-g.cam,14,Color("d0c59d"))
	g.text_at(("남쪽 덤불길" if campaign_id==1 else Campaign.STAGES[campaign_id].names[4])+" · 접근 시 교전",Vector2(1740,920)-g.cam,14,Color("d0c59d"))
	for i in 4:
		var p=Vector2(2330+i*45,825+(i%2)*16)-g.cam
		for offset in [Vector2.ZERO,Vector2(5,-8),Vector2(-4,-9)]:
			g.draw_rect(Rect2((p+offset).round(),Vector2(5,7)),Color("6c624a"))
