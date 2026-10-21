extends RefCounted
# Taming policy is independent of enemy AI and stage placement. No new player class is created here.
const CLASS_FAMILIES={"druid":["beast"],"contractor":["monster"],"necromancer":["undead"]}
const STARTERS={"druid":["boar","marten","fox"],"contractor":["slime"],"necromancer":["skeleton"]}
const FAMILIES={"beast":"야수","monster":"마물","undead":"언데드"}
const ORIGINAL=["boar","marten","fox","turtle","deer","wolf"]
const NEW={
	"bat":{"name":"동굴박쥐","family":"beast","height":32,"stats":[70,15,60,150],"reach":55,"wind":0.55,"radius":50,"speed":135},
	"slime":{"name":"이끼 슬라임","family":"monster","height":30,"stats":[65,8,50,70],"reach":50,"wind":0.75,"radius":60,"speed":68},
	"golem":{"name":"바위 마물","family":"monster","height":60,"stats":[160,15,90,65],"reach":85,"wind":1.05,"radius":95,"speed":65},
	"skeleton":{"name":"해골병","family":"undead","height":52,"stats":[70,10,55,95],"reach":55,"wind":0.65,"radius":60,"speed":95},
	"wraith":{"name":"묘역의 망령","family":"undead","height":50,"stats":[75,10,210,80],"reach":210,"wind":0.95,"radius":75,"speed":80},
	"thornling":{"name":"붉은가시 마물","family":"monster","height":46,"stats":[110,10,130,85],"reach":130,"wind":1.15,"radius":145,"speed":82},
	"shaman":{"name":"재의 주술사","family":"monster","height":54,"stats":[90,9,230,75],"reach":230,"wind":1.4,"radius":85,"speed":70},
	"sentinel":{"name":"황야 파수병","family":"monster","height":62,"stats":[185,16,95,72],"reach":95,"wind":1.2,"radius":105,"speed":70},
	"cycle_guardian":{"name":"순환의 수호자","family":"monster","height":66,"stats":[220,18,100,70],"reach":100,"wind":1.25,"radius":115,"speed":68},
	"guardian":{"name":"묘역 수호병","family":"undead","height":60,"stats":[170,16,85,75],"reach":80,"wind":0.95,"radius":90,"speed":75}}
static func kinds(): return ORIGINAL+NEW.keys()
static func starters(player_class): return STARTERS.get(player_class,[]).duplicate()
static func family(kind): return "beast" if kind in ORIGINAL else NEW.get(kind,{}).get("family","")
static func can_tame(kind,player_class="druid"):
	return family(kind) in CLASS_FAMILIES.get(player_class,[])
static func name_of(kind):
	return {"boar":"멧돼지","marten":"담비","fox":"여우","turtle":"거북","deer":"사슴","wolf":"늑대"}.get(kind,NEW.get(kind,{}).get("name",kind))
static func condition(kind,player_class="druid"):
	if can_tame(kind,player_class): return "드루이드와 교감 가능" if player_class=="druid" else "현재 계열로 인연 가능"
	return {"beast":"야수 계열의 인연이 필요","monster":"마물 계열의 인연이 필요","undead":"언데드 계열의 인연이 필요"}.get(family(kind),"알 수 없는 생물")
