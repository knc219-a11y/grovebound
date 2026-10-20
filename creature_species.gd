extends RefCounted
# Taming policy is independent of enemy AI and stage placement. No new player class is created here.
const CLASS_FAMILIES={"druid":["beast"],"contractor":["monster"],"necromancer":["undead"]}
const FAMILIES={"beast":"야수","monster":"마물","undead":"언데드"}
const ORIGINAL=["boar","marten","fox","turtle","deer","wolf"]
const NEW={
	"bat":{"name":"동굴박쥐","family":"beast","height":32,"stats":[70,15,60,150],"reach":55,"wind":0.55,"radius":50,"speed":135},
	"slime":{"name":"이끼 슬라임","family":"monster","height":30,"stats":[65,8,50,70],"reach":50,"wind":0.75,"radius":60,"speed":68},
	"golem":{"name":"바위 마물","family":"monster","height":60,"stats":[160,15,90,65],"reach":85,"wind":1.05,"radius":95,"speed":65},
	"skeleton":{"name":"해골병","family":"undead","height":52,"stats":[70,10,55,95],"reach":55,"wind":0.65,"radius":60,"speed":95},
	"wraith":{"name":"묘역의 망령","family":"undead","height":50,"stats":[75,10,210,80],"reach":210,"wind":0.95,"radius":75,"speed":80},
	"guardian":{"name":"묘역 수호병","family":"undead","height":60,"stats":[170,16,85,75],"reach":80,"wind":0.95,"radius":90,"speed":75}}
static func kinds(): return ORIGINAL+NEW.keys()
static func family(kind): return "beast" if kind in ORIGINAL else NEW.get(kind,{}).get("family","")
static func can_tame(kind,player_class="druid"):
	return family(kind) in CLASS_FAMILIES.get(player_class,[])
static func name_of(kind):
	return {"boar":"멧돼지","marten":"담비","fox":"여우","turtle":"거북","deer":"사슴","wolf":"늑대"}.get(kind,NEW.get(kind,{}).get("name",kind))
static func condition(kind):
	if can_tame(kind): return "드루이드와 교감 가능"
	return "마물 계열의 계약이 필요" if family(kind)=="monster" else "언데드 계열의 인연이 필요"
