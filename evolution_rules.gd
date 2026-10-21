extends RefCounted
# Stage policy shared by preview, confirmation and commit.
const Loot=preload("res://companion_loot.gd")
static func material_error(d,squad,is_main=false,source_star=4):
	if d.is_empty(): return "동료가 없습니다."
	if source_star not in [4,5] or Loot.star(d)!=source_star or int(d.get("level",0))!=source_star*10+10: return "%d성 Lv.%d 필요" % [source_star,source_star*10+10]
	if not Loot.Special.ready(d) or Loot.Special.pending(d) or not Loot.Special.ELEMENTS.has(Loot.Special.element(d)) or not Loot.Special.choices(d.get("kind","")).has(Loot.Special.unique(d)) or (source_star==5 and not Loot.Special.evolution_choices(d.get("kind","")).has(Loot.Special.evolution(d))): return "능력 선택을 먼저 완료하세요."
	if not Loot.Special.Rules.EXISTING_SPECIAL_KINDS.has(d.get("kind","")): return "현재 야수 동료만 진화할 수 있습니다."
	if not is_main and (squad.has(d.id) or d.get("favorite",false)): return "동행/즐겨찾기 동료는 보조로 사용할 수 없습니다."
	return ""
static func preview(records,squad,main_id,support_id):
	if main_id==support_id: return {"error":"서로 다른 동료를 선택하세요."}
	var mains=records.filter(func(d): return d.get("id")==main_id)
	if mains.size()!=1: return {"error":"주 동료 정보가 바뀌었습니다."}
	var source_star=Loot.star(mains[0])
	var selected=[]
	for id in [main_id,support_id]:
		var matches=records.filter(func(d): return d.get("id")==id)
		if matches.size()!=1: return {"error":"동료 명단이 바뀌었습니다. 다시 선택하세요."}
		var d=matches[0]
		var error=material_error(d,squad,id==main_id,source_star)
		if not error.is_empty(): return {"error":error}
		selected.append(d.duplicate(true))
	var result=selected[0].duplicate(true)
	result.star=source_star+1
	result.level=1 if source_star==4 else 60
	result.xp=0
	result.erase("legacy_overcap")
	if source_star==4: result.special.evolution={"version":1,"state":"pending","ability":"","growth_version":2}
	else: result.special.evolution.enhanced=true
	return {"error":"","materials":selected,"result":result}
