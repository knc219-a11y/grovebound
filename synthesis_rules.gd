extends RefCounted
# Read-only policy and planning. Actual consumption and saved result creation live in main.gd.
const POSITIONS={
	"frontline":{"name":"전열","kinds":["boar","turtle"]},
	"striker":{"name":"공격","kinds":["marten","wolf","bat"]},
	"ranged_support":{"name":"원거리·지원","kinds":["fox","deer"]}
}
const EXISTING_SPECIAL_KINDS=["boar","marten","fox","turtle","deer","wolf","bat"]
# New special-only species are registered here after their names, stats, skills and art
# are approved. They form a separate low-probability pool; the exact rate is undecided.
const NEW_SPECIAL_SPECIES=[]

static func position_of(kind):
	for key in POSITIONS:
		if kind in POSITIONS[key].kinds: return key
	return ""

static func existing_pool(preserve,main_kind):
	if preserve=="species": return [main_kind] if main_kind in EXISTING_SPECIAL_KINDS else []
	if preserve=="position":
		var position=position_of(main_kind)
		return POSITIONS.get(position,{}).get("kinds",[]).duplicate()
	return []

# These conditions are explicit approvals, not inferred balance defaults.
const REQUIRED_STAR=3
const REQUIRED_LEVEL=40
const RESULT_STAR=4
const RESULT_LEVEL=1
const SUCCESS_PERCENT=100
const EXTRA_COST=0

static func material_error(record,squad,is_main=false):
	if record.is_empty(): return "동료가 없습니다."
	if int(record.get("star",0))!=REQUIRED_STAR or int(record.get("level",0))!=REQUIRED_LEVEL:
		return "3성 Lv.40 필요"
	if not EXISTING_SPECIAL_KINDS.has(record.get("kind","")): return "지원하지 않는 종"
	if not is_main:
		if squad.has(record.get("id")): return "동행 중 · 보조 불가"
		if record.get("favorite",false): return "즐겨찾기 · 보조 불가"
	return ""

static func preview(records,squad,ids,main_id,preserve):
	if ids.size()!=3 or not ids.has(main_id): return {"error":"서로 다른 세 마리와 주재료를 선택하세요."}
	var selected=[]
	var seen=[]
	var main={}
	for id in ids:
		if seen.has(id): return {"error":"같은 동료를 중복 선택할 수 없습니다."}
		seen.append(id)
		var matches=records.filter(func(d): return d.get("id")==id)
		if matches.size()!=1: return {"error":"동료 명단이 바뀌었습니다. 다시 선택하세요."}
		var d=matches[0]
		var reason=material_error(d,squad,id==main_id)
		if not reason.is_empty(): return {"error":reason}
		selected.append(d.duplicate(true))
		if id==main_id: main=d
	var pool=existing_pool(preserve,main.kind)
	if pool.is_empty(): return {"error":"보존 방식을 선택하세요."}
	# A plan contains snapshots only, never an instantiated or rolled result.
	return {"error":"","main":main.duplicate(true),"materials":selected,"pool":pool,
		"preserve":preserve,"result_star":RESULT_STAR,"result_level":RESULT_LEVEL,
		"success_percent":SUCCESS_PERCENT,"extra_cost":EXTRA_COST}
