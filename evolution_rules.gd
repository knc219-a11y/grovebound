extends RefCounted
# The 5->6 execution remains disabled until its final reward is agreed.
const Loot=preload("res://companion_loot.gd")
static func material_error(d,squad,is_main=false):
	if d.is_empty(): return "동료가 없습니다."
	if Loot.star(d)!=4 or int(d.get("level",0))!=50: return "4성 Lv.50 필요"
	if not Loot.Special.ready(d) or Loot.Special.pending(d): return "능력 선택을 먼저 완료하세요."
	if not Loot.Special.Rules.EXISTING_SPECIAL_KINDS.has(d.get("kind","")): return "현재 야수 동료만 진화할 수 있습니다."
	if not is_main and (squad.has(d.id) or d.get("favorite",false)): return "동행/즐겨찾기 동료는 보조로 사용할 수 없습니다."
	return ""
static func preview(records,squad,main_id,support_id):
	if main_id==support_id: return {"error":"서로 다른 동료를 선택하세요."}
	var selected=[]
	for id in [main_id,support_id]:
		var matches=records.filter(func(d): return d.get("id")==id)
		if matches.size()!=1: return {"error":"동료 명단이 바뀌었습니다. 다시 선택하세요."}
		var d=matches[0]
		var error=material_error(d,squad,id==main_id)
		if not error.is_empty(): return {"error":error}
		selected.append(d.duplicate(true))
	var result=selected[0].duplicate(true)
	result.star=5
	result.level=50
	result.xp=0
	result.erase("legacy_overcap")
	result.special.evolution={"version":1,"state":"pending","ability":""}
	return {"error":"","materials":selected,"result":result}
