extends RefCounted
# Hero progression is separate from companion growth and its random stream.
const CAP=30
const SLOTS=["weapon","armor","charm1","charm2"]
const SKILLS=["heal","buff","revive","barrier"]
const NAMES={"heal":"회복","buff":"야성 강화","revive":"소생","barrier":"숲의 보호"}
const CATALOG={
	"twig_staff":{"name":"새싹 지팡이","slot":"weapon","level":1,"price":120,"attack":2.0,"support":3.0},
	"oak_staff":{"name":"참나무 지팡이","slot":"weapon","level":8,"price":450,"attack":4.0,"support":8.0},
	"grove_staff":{"name":"숲지기 지팡이","slot":"weapon","level":18,"price":1200,"attack":6.0,"support":14.0},
	"woven_robe":{"name":"직조 로브","slot":"armor","level":1,"price":100,"hp":25.0,"defense":3.0},
	"bark_robe":{"name":"나무껍질 로브","slot":"armor","level":8,"price":400,"hp":50.0,"defense":6.0},
	"guardian_robe":{"name":"수호자 로브","slot":"armor","level":18,"price":1100,"hp":80.0,"defense":10.0},
	"vitality_charm":{"name":"생명의 부적","slot":"charm","level":1,"price":160,"hp":20.0},
	"stream_charm":{"name":"시냇물 부적","slot":"charm","level":8,"price":500,"haste":0.04,"support":3.0},
	"wind_charm":{"name":"바람 부적","slot":"charm","level":18,"price":1000,"haste":0.07,"defense":3.0}}
static func fresh():
	return {"version":1,"gold":0,"level":1,"xp":0,"items":[],"equipped":{"weapon":0,"armor":0,"charm1":0,"charm2":0},"next_item_id":1,"skills":{"heal":1,"buff":1,"revive":1,"barrier":0},"rng_state":""}
static func whole(v,lo,hi):
	return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=lo and v<=hi
static func valid(p):
	if not p is Dictionary: return false
	var base=fresh()
	for k in base:
		if not p.has(k): return false
	if not whole(p.version,1,1) or not whole(p.gold,0,2000000000) or not whole(p.level,1,CAP) or not whole(p.xp,0,100*p.level-1) or not whole(p.next_item_id,1,2000000000): return false
	if p.level==CAP and p.xp!=0: return false
	if not p.items is Array or not p.equipped is Dictionary or not p.skills is Dictionary or not p.rng_state is String: return false
	if not p.rng_state.is_empty() and not p.rng_state.is_valid_int(): return false
	var ids=[]
	for item in p.items:
		if not item is Dictionary or not item.has_all(["id","catalog","enhance"]) or not CATALOG.has(item.catalog): return false
		if not whole(item.id,1,p.next_item_id-1) or item.id in ids or not whole(item.enhance,0,5): return false
		ids.append(item.id)
	var worn=[]
	for slot in SLOTS:
		if not p.equipped.has(slot) or not whole(p.equipped[slot],0,p.next_item_id-1): return false
		var id=p.equipped[slot]
		if id==0: continue
		var item=find(p,id)
		if item.is_empty() or id in worn or not fits(item,slot) or CATALOG[item.catalog].level>p.level: return false
		worn.append(id)
	for key in SKILLS:
		if not p.skills.has(key) or not whole(p.skills[key],0 if key=="barrier" else 1,5): return false
		if p.skills[key]>0 and p.level<(8 if key=="barrier" else 1)+4*(p.skills[key]-1): return false
	return true
static func find(p,id):
	for item in p.items:
		if item.id==id: return item
	return {}
static func fits(item,slot):
	return CATALOG[item.catalog].slot==("charm" if slot.begins_with("charm") else slot)
static func title(item):
	return CATALOG[item.catalog].name+" +%d" % item.enhance
static func base_stats(p):
	return {"hp":180.0+8*(p.level-1),"attack":6.0+0.3*(p.level-1),"defense":0.2*(p.level-1),"support":float(p.level-1),"haste":0.0}
static func item_stats(item):
	var result={}
	for key in ["hp","attack","defense","support","haste"]: result[key]=CATALOG[item.catalog].get(key,0.0)*(1.0+0.15*item.enhance)
	return result
static func stats(p):
	var result=base_stats(p)
	for slot in SLOTS:
		var item=find(p,p.equipped[slot])
		if item.is_empty(): continue
		var bonus=item_stats(item)
		for key in bonus: result[key]+=bonus[key]
	result.haste=minf(0.30,result.haste)
	return result
