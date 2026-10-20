extends RefCounted
# Data policy only. The 3->4 synthesis transaction and result roll are not implemented yet.
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
