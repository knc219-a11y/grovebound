extends RefCounted
# Read-only presentation: use production policies; never consume, roll or save.
const R=preload("res://campaign_routes.gd")
const Loot=preload("res://companion_loot.gd")
const M=preload("res://companion_management.gd")
const S=preload("res://synthesis_rules.gd")
const Special=preload("res://special_companions.gd")

static func synthesis_plan(records,squad):
	var candidates=records.filter(func(d): return S.material_error(d,squad,true).is_empty())
	for main in candidates:
		var ids=[main.id]
		for d in candidates:
			if d.id!=main.id and not ids.has(d.id) and S.material_error(d,squad,false).is_empty(): ids.append(d.id)
			if ids.size()==3: break
		if ids.size()==3:
			var plan=S.preview(records,squad,ids,main.id,"species")
			if plan.get("error","") == "": return plan
	return {}

static func recommended(progress):
	# An already completed late route is a growth option, never a promised count.
	for theme in [4,5]:
		for stage in range(1,9):
			var c=R.coordinate(theme,stage)
			if R.available(c,progress) and R.growth_replay(c,progress): return c
	return {}

static func model(g):
	var progress=R.progress_for(g)
	var next_route={}
	for theme in range(1,6):
		for stage in range(1,9):
			var c=R.coordinate(theme,stage)
			if next_route.is_empty() and not R.contains(progress,c) and R.available(c,progress): next_route=c
	var completed=R.contains(progress,R.coordinate(5,8))
	var plan=synthesis_plan(g.owned,g.squad)
	var ready=g.owned.filter(func(d): return Special.ready(d))
	var active=ready.filter(func(d): return g.squad.slice(0,4).has(d.id))
	var pending=g.owned.filter(func(d): return Special.pending(d))
	var promote=g.owned.filter(func(d): return not M.promotion_preview(d).is_empty())
	var candidates=g.owned.filter(func(d): return S.material_error(d,g.squad,true).is_empty())
	var goal="다음 일반 탐험"
	var detail="동료 관리 → 육성 · 만렙에서 승급"
	if not promote.is_empty(): detail="승급 가능 %d마리 · 만렙 XP 중단 → 승급 후 재성장" % promote.size()
	if not next_route.is_empty() and int(next_route.theme)>=4:
		goal="첫 4성 → 최종보스 준비"
		detail="3성 Lv.40 세 마리 육성 → 4성 합성"
		if not plan.is_empty(): detail="합성 가능 · 보조 2마리 소모 / 주재료 보존 방식 선택"
		elif not candidates.is_empty(): detail="3성 Lv.40 후보 %d마리 · 즐겨찾기는 보조 불가" % candidates.size()
		if not ready.is_empty(): detail="4성+ 출전 %d마리 · 대기/보관은 동료 관리에서 편성" % active.size()
		if not active.is_empty():
			goal="최종보스 도전 준비"
			detail="갑주 대응 동료 출전 완료 · 스킬 사용과 생존 준비"
	if not pending.is_empty(): detail="능력 선택 대기 %d마리 · 동료 상세에서 완료 후 출발" % pending.size()
	if completed:
		goal="일반 40개 완료"
		detail="심층 해금 · 실제 탐험은 준비 중 / 일반 재탐험 가능"
	var replay=recommended(progress)
	var route=replay if not replay.is_empty() and not completed and int(next_route.get("theme",0))>=4 and active.is_empty() else next_route
	if completed: route=replay
	var route_text="첫 인연을 맺고 탐험을 준비하세요."
	if not route.is_empty():
		var is_replay=R.growth_replay(route,progress)
		var reward=R.rewards(route,is_replay)
		route_text="%s %d-%d · XP %d / 재료 %d" % ["성장 재탐험" if is_replay else "다음 탐험",route.theme,route.stage,reward.xp,reward.materials]
	return {"goal":goal,"detail":detail,"route":route,"route_text":route_text,"plan":plan,"active":active.size(),"completed":completed}

static func open_recommended(g):
	var c=model(g).route
	if c.is_empty(): return
	g.map_difficulty=c.difficulty; g.map_theme=c.theme; g.map_stage=c.stage
	g.open_stage_select()

static func level_status(d):
	if Special.pending(d): return "능력 선택 대기 · 동료 상세에서 완료"
	if not Loot.is_max_level(d): return "다음 레벨까지 %d" % maxi(0,M.needed_xp(d)-d.xp)
	if not M.promotion_preview(d).is_empty(): return "승급 준비 완료"
	if Loot.star(d)==3: return "합성 후보 · 세 마리와 보조 잠금 조건 확인"
	return "진화 화면에서 조건 확인" if Loot.star(d) in [4,5] else "최고 성급 · 최대 레벨"
