extends RefCounted
const Save=preload("res://save_data.gd")
const Species=preload("res://creature_species.gd")
const STAGES={
	1:{"name":"초록물 계곡","theme":"야수 중심 · 세 계열 첫 만남 · 무리 제압","level":1,"background":"res://assets/maps/greenwater-beginner-v3.webp","boss":"계곡의 우두머리","boss_kind":"boar","boss_hp":850.0,
		"kinds":["boar","slime","deer","fox","marten","wolf"],"escorts":["boar","skeleton","turtle","wolf","skeleton","slime"],"swarm":"boar"},
	2:{"name":"버려진 채석장","theme":"슬라임 무리 · 바위 강타 · 박쥐와 교감","level":3,"background":"res://assets/campaign/quarry-v1.webp","boss":"채석장의 돌지기","boss_kind":"golem","boss_hp":1050.0,
		"kinds":["slime","golem","bat","slime","slime","golem"],"escorts":["slime","slime","skeleton","bat","skeleton","slime"],"swarm":"slime",
		"names":["이끼 낀 입구","운반로","굴 입구","갈라진 채굴터","바위 그늘","돌지기 앞마당"],"hints":["슬라임을 모아 한 번에","바위 강타의 원을 피하세요","박쥐와 해골병이 머무는 옆길","슬라임 무리 속 박쥐와 교감 기회","슬라임과 해골병을 만나는 옆길","무리 제압과 강타 회피"]},
	3:{"name":"잊힌 묘역","theme":"해골 전열 · 원거리 망령 · 수호병의 예고","level":5,"background":"res://assets/campaign/graveyard-v1.webp","boss":"묘역의 문지기","boss_kind":"guardian","boss_hp":1250.0,
		"kinds":["skeleton","wraith","wolf","skeleton","wraith","guardian"],"escorts":["skeleton","slime","skeleton","bat","slime","wraith"],"swarm":"skeleton",
		"names":["무너진 묘문","망령의 길목","야수의 은신처","비석 사이 공터","검은 나뭇가지","문지기 전열"],"hints":["해골 무리를 범위로 제압","소규모 전투에서 지면 예고 회피","늑대와 해골병을 만나는 옆길","해골 전열 속 박쥐와 교감 기회","망령과 슬라임이 머무는 옆길","전열 옆으로 돌아 뒤의 망령부터"]}}
static func reward_kinds(id):
	var stage=STAGES[id]
	var result=[]
	for pack in stage.kinds.size():
		result.append(stage.kinds[pack])
		if pack>0: result.append(stage.escorts[pack])
	return result
static func tamable_kinds(id,player_class):
	var result=[]
	for kind in reward_kinds(id):
		if Species.can_tame(kind,player_class) and kind not in result: result.append(kind)
	return result
static func habitats(kind):
	var result=[]
	for id in STAGES:
		if kind in reward_kinds(id): result.append(STAGES[id].name)
	return result
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
		var level=1+int(pack/2) if id==1 else id+int(pack/3)
		g.spawn_enemy(stage.kinds[pack],g.Trail.PACKS[pack],level)
		g.enemies[-1].pack=pack
		if id==1: g.enemies[-1].damage_scale=0.8
		if pack>0:
			var offset=Vector2(115,-65) if stage.escorts[pack]=="wraith" else Vector2(-70,25) if stage.kinds[pack]=="wraith" else g.Trail.escort_offset(pack)
			g.spawn_enemy(stage.escorts[pack],g.Trail.PACKS[pack]+offset,level)
			g.enemies[-1].pack=pack
			if id==1: g.enemies[-1].damage_scale=0.8
	for pack in [0,3,5]:
		var amount=g.Trail.FOLLOWERS[pack] if id==1 else {0:4,3:6,5:8}[pack]
		for j in amount:
			var offset=g.Trail.follower_offsets(pack)[j] if id==1 else g.Trail.FOLLOWER_OFFSETS[j%7]+Vector2(38 if j>=7 else 0,-25 if j>=7 else 0)
			var kind="wolf" if id==1 and pack==5 else stage.swarm
			g.spawn_enemy(kind,g.Trail.PACKS[pack]+offset,1+int(pack/2) if id==1 else id+int(pack/3))
			var e=g.enemies[-1]
			e.pack=pack; e.swarm=true; e.swarm_damage=1.6/amount
			# Introductory crowds retain their count/rewards, with less simultaneous pressure.
			if id==1: e.damage_scale=0.5
			e.hp*=0.28; e.maxhp=e.hp
	g.spawn_enemy(stage.boss_kind,Vector2(2590,850),4 if id==1 else id+2,true)
	g.enemies[-1].hp=stage.boss_hp; g.enemies[-1].maxhp=stage.boss_hp
	g.enemies[-1].stage_entry=true
