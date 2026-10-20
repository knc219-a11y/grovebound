extends RefCounted
# Reuses the approved meadow and original reward-bearing encounters.
# The entry pack also contains four weak, reward-neutral followers.
const PACKS=[Vector2(650,790),Vector2(1000,850),Vector2(1100,510),Vector2(1500,820),Vector2(1850,1040),Vector2(2190,760)]
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
func reset(): visited.clear()
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
			g.notify("거대한 발자국의 주인이 모습을 드러냈습니다. 발구르기와 돌진을 살피세요.")
			return true
	return false
func area(p):
	if p.distance_to(NORTH)<175: return "옆길 · 고요한 풀밭"
	if p.distance_to(SOUTH)<175: return "옆길 · 낮은 덤불길"
	if p.distance_to(REST)<150: return "풀그늘 쉼터 · 편성 점검"
	if p.x<900: return "01 초록물 입구"
	if p.x<1400: return "02 두갈래 초지"
	if p.x<1850: return "03 굽은 풀길"
	if p.x<2300: return "04 깊은 풀길"
	return "05 우두머리 공터"
func near_rest(p): return p.distance_to(REST)<100
func update(g):
	for entry in [["north",NORTH,"북쪽 옆길 · 사슴과 늑대가 머무는 조용한 풀밭입니다."],["south",SOUTH,"남쪽 옆길 · 담비가 숨어 있는 낮은 덤불길입니다."],["rest",REST,"풀그늘 쉼터 · 전투 밖에서 동행 편성을 점검할 수 있습니다."]]:
		if g.player.pos.distance_to(entry[1])<160 and not visited.has(entry[0]):
			visited[entry[0]]=true
			g.notify(entry[2])
	if g.player.pos.x>2290 and not visited.has("boss"):
		visited.boss=true
		g.notify("부러진 표지판과 거대한 발자국… 앞은 우두머리 공터입니다. "+progress_text(g.enemies)+" · 지원 스킬을 확인하세요.")
	if g.player.pos.x>2350: begin_boss_intro(g)
func draw(g):
	if sign==null:
		sign=load("res://assets/town/prop-1-v1.webp")
		bench=load("res://assets/town/prop-2-v1.webp")
		fire=load("res://assets/town/prop-0-v1.webp")
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
	g.text_at("풀그늘 쉼터",REST-g.cam+Vector2(-55,68),15,Color("e0d5bb"))
	g.text_at("북쪽 풀밭",Vector2(1010,690)-g.cam,14,Color("d0c59d"))
	g.text_at("남쪽 덤불길",Vector2(1740,920)-g.cam,14,Color("d0c59d"))
	for i in 4:
		var p=Vector2(2330+i*45,825+(i%2)*16)-g.cam
		for offset in [Vector2.ZERO,Vector2(5,-8),Vector2(-4,-9)]:
			g.draw_rect(Rect2((p+offset).round(),Vector2(5,7)),Color("6c624a"))
