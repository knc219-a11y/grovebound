extends RefCounted
# Shared element catalog; beast uniques are the first family-specific catalog.
const ELEMENTS={
	"fire":{"name":"불꽃","color":"edaa69","description":"공격종 피해 +10% · 사슴 회복 +15% · 거북 방어 +1초"},
	"water":{"name":"물","color":"78bee5","description":"스킬 재사용 대기시간 15% 감소"},
	"earth":{"name":"대지","color":"d9bd76","description":"최대 체력 +12% · 받는 피해 5% 감소"},
	"wind":{"name":"바람","color":"83dbc7","description":"이동 속도 +8% · 스킬 대기시간 10% 감소"}
}
const UNIQUES={
	"frontline":{
		"vital":{"name":"강인한 생명","description":"최대 체력 +15%"},
		"guard":{"name":"견고한 몸","description":"받는 피해 8% 감소"},
		"barrier":{"name":"전열의 결의","description":"스킬 사용 시 자신에게 최대 체력 10% 보호막 · 4초"}},
	"striker":{
		"basic":{"name":"날카로운 발톱","description":"기본 공격 피해 +15%"},
		"skill":{"name":"응축된 야성","description":"스킬 피해 +15%"},
		"execute":{"name":"끝없는 추격","description":"체력 50% 이하 적에게 주는 피해 +15%"}},
	"ranged_support":{
		"potency":{"name":"깊어진 교감","description":"여우 범위 피해 / 사슴 회복량 +15%"},
		"haste":{"name":"빠른 호응","description":"스킬 대기시간 12% 감소"},
		"reach":{"name":"퍼지는 기운","description":"여우 폭발 / 사슴 스킬 회복 반경 +20%"}}
}
# Approved first balance values; tune here after player feedback.
const EVOLUTION_VALUES={"vital":0.20,"guard":0.08,"barrier":0.15,"barrier_seconds":5.0,"basic":0.20,"skill":0.20,"execute":0.20,"execute_threshold":0.50,"potency":0.20,"haste":0.10,"reach":0.20}
const SIX_VALUES={"vital":0.30,"guard":0.12,"barrier":0.20,"barrier_seconds":6.0,"basic":0.30,"skill":0.30,"execute":0.30,"execute_threshold":0.50,"potency":0.30,"haste":0.15,"reach":0.30}
const EVOLUTION_START=1.10
const EVOLUTION_PER_LEVEL=0.02
const EVOLUTIONS={
	"frontline":{
		"vital":{"name":"넘치는 생명","description":"최대 체력 +20%"},
		"guard":{"name":"불굴의 수호","description":"받는 피해 8% 감소"},
		"barrier":{"name":"진화의 방벽","description":"스킬 사용 시 자신에게 최대 체력15% 보호막 · 5초"}},
	"striker":{
		"basic":{"name":"숙련된 사냥","description":"기본 공격 피해 +20%"},
		"skill":{"name":"폭발하는 야성","description":"스킬 피해 +20%"},
		"execute":{"name":"집요한 추격","description":"체력50% 이하 적에게 피해 +20%"}},
	"ranged_support":{
		"potency":{"name":"깊은 공명","description":"여우 스킬 피해 / 사슴 회복량 +20%"},
		"haste":{"name":"민첩한 호응","description":"스킬 대기시간 10% 감소"},
		"reach":{"name":"넓어진 교감","description":"여우 폭발 / 사슴 스킬 회복 반경 +20%"}}
}
const SKILLS={"boar":"수호 돌진","turtle":"전열의 방벽","marten":"연속 사냥","wolf":"사냥 표식","bat":"충격 급강하","fox":"잔여 폭발","deer":"생명의 보호"}
const Rules=preload("res://synthesis_rules.gd")
const SKILL_DESCRIPTIONS={
	"boar":"관통 돌진 후 받는 피해25% 감소 · 3초",
	"turtle":"도발·방어 + 주변 아군 피해15% 감소 · 3초",
	"marten":"공격력1.5배씩3회 · 처치 시 남은 타격 대상 전환",
	"wolf":"공격력3.5배 타격 · 자신에게 받는 피해20% 증가 표식5초",
	"bat":"공격력3.5배 집중 타격 + 주변100px에1배 충격파",
	"fox":"공격력2.5배 폭발 +0.6초 후 같은 위치1배 잔여 폭발",
	"deer":"범위 회복 + 대상 최대 체력5% 보호막4초"
}
static func is_special(d):
	return int(d.get("star",0)) in [4,5,6] and d.get("special") is Dictionary and int(d.special.get("version",0))==1
static func pending(d): return is_special(d) and (not ready(d) or evolution_pending(d))
# Existing identity and skills stay available while the additional choice is pending.
static func ready(d): return is_special(d) and d.special.get("state","")=="ready"
static func evolution_pending(d):
	return is_special(d) and int(d.get("star",0))>=5 and d.special.get("evolution",{}).get("state","")!="ready"
