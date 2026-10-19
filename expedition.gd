extends RefCounted
# Session-only ledger: reads snapshots; never grants rewards or edits a save.
var active=false
var baseline={}
var report={}
var joined={}
static func lifetime_xp(d):
	var level=int(d.get("level",1))
	return 35*level*(level-1)/2+int(d.get("xp",0))
func begin(owned,materials,tutorial):
	active=true
	joined.clear()
	baseline={"owned":owned.duplicate(true),"materials":materials,"tutorial":tutorial}
func record_bond(d):
	if active: joined[d.id]=d.duplicate(true)
func close(owned,materials,kills,seconds,outcome):
	if not active: return false
	active=false
	var before={}
	for d in baseline.owned: before[d.id]=d
	var newcomers=[]
	var growth=[]
	for d in owned:
		if not before.has(d.id):
			newcomers.append(d.duplicate(true))
		var old=before.get(d.id,joined.get(d.id,{}))
		if old.is_empty(): continue
		var delta=int(lifetime_xp(d)-lifetime_xp(old))
		if delta>0: growth.append({"id":d.id,"kind":d.kind,"from":old.level,"to":d.level,"xp":delta})
	report={"outcome":outcome,"newcomers":newcomers,"growth":growth,"materials":materials-int(baseline.materials),"kills":kills,"seconds":int(seconds),"tutorial":baseline.tutorial}
	return true
func clear():
	active=false
	joined.clear()
	baseline.clear()
	report.clear()
