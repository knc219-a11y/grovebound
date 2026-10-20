extends RefCounted
const STAGES=[
	{"name":"무너진 묘문","story":"돌지기의 문양이 묘문에도 남았습니다. 해골 전열을 넘어 흔적을 찾으세요.","ending":"묘문 안에서는 죽은 자들이 아직 같은 길을 맴돕니다.","level":8,"packs":[["skeleton","slime"],["skeleton","bat"]],"crowds":[3,3],"points":[Vector2(650,810),Vector2(1160,750)],"exit":Vector2(1470,750)},
	{"name":"망령의 길목","story":"해골 뒤의 망령이 땅을 겨눕니다. 표시된 자리를 벗어나 후열로 접근하세요.","ending":"망령들은 공격하면서도 길이 닫혔다는 말을 되풀이합니다.","level":8,"packs":[["skeleton","wraith"],["skeleton","slime"],["bat","wraith"]],"crowds":[2,2,2],"points":[Vector2(660,930),Vector2(1140,780),Vector2(1630,640)],"exit":Vector2(1950,640)},
	{"name":"비석 사이 우회","story":"수호병이 망령을 지킵니다. 열린 옆 공간을 이용해 전열을 돌아가세요.","ending":"비석의 이름은 지워졌지만 수호자의 명령은 남아 있습니다.","level":9,"packs":[["guardian","skeleton"],["skeleton","wraith"],["bat","slime"]],"crowds":[2,3,3],"points":[Vector2(650,700),Vector2(1180,940),Vector2(1700,780)],"exit":Vector2(2030,780)},
	{"name":"종지기의 뜰","story":"종지기가 발밑을 겨눕니다. 공격이 고정된 뒤 움직여 안전한 자리를 찾으세요.","ending":"종지기는 영혼들을 놓아주고 싶지만 돌아갈 흐름이 없다고 말합니다.","level":9,"packs":[["skeleton","slime"],["wraith"]],"crowds":[4,0],"points":[Vector2(680,820),Vector2(1300,810)],"exit":Vector2(1620,810),"boss":"묘역의 종지기","boss_hp":1300.0,"boss_level":9,"midboss":true,"boss_pattern":"hex"},
	{"name":"머무는 영혼","story":"망령과 수호병이 물러서지 않습니다. 강타와 표적 예고를 번갈아 피하세요.","ending":"영혼들은 살아 있는 이들을 지키려 이곳에 붙잡혔습니다.","level":10,"packs":[["skeleton","wraith"],["guardian","slime"],["skeleton","bat"]],"crowds":[3,3,3],"points":[Vector2(650,950),Vector2(1180,770),Vector2(1740,600)],"exit":Vector2(2060,600)},
	{"name":"수호자의 기억","story":"수호병 옆을 돌아 망령을 압박하세요. 비석에 남은 기억을 따라가세요.","ending":"죽음을 멈추면 모두를 지킬 수 있다는 수호자의 목소리가 들려옵니다.","level":10,"packs":[["guardian","wraith"],["bat","slime"],["skeleton","wraith"]],"crowds":[3,2,3],"points":[Vector2(660,720),Vector2(1180,940),Vector2(1740,790)],"exit":Vector2(2060,790)},
	{"name":"문지기의 전열","story":"전열과 후열을 나누어 공략하세요. 마지막 길목 전에 쉼터에서 정비하세요.","ending":"문지기는 죽은 자를 지키는 것이 아니라 떠나지 못하게 붙잡고 있습니다.","level":11,"packs":[["skeleton","wraith"],["guardian","slime"],["skeleton","bat"],["skeleton","wraith"]],"crowds":[2,3,2,1],"points":[Vector2(650,800),Vector2(1120,640),Vector2(1650,940),Vector2(2190,790)],"exit":Vector2(2500,790)},
	{"name":"돌아가지 못한 문","story":"문지기를 멈추고 영혼의 길을 여세요. 강타와 고정 표적의 원을 구분하세요.","ending":"영혼의 길이 열립니다. 순환을 멈춘 수호자를 찾아 붉은바람 너머로 향합니다.","level":11,"packs":[["skeleton","slime"],["guardian","wraith"],["guardian"]],"crowds":[3,4,0],"points":[Vector2(650,800),Vector2(1250,760),Vector2(2020,820)],"exit":Vector2(2350,820),"boss":"묘역의 문지기","boss_hp":2400.0,"boss_level":12,"midboss":false}]
static func profile(stage):
	var p=STAGES[stage-1].duplicate(true)
	p.swarm_kind="skeleton"; p.damage_scale=1.0; p.swarm_damage_scale=1.0; p.rear_support=true
	p.side_kinds=["wolf","slime"]
	p.rest_name="옛 묘지기 쉼터"; p.exit_name="영혼길 표식"; p.side_name="옆길 · 늑대와 슬라임"
	p.boss_hint="표적이 고정되면 원 밖으로 이동하세요." if p.get("midboss",false) else "주변 강타와 고정 표적을 구분하세요."
	return p
