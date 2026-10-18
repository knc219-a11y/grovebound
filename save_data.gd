extends RefCounted
const Loot=preload("res://companion_loot.gd")
# Normalize legacy JSON without guessing which creature a dangling party ID meant.
static func id_value(value):
	if value is int: return value
	if value is float and is_finite(value) and value==floor(value): return int(value)
	if value is String and value.is_valid_int(): return int(value)
	return -1

static func integer(value, fallback: int):
	var result = id_value(value)
	return fallback if result<0 else result

static func normalize(data: Dictionary, valid_kinds: Array):
	var repaired = not data.has("owned") or not data.has("squad")
	var source = data.get("owned",[])
	if not source is Array:
		source = []
		repaired = true
	var next_id = maxi(1,integer(data.get("next_id",1),1))
	for raw in source:
		if raw is Dictionary: next_id = maxi(next_id,id_value(raw.get("id",-1))+1)
	var owned = []
	var ids = {}
	for raw in source:
		if not raw is Dictionary or not valid_kinds.has(raw.get("kind","")):
			repaired = true
			continue
		var record = raw.duplicate(true)
		var id = id_value(raw.get("id",-1))
		if id<=0 or ids.has(id):
			id = next_id
			next_id += 1
			repaired = true
		record.id = id
		record.level = maxi(1,integer(raw.get("level",1),1))
		record.xp = integer(raw.get("xp",0),0)
		if not raw.get("trait",null) is String or raw.get("trait","").is_empty():
			record.trait = "강인함"
			repaired = true
		if not raw.has("level") or not raw.has("xp") or record.level!=raw.get("level") or record.xp!=raw.get("xp"):
			repaired = true
		Loot.normalize(record)
		if raw.get("grade")!=record.grade or not Loot.same_options(raw.get("options"),record.options): repaired=true
		owned.append(record)
		ids[id] = true
	var source_squad = data.get("squad",[])
	if not source_squad is Array:
		source_squad = []
		repaired = true
	var squad = []
	for value in source_squad:
		var id = id_value(value.get("id",-1) if value is Dictionary else value)
		if not ids.has(id) or squad.has(id) or squad.size()>=6:
			repaired = true
			continue
		if value is Dictionary: repaired = true
		squad.append(id)
	return {"owned":owned,"squad":squad,"next_id":next_id,"repaired":repaired}
