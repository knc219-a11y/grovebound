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
