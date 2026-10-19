extends RefCounted
# No hidden IVs. Only species/level, one fixed trait, and explicit affixes.
const GRADES=["common","rare","epic"]
const NAMES={"common":"일반","rare":"희귀","epic":"영웅"}
const COLORS={"common":Color("b8d59c"),"rare":Color("78bdec"),"epic":Color("c599ef")}
const TRAIT_DESCRIPTIONS={"강인함":"최대 체력 +20%","용맹함":"공격력 +18%","단단함":"받는 피해 -15%","민첩함":"이동 속도 +20%","다정함":"주는 회복량 +25%"}
const COUNTS={"common":1,"rare":2,"epic":3}
const OPTIONS={
	"vitality":{"name":"최대 체력","min":6,"max":14,"unit":"%"},
	"power":{"name":"공격력","min":4,"max":9,"unit":"%"},
	"armor":{"name":"받는 피해 감소","min":4,"max":9,"unit":"%"},
	"speed":{"name":"이동 속도","min":5,"max":12,"unit":"%"},
	"skill_haste":{"name":"동료 스킬 대기시간 감소","min":6,"max":12,"unit":"%"},
	"stun_hunter":{"name":"기절 대상 추가 피해","min":12,"max":24,"unit":"%"},
	"healing":{"name":"주는 회복량","min":8,"max":16,"unit":"%"}
}
static func pool(kind,temperament=""):
	var keys=["vitality","armor","speed","skill_haste"]
	keys.append("healing" if kind=="deer" else "power")
	if kind in ["boar","wolf","marten","fox"]: keys.append("stun_hunter")
	# Avoid repeating the same plain stat as the fixed trait.
	var excluded={"강인함":"vitality","용맹함":"power","단단함":"armor","민첩함":"speed","다정함":"healing"}.get(temperament,"")
	keys.erase(excluded)
	return keys
static func roll(kind,level,rng,forced_grade=""):
	var grade=forced_grade
	if not GRADES.has(grade):
		var pick=rng.randf()
		grade="common" if pick<0.75 else ("rare" if pick<0.97 else "epic")
	var traits=["강인함","용맹함","단단함","민첩함"]
	if kind=="deer":
		# Deer never attacks: do not roll a new attack-only trait on a healer.
		traits.erase("용맹함")
		traits.append("다정함")
	var temperament=traits[rng.randi_range(0,traits.size()-1)]
	var available=pool(kind,temperament)
	var options=[]
	for i in COUNTS[grade]:
		var index=rng.randi_range(0,available.size()-1)
		var key=available[index]
		available.remove_at(index)
		options.append({"key":key,"value":rng.randi_range(OPTIONS[key].min,OPTIONS[key].max)})
	return {"kind":kind,"level":maxi(1,int(level)),"xp":0,"trait":temperament,"grade":grade,"options":options}
static func normalize(record):
	# Legacy companions keep their original strength: no random migration rolls.
	var grade=record.get("grade","common")
	if not GRADES.has(grade): grade="common"
	var source=record.get("options",[])
	var options=[]
	var seen=[]
	if source is Array:
		for entry in source:
			if not entry is Dictionary: continue
			var key=entry.get("key","")
			if not OPTIONS.has(key) or seen.has(key) or not pool(record.kind).has(key): continue
			var value=entry.get("value",0)
			if not (value is int or value is float) or not is_finite(float(value)): continue
			options.append({"key":key,"value":clampi(int(value),OPTIONS[key].min,OPTIONS[key].max)})
			seen.append(key)
			if options.size()>=COUNTS[grade]: break
	record.grade=grade
	record.options=options
	return record
static func bonus(record,key):
	var amount=0.0
	for option in record.get("options",[]):
		if option.key==key: amount+=float(option.value)/100.0
	return amount
static func lines(record):
	var result=PackedStringArray()
	for option in record.get("options",[]):
		result.append("%s +%d%%" % [OPTIONS[option.key].name,int(option.value)])
	return result
static func grade(record): return record.get("grade","common")
static func color(record): return COLORS.get(grade(record),COLORS.common)
static func title(record): return NAMES.get(grade(record),NAMES.common)
static func same_options(raw,normalized):
	if not raw is Array or raw.size()!=normalized.size(): return false
	for i in raw.size():
		if not raw[i] is Dictionary or raw[i].size()!=2: return false
		if raw[i].get("key")!=normalized[i].key: return false
		var value=raw[i].get("value")
		if not (value is int or value is float) or float(value)!=float(normalized[i].value): return false
	return true
