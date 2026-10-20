extends RefCounted
# Separate identifiers keep legacy region IDs from becoming stage numbers.
const Save=preload("res://save_data.gd")
const Legacy=preload("res://campaign.gd")
const DIFFICULTIES=["normal","depth","challenge"]
const DIFFICULTY_NAMES={"normal":"일반","depth":"심층","challenge":"도전"}
const THEMES={1:"초록물 계곡",2:"버려진 채석장",3:"잊힌 묘역",4:"붉은바람 황야",5:"검은성채"}
const VALLEY=[
	{"name":"흉포한 발자국","story":"평온하던 계곡에서 짐승들이 길을 막습니다. 흔적을 따라가세요.","ending":"짓밟힌 풀밭 너머로 흉포한 발자국이 이어집니다.","level":1,"packs":[["boar"],["marten","boar"]],"crowds":[2,1],"points":[Vector2(650,790),Vector2(1050,760)],"exit":Vector2(1330,760)},
	{"name":"두 갈래 물길","story":"물길 주변에 낯선 생물들이 모였습니다. 전열을 모아 길을 여세요.","ending":"야수뿐 아니라 마물과 죽은 자도 물길 주변을 맴돕니다.","level":1,"packs":[["slime","skeleton"],["fox","boar"]],"crowds":[1,3],"points":[Vector2(670,900),Vector2(1170,720)],"exit":Vector2(1450,720)},
	{"name":"풀밭의 집결","story":"늑대들이 작은 야수들을 몰고 있습니다. 동료의 범위 스킬을 활용하세요.","ending":"무리는 샘을 등진 채 달려왔습니다. 샘 위쪽에서 둔탁한 소리가 납니다.","level":2,"packs":[["wolf","boar"],["fox","wolf"],["slime"]],"crowds":[3,4,0],"points":[Vector2(680,750),Vector2(1160,870),Vector2(1510,710)],"exit":Vector2(1780,710)},
	{"name":"가시등의 공터","story":"가시등 멧돼지가 샘으로 가는 길을 지킵니다. 발구르기 예고를 살피세요.","ending":"가시등이 물러난 자리에서 말라붙은 물길이 드러납니다.","level":2,"packs":[["boar","skeleton"],["boar"]],"crowds":[2,0],"points":[Vector2(680,800),Vector2(1220,800)],"exit":Vector2(1500,800),"boss":"가시등 멧돼지","boss_hp":450.0,"midboss":true},
	{"name":"메마른 샛물","story":"물길이 막혀 있습니다. 주변 생물들을 진정시키고 샘으로 향하세요.","ending":"막힌 곳은 자연스럽게 무너진 흔적과 다릅니다. 흐름이 안쪽에서 멎었습니다.","level":2,"packs":[["slime","boar"],["skeleton","marten"],["wolf"]],"crowds":[1,2,2],"points":[Vector2(650,970),Vector2(1110,800),Vector2(1540,610)],"exit":Vector2(1820,610)},
	{"name":"이방인의 흔적","story":"해골병과 슬라임이 야수 사이에 섞였습니다. 서로 다른 공격 거리에 대응하세요.","ending":"채석장에서 흘러온 돌조각이 물길에 박혀 있습니다.","level":3,"packs":[["skeleton","slime"],["fox","wolf"],["slime","boar"]],"crowds":[2,3,2],"points":[Vector2(660,700),Vector2(1120,920),Vector2(1630,800)],"exit":Vector2(1910,800)},
	{"name":"샘으로 가는 길","story":"샘 앞에 모인 무리를 흩뜨리세요. 공터의 쉼터에서 동료를 정비할 수 있습니다.","ending":"샘을 막은 바위 곁에서 계곡의 우두머리가 울부짖습니다.","level":3,"packs":[["wolf","slime"],["boar","fox"],["wolf","skeleton"],["boar"]],"crowds":[2,3,4,0],"points":[Vector2(650,800),Vector2(1080,680),Vector2(1580,880),Vector2(2000,750)],"exit":Vector2(2260,750)},
	{"name":"초록물의 샘","story":"계곡의 우두머리를 진정시키고 샘의 흐름을 여세요. 발구르기 뒤 돌진에 주의하세요.","ending":"샘물이 다시 흐릅니다. 그러나 물길 끝의 채석장에서는 대답 없는 울림이 이어집니다.","level":3,"packs":[["slime","skeleton"],["wolf","boar"],["boar"]],"crowds":[2,4,0],"points":[Vector2(650,800),Vector2(1250,790),Vector2(1930,820)],"exit":Vector2(2250,820),"boss":"계곡의 우두머리","boss_hp":850.0,"midboss":false}]
static func coordinate(theme,stage,difficulty="normal"):
	return {"difficulty":difficulty,"theme":theme,"stage":stage}
