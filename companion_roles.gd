extends RefCounted
const LABELS={"boar":"돌진","marten":"속공","wolf":"추격","fox":"범위","turtle":"보호","deer":"회복","bat":"급강하"}
const DESCRIPTIONS={
	"bat":"빠르게 접근해 물기 · 스킬로 급강하 집중 타격",
	"boar":"가까운 적과 교전 · 스킬로 경로의 적을 관통 · 1.5초 기절",
	"marten":"기절한 적 우선 · 빠른 기본 공격으로 집중 타격",
	"wolf":"체력이 낮은 적 우선 · 한 대상을 끝까지 추격",
	"fox":"모여 있는 적 우선 · 거리를 벌리고 넓은 지점 폭발",
	"turtle":"드루이드 가까운 적 우선 · 도발과 방어로 전열 보호",
	"deer":"다친 아군 가까이 이동 · 회복과 광역 회복 지원"}
const SKILLS={"boar":"관통 돌진","marten":"집중 타격","wolf":"추격 타격","fox":"야성 폭발","turtle":"도발 · 방어","deer":"숲의 회복","bat":"급강하 타격"}
const TRAIT_MARKS={"강인함":"강","용맹함":"용","단단함":"단","민첩함":"민","다정함":"정"}
# Only targeting priorities change; ranges, power and cooldowns stay in main.
static func target(kind,origin,enemies,player_pos,radius):
	var best={}
	var score=INF
	for e in enemies:
		if e.hp<=0 or origin.distance_to(e.pos)>radius: continue
		var distance=origin.distance_to(e.pos)
		var value=distance
		match kind:
			"marten": value=distance-(500 if e.get("stun",0.0)>0 else 0)
			"wolf": value=400*e.hp/e.maxhp+distance*0.25
			"turtle": value=e.pos.distance_to(player_pos)*0.8+distance*0.2
			"fox":
				var neighbors=0
				for other in enemies:
					if other.hp>0 and other.pos.distance_to(e.pos)<125: neighbors+=1
				value=distance-neighbors*500
		if value<score:
			score=value
			best=e
	return best
static func describe(d,loot):
	return DESCRIPTIONS.get(d.kind,"")+"\n스킬: "+SKILLS.get(d.kind,"")+"\n상시 특성: "+d.trait+" · "+loot.TRAIT_DESCRIPTIONS.get(d.trait,"")+(" (회복량에는 적용되지 않는 기존 특성)" if d.kind=="deer" and d.trait=="용맹함" else "")
static func signal_action(unit,caption):
	unit.role_action=caption
	unit.role_flash=1.1
static func add_metric(unit,key,amount):
	if amount<=0: return
	if not unit.has("contribution"): unit.contribution={}
	unit.contribution[key]=unit.contribution.get(key,0.0)+amount
