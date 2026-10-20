extends RefCounted
const Save=preload("res://save_data.gd")
const STAGES={
	1:{"name":"초록물 계곡","theme":"야수와 첫 인연 · 돌진과 범위 제압","level":1,"background":"res://assets/maps/greenwater-beginner-v3.webp","boss":"계곡의 우두머리"},
	2:{"name":"버려진 채석장","theme":"슬라임 무리 · 바위 강타 · 박쥐와 교감","level":3,"background":"res://assets/campaign/quarry-v1.webp","boss":"채석장의 돌지기","boss_kind":"golem","boss_hp":1050.0,
		"kinds":["slime","golem","bat","slime","bat","golem"],"escorts":["slime","slime","bat","golem","bat","slime"],"swarm":"slime",
		"names":["이끼 낀 입구","운반로","굴 입구","갈라진 채굴터","바위 그늘","돌지기 앞마당"],"hints":["슬라임을 모아 한 번에","바위 강타의 원을 피하세요","박쥐와 교감할 기회","전열을 정리하고 큰 적 집중","드루이드와 인연을 맺는 야수","스킬을 모아 앞마당 제압"]},
	3:{"name":"잊힌 묘역","theme":"해골 전열 · 원거리 망령 · 수호병의 예고","level":5,"background":"res://assets/campaign/graveyard-v1.webp","boss":"묘역의 문지기","boss_kind":"guardian","boss_hp":1250.0,
		"kinds":["skeleton","wraith","wolf","skeleton","bat","guardian"],"escorts":["skeleton","skeleton","wolf","wraith","bat","skeleton"],"swarm":"skeleton",
		"names":["무너진 묘문","망령의 길목","야수의 은신처","비석 사이 공터","검은 나뭇가지","문지기 전열"],"hints":["해골 무리를 범위로 제압","지면의 저주 예고를 피하세요","살아 있는 야수와 교감","뒤의 망령부터 정리","박쥐가 머무는 선택 길","전열을 정리한 뒤 공터 진입"]}}
static func accessible(id,cleared): return STAGES.has(id) and (id==1 or id-1 in cleared)
static func progress(data):
	var raw=data.get("cleared_stages",[])
	var result=[]
	if data.get("unlocked",false)==true: result.append(1)
	if raw is Array:
		var ids=[]
		for value in raw:
			var parsed=Save.id_value(value)
			if parsed in [1,2,3]: ids.append(parsed)
		for id in [1,2,3]:
			if id in ids and (id==1 or id-1 in result) and id not in result: result.append(id)
	result.sort()
	return result
static func populate(g,id):
	var stage=STAGES[id]
	for pack in g.Trail.PACKS.size():
		var level=id+int(pack/3)
		g.spawn_enemy(stage.kinds[pack],g.Trail.PACKS[pack],level)
		g.enemies[-1].pack=pack
		if pack>0:
			var offset=Vector2(115,-65) if stage.escorts[pack]=="wraith" else Vector2(-70,25) if stage.kinds[pack]=="wraith" else g.Trail.escort_offset(pack)
			g.spawn_enemy(stage.escorts[pack],g.Trail.PACKS[pack]+offset,level)
			g.enemies[-1].pack=pack
	for pack in [0,3,5]:
		var amount={0:4,3:6,5:8}[pack]
		for j in amount:
			var offset=g.Trail.FOLLOWER_OFFSETS[j%7]+Vector2(38 if j>=7 else 0,-25 if j>=7 else 0)
			g.spawn_enemy(stage.swarm,g.Trail.PACKS[pack]+offset,id+int(pack/3))
			var e=g.enemies[-1]
			e.pack=pack; e.swarm=true; e.swarm_damage=1.6/amount
			e.hp*=0.28; e.maxhp=e.hp
	g.spawn_enemy(stage.boss_kind,Vector2(2590,850),id+2,true)
	g.enemies[-1].hp=stage.boss_hp; g.enemies[-1].maxhp=stage.boss_hp
	g.enemies[-1].stage_entry=true