static func valid(c):
	return c is Dictionary and c.get("difficulty","") in DIFFICULTIES and Save.id_value(c.get("theme",0)) in range(1,6) and Save.id_value(c.get("stage",0)) in range(1,9)
static func key(c):
	return "%s:%d:%d" % [c.difficulty,int(c.theme),int(c.stage)] if valid(c) else ""
static func implemented(c):
	return valid(c) and c.difficulty=="normal" and int(c.theme)==1
static func title(c):
	if not valid(c): return "탐험 지도"
	return "%s %d-%d · %s" % [DIFFICULTY_NAMES[c.difficulty],int(c.theme),int(c.stage),VALLEY[int(c.stage)-1].name if int(c.theme)==1 else THEMES[int(c.theme)]]
static func profile(c):
	return VALLEY[int(c.stage)-1].duplicate(true) if implemented(c) else {}
static func migrated(legacy):
	var result={"version":1,"cleared":[]}
	for theme in Legacy.progress(legacy):
		for stage in range(1,9): result.cleared.append(coordinate(theme,stage))
	return result
static func normalize(data):
	if not data.has("campaign_progress"): return migrated(data)
	var result={"version":1,"cleared":[]}
	var source=data.get("campaign_progress")
	if not source is Dictionary or Save.id_value(source.get("version",0))!=1 or not source.get("cleared",[]) is Array: return result
	var keys={}
	for c in source.get("cleared",[]):
		if valid(c): keys[key(c)]=true
	for difficulty in DIFFICULTIES:
		if difficulty!="normal" and not contains(result,coordinate(5,8,DIFFICULTIES[DIFFICULTIES.find(difficulty)-1])): break
		for theme in range(1,6):
			for stage in range(1,9):
				var c=coordinate(theme,stage,difficulty)
				if not keys.has(key(c)): break
				result.cleared.append(c)
			if not contains(result,coordinate(theme,8,difficulty)): break
	return result
static func contains(progress,c):
	for saved in progress.get("cleared",[]):
		if key(saved)==key(c) and not key(c).is_empty(): return true
	return false
static func available(c,progress):
	if not implemented(c): return false
	return int(c.stage)==1 or contains(progress,coordinate(1,int(c.stage)-1,c.difficulty))
static func completed(progress,c):
	var result=progress.duplicate(true)
	if not contains(result,c): result.cleared.append(c.duplicate(true))
	return normalize({"campaign_progress":result})
static func next(c):
	if not valid(c): return {}
	return coordinate(int(c.theme),int(c.stage)+1,c.difficulty) if int(c.stage)<8 else coordinate(int(c.theme)+1,1,c.difficulty) if int(c.theme)<5 else coordinate(1,1,DIFFICULTIES[DIFFICULTIES.find(c.difficulty)+1]) if c.difficulty!="challenge" else {}
static func progress_for(g):
	return g.campaign_progress if not g.campaign_progress.is_empty() else migrated({"cleared_stages":g.cleared_stages,"unlocked":g.unlocked})
static func populate(g,c):
	var p=profile(c)
	for pack in p.packs.size():
		for index in p.packs[pack].size():
			var terminal=p.has("boss") and pack==p.packs.size()-1
			g.spawn_enemy(p.packs[pack][index],p.points[pack]+Vector2(index*65,index*30),4 if terminal and not p.get("midboss",false) else p.level,terminal)
			var e=g.enemies[-1]
			e.pack=pack; e.damage_scale=0.8 if not terminal else 0.8 if p.get("midboss",false) else 1.0
			if terminal:
				e.hp=p.boss_hp; e.maxhp=e.hp; e.stage_entry=true; e.route_mid=p.get("midboss",false)
		for index in p.crowds[pack]:
			g.spawn_enemy("wolf" if int(c.stage)>=3 else "boar",p.points[pack]+Vector2(-65+index*38,45 if index%2 else -45),p.level)
			var e=g.enemies[-1]
			e.pack=pack; e.swarm=true; e.swarm_damage=1.6/p.crowds[pack]; e.damage_scale=0.5
			e.hp*=0.28; e.maxhp=e.hp
	# Side encounters retain two optional opportunities without blocking completion.
	for index in 2:
		g.spawn_enemy("deer" if index==0 else "turtle",g.trail.side+Vector2(index*65,25*index),p.level)
		g.enemies[-1].pack=8; g.enemies[-1].damage_scale=0.8
static func rewards(c):
	var p=profile(c)
	if p.is_empty(): return {}
	var xp=0
	var materials=0
	for pack in p.packs.size():
		var boss=p.has("boss") and pack==p.packs.size()-1
		for kind in p.packs[pack]:
			xp+=12+(4 if boss and not p.get("midboss",false) else p.level)*4
			materials+=5 if boss else 1
	return {"xp":xp,"materials":materials+10,"bonus":10,"optional_xp":2*(12+p.level*4),"optional_materials":2}
