extends RefCounted
# Eight independent encounters in the approved quarry backdrop; no new species IDs.
const STAGES=[
	{"name":"이끼 낀 운반로","story":"계곡의 돌조각이 운반로로 이어집니다. 모여든 슬라임을 흩뜨리세요.","ending":"운반로의 돌들은 물이 흐르던 수로에서 옮겨진 것입니다.","level":4,"packs":[["slime","slime"],["bat","slime"]],"crowds":[3,3],"points":[Vector2(650,830),Vector2(1140,760)],"exit":Vector2(1450,760)},
	{"name":"무너진 지지대","story":"바위 마물이 운반로를 막았습니다. 강타의 원을 벗어나 공격하세요.","ending":"무너진 지지대 안쪽에는 돌을 같은 곳으로 옮기라는 표식이 남아 있습니다.","level":4,"packs":[["slime","bat"],["golem","slime"],["slime","skeleton"]],"crowds":[2,2,2],"points":[Vector2(660,950),Vector2(1120,810),Vector2(1550,680)],"exit":Vector2(1850,680)},
	{"name":"박쥐의 굴","story":"굴 주변에 박쥐와 슬라임이 모였습니다. 교감할 야수와 적의 강타를 함께 살피세요.","ending":"박쥐들이 깊은 채굴터에서 되울리는 소리를 피해 밖으로 나옵니다.","level":5,"packs":[["bat","slime"],["golem","bat"],["slime","skeleton"]],"crowds":[3,2,3],"points":[Vector2(660,710),Vector2(1120,970),Vector2(1610,790)],"exit":Vector2(1920,790)},
	{"name":"균열의 공터","story":"균열 바위마물이 길을 지킵니다. 커다란 원형 강타를 피하고 빈틈을 노리세요.","ending":"바위마물 아래 드러난 수로가 채석장 깊은 곳을 향합니다.","level":5,"packs":[["slime","skeleton"],["golem"]],"crowds":[4,0],"points":[Vector2(680,820),Vector2(1280,810)],"exit":Vector2(1590,810),"boss":"균열 바위마물","boss_hp":900.0,"boss_level":5,"midboss":true},
	{"name":"말라붙은 수로","story":"수로를 따라 생물들이 모여듭니다. 강타와 근접 무리 사이의 안전한 자리를 찾으세요.","ending":"수로의 물은 사라진 것이 아니라 한곳으로 붙잡혀 있습니다.","level":6,"packs":[["skeleton","slime"],["golem","bat"],["slime","slime"]],"crowds":[2,3,4],"points":[Vector2(640,950),Vector2(1150,760),Vector2(1700,600)],"exit":Vector2(2000,600)},
	{"name":"되울리는 채굴장","story":"바위 마물 사이에서 박쥐들이 날아듭니다. 전열을 모아 범위 스킬로 길을 여세요.","ending":"돌지기는 누군가가 남긴 명령을 아직도 따르고 있습니다.","level":6,"packs":[["golem","slime"],["bat","skeleton"],["golem","slime"]],"crowds":[3,4,3],"points":[Vector2(670,730),Vector2(1160,920),Vector2(1720,790)],"exit":Vector2(2030,790)},
	{"name":"돌지기의 전열","story":"돌지기 앞 무리를 제압하세요. 쉼터에서 정비하고 마지막 길목으로 향하세요.","ending":"채굴터 중심의 돌지기가 끊어진 흐름을 붙잡고 있습니다.","level":7,"packs":[["slime","bat"],["golem","skeleton"],["slime","bat"],["golem","slime"]],"crowds":[3,4,4,2],"points":[Vector2(650,800),Vector2(1100,650),Vector2(1600,940),Vector2(2110,780)],"exit":Vector2(2420,780)},
	{"name":"멈춘 돌의 심장","story":"돌지기를 멈추세요. 주변 강타와 지정 위치 공격의 예고를 구분하세요.","ending":"돌지기가 멈추자 수로가 열립니다. 돌에 새겨진 문양은 잊힌 묘역의 묘문과 같습니다.","level":7,"packs":[["slime","skeleton"],["golem","bat"],["golem"]],"crowds":[4,5,0],"points":[Vector2(660,800),Vector2(1240,760),Vector2(1980,820)],"exit":Vector2(2320,820),"boss":"채석장의 돌지기","boss_hp":1600.0,"boss_level":8,"midboss":false}]
static func profile(stage):
	var p=STAGES[stage-1].duplicate(true)
	p.swarm_kind="slime"; p.damage_scale=1.0; p.swarm_damage_scale=1.0
	p.side_kinds=["bat","skeleton"]
	p.rest_name="채굴터 쉼터"; p.exit_name="채굴로 표식"; p.side_name="옆길 · 박쥐와 해골병"
	p.boss_hint="원형 강타 밖으로 이동하세요." if p.get("midboss",false) else "주변 강타와 지정 위치의 공격 예고를 살피세요."
	return p