static func add_item(p,key):
	var item={"id":p.next_item_id,"catalog":key,"enhance":0}
	p.next_item_id+=1
	p.items.append(item)
	return item
static func reward(p,enemy_level,boss=false):
	var next=p.duplicate(true)
	next.gold=mini(2000000000,next.gold+(5+2*enemy_level)*(5 if boss else 1))
	if next.level<CAP:
		next.xp+=12+4*enemy_level
		while next.level<CAP and next.xp>=next.level*100:
			next.xp-=next.level*100
			next.level+=1
		if next.level==CAP: next.xp=0
	var random=RandomNumberGenerator.new()
	if next.rng_state.is_empty(): random.seed=20261021
	else: random.state=next.rng_state.to_int()
	var drop=random.randf()<0.08 or boss
	if drop:
		var pool=CATALOG.keys().filter(func(k): return CATALOG[k].level<=enemy_level)
		if not pool.is_empty(): add_item(next,pool[random.randi_range(0,pool.size()-1)])
	next.rng_state=str(random.state)
	return next
static func skill(p,key):
	var rank=int(p.skills[key])
	var extra=maxi(0,rank-1)
	var s=stats(p)
	match key:
		"heal": return {"rank":rank,"amount":(55.0+5*extra)*(1+s.support/100.0),"cooldown":(8.0-0.25*extra)*(1-s.haste)}
		"buff": return {"rank":rank,"power":0.60+0.03*extra,"duration":7.0+0.5*extra,"cooldown":(14.0-0.5*extra)*(1-s.haste)}
		"revive": return {"rank":rank,"seconds":3.0-0.2*extra,"ratio":0.30+0.025*extra}
	return {"rank":rank,"ratio":0.08+0.02*extra,"seconds":4.0,"cooldown":18.0*(1-s.haste)}
static func skill_text(p,key):
	var s=skill(p,key)
	match key:
		"heal": return "체력이 낮은 아군 회복 %.1f · 재사용 %.1f초" % [s.amount,s.cooldown]
		"buff": return "아군 1명 공격 +%d%% · %.1f초 · 재사용 %.1f초" % [roundi(s.power*100),s.duration,s.cooldown]
		"revive": return "%.1f초 집중 · 체력 %d%%로 소생" % [s.seconds,roundi(s.ratio*100)]
	return "주변 아군 보호막 %d%% · 4초 · 재사용 %.1f초" % [roundi(s.ratio*100),s.cooldown]
static func plan(p,action,arg):
	var next=p.duplicate(true)
	var cost=0
	var error=""
	match action:
		"buy":
			if not CATALOG.has(arg): error="알 수 없는 장비입니다."
			elif p.level<CATALOG[arg].level: error="주인공 레벨이 부족합니다."
			else: cost=CATALOG[arg].price; add_item(next,arg)
		"skill":
			if arg not in SKILLS: error="알 수 없는 스킬입니다."
			else:
				var rank=p.skills[arg]
				if rank>=5: error="최대 단계입니다."
				elif p.level<(8 if arg=="barrier" else 1)+4*rank: error="주인공 레벨 %d 필요" % ((8 if arg=="barrier" else 1)+4*rank)
				else: cost=75*(rank+1); next.skills[arg]+=1
		"unequip":
			if arg not in SLOTS: error="장착 칸이 올바르지 않습니다."
			else: next.equipped[arg]=0
		"equip","sell","enhance":
			var item=find(next,arg.id if arg is Dictionary else arg)
			if item.is_empty(): error="장비가 없습니다."
			elif action=="equip":
				if arg.slot not in SLOTS or not fits(item,arg.slot): error="장착 칸이 맞지 않습니다."
				elif CATALOG[item.catalog].level>p.level: error="주인공 레벨이 부족합니다."
				else:
					for slot in SLOTS:
						if next.equipped[slot]==item.id: next.equipped[slot]=0
					next.equipped[arg.slot]=item.id
			elif action=="sell":
				if item.id in next.equipped.values(): error="장착 중인 장비는 해제 후 판매하세요."
				else: next.gold=mini(2000000000,next.gold+int(CATALOG[item.catalog].price/4)); next.items.erase(item)
			elif item.enhance>=5: error="최대 강화입니다."
			else: cost=int(CATALOG[item.catalog].price/2)*(item.enhance+1); item.enhance+=1
		_: error="알 수 없는 작업입니다."
	if cost>p.gold: error="골드가 부족합니다."
	next.gold-=cost
	return {"after":next,"cost":cost,"error":error}