static func evolution_choices(kind): return EVOLUTIONS.get(Rules.position_of(kind),{})
static func evolution(d):
	return d.special.get("evolution",{}).get("ability","") if ready(d) and int(d.star)>=5 and not evolution_pending(d) else ""
static func evolution_values(d): return SIX_VALUES if int(d.get("star",0))==6 else EVOLUTION_VALUES
static func evolution_value(d,key): return evolution_values(d)[key] if evolution(d)==key else 0.0
static func evolution_description(d):
	var ability=evolution(d)
	if ability.is_empty(): return ""
	var info=evolution_choices(d.kind)[ability].description
	if int(d.star)!=6: return info
	return info.replace("+20%","+30%").replace("8%","12%").replace("15% 보호막 · 5초","20% 보호막 · 6초").replace("10% 감소","15% 감소")
static func growth(d):
	var level=int(d.level)
	if int(d.star)==5: return (0.70+0.022*49)*(EVOLUTION_START+EVOLUTION_PER_LEVEL*(level-50))
	if int(d.star)==6: return (0.70+0.022*49)*1.30*(EVOLUTION_START+EVOLUTION_PER_LEVEL*(level-60))
	return 0.70+0.022*(level-1)
static func choices(kind): return UNIQUES.get(Rules.position_of(kind),{})
static func element(d): return d.special.get("element","") if ready(d) else ""
static func unique(d): return d.special.get("unique","") if ready(d) else ""
static func hp_scale(d):
	return (1.0+39*0.26)*growth(d)
static func attack_scale(d):
	return (1.0+39*0.22)*growth(d)
static func hp_bonus(d): return (0.12 if element(d)=="earth" else 0.0)+(0.15 if unique(d)=="vital" else 0.0)+evolution_value(d,"vital")
static func armor(d): return (0.95 if element(d)=="earth" else 1.0)*(0.92 if unique(d)=="guard" else 1.0)*(1.0-evolution_value(d,"guard"))
static func haste(d): return (0.85 if element(d)=="water" else 0.9 if element(d)=="wind" else 1.0)*(0.88 if unique(d)=="haste" else 1.0)*(1.0-evolution_value(d,"haste"))
static func speed(d): return 1.08 if element(d)=="wind" else 1.0
static func radius(d): return (1.2 if unique(d)=="reach" else 1.0)*(1.0+evolution_value(d,"reach"))
static func healing(d): return (1.15 if element(d)=="fire" else 1.0)*(1.15 if unique(d)=="potency" else 1.0)*(1.0+evolution_value(d,"potency"))
static func damage(d,is_skill,target):
	var value=1.10 if element(d)=="fire" and d.kind not in ["turtle","deer"] else 1.0
	if (unique(d)=="skill" and is_skill) or (unique(d)=="basic" and not is_skill): value*=1.15
	if unique(d)=="execute" and target.hp<=target.maxhp*0.5: value*=1.15
	if unique(d)=="potency" and d.kind=="fox" and is_skill: value*=1.15
	if is_skill: value*=1.0+evolution_value(d,"skill")
	else: value*=1.0+evolution_value(d,"basic")
	if target.hp<=target.maxhp*EVOLUTION_VALUES.execute_threshold: value*=1.0+evolution_value(d,"execute")
	if d.kind=="fox" and is_skill: value*=1.0+evolution_value(d,"potency")
	return value
static func normalize(d):
	if not is_special(d): return
	var s=d.special
	s.version=1
	var valid=ELEMENTS.has(s.get("element","")) and not ELEMENTS.get(s.get("element",""),{}).get("pending",false) and choices(d.kind).has(s.get("unique",""))
	s.state="ready" if s.get("state")=="ready" and valid else "pending"
	if not valid:
		s.element=""
		s.unique=""
	if int(d.star)>=5:
		var e=s.get("evolution",{})
		if not e is Dictionary: e={}
		e.version=1
		var chosen=e.get("ability","")
		e.state="ready" if e.get("state")=="ready" and evolution_choices(d.kind).has(chosen) else "pending"
		e.ability=chosen if e.state=="ready" else ""
		if int(d.star)==6 and e.state=="ready": e.enhanced=true
		s.evolution=e
static func summary(d):
	if not is_special(d): return ""
	if not ready(d): return "특수개체 · 속성/고유 능력 선택 대기"
	if evolution_pending(d): return "5성 진화 · 진화 능력 선택 대기"
	return "%s · %s · %s" % [ELEMENTS[element(d)].name,choices(d.kind)[unique(d)].name,SKILLS[d.kind]]+(" · 진화: "+evolution_choices(d.kind)[evolution(d)].name+(" 강화" if int(d.star)==6 else "") if not evolution(d).is_empty() else "")

static func equivalent(a,b):
	if (a is int or a is float) and (b is int or b is float): return float(a)==float(b)
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not equivalent(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in a.size():
			if not equivalent(a[i],b[i]): return false
		return true
	return a==b
