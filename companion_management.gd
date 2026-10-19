extends RefCounted
const Loot=preload("res://companion_loot.gd")
static func filtered(records,squad,kind="",grade="",favorites_only=false,order=0):
	var result=[]
	for record in records:
		if not kind.is_empty() and record.kind!=kind: continue
		if not grade.is_empty() and Loot.grade(record)!=grade: continue
		if favorites_only and not record.get("favorite",false): continue
		result.append(record)
	result.sort_custom(func(a,b):
		match order:
			0:
				var ai=squad.find(a.id)
				var bi=squad.find(b.id)
				ai=999 if ai<0 else ai
				bi=999 if bi<0 else bi
				if ai!=bi: return ai<bi
			1: return a.id>b.id
			2:
				var ar=Loot.GRADES.find(Loot.grade(a))
				var br=Loot.GRADES.find(Loot.grade(b))
				if ar!=br: return ar>br
				if a.level!=b.level: return a.level>b.level
			3:
				if a.level!=b.level: return a.level>b.level
		return a.id<b.id)
	return result
static func needed_xp(record): return int(record.level)*35
static func project(record,amount):
	var result=record.duplicate(true)
	result.xp+=maxi(0,int(amount))
	while result.xp>=needed_xp(result):
		result.xp-=needed_xp(result)
		result.level+=1
	return result
static func can_release(record,squad):
	return not record.is_empty() and not record.get("favorite",false) and not squad.has(record.id)

static func farewell_reward(record):
	# Level +1 adds one material; even one training charge costs three.
	# Thus training solely to cash out cannot return more than its material cost.
	return maxi(1,int(record.get("level",1)))+1+{"common":0,"rare":3,"epic":8}.get(Loot.grade(record),0)
static func target_plan(record,target):
	target=int(target)
	if record.is_empty() or target<=int(record.level) or target>int(record.level)+1000 or target>1000000: return {}
	var current=35*int(record.level)*(int(record.level)-1)/2+int(record.xp)
	var total=35*target*(target-1)/2
	var charges=ceili(maxf(0,total-current)/40.0)
	if charges<=0: return {}
	var projected=record.duplicate(true)
	projected.level=target
	projected.xp=int(current+charges*40-total)
	return {"target":target,"charges":charges,"cost":charges*3,"xp":charges*40,"before":record.duplicate(true),"after":projected}
