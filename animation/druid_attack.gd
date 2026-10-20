extends RefCounted
# Visual anticipation follows the existing auto-attack cooldown. Damage stays immediate.
const DURATION=0.52
const IMPACT=0.14
const TIMES=[0.0,0.04,0.09,0.14,0.195,0.26,0.33,0.41]
static var config={}
static func data():
	if config.is_empty() and FileAccess.file_exists("res://animation/druid-attack.json"):
		config=JSON.parse_string(FileAccess.get_file_as_string("res://animation/druid-attack.json"))
	return config
static func active(actor):
	return actor.get("hp",0)>0 and not actor.get("walk",false) and not actor.get("pixel_moving",false) and not actor.get("channeling",false) and actor.get("action_key","")=="attack" and actor.get("action_remaining",0.0)>0
static func frame(actor):
	var elapsed=DURATION-actor.get("action_remaining",0.0)
	var index=0
	for i in TIMES.size():
		if elapsed+0.00001>=TIMES[i]: index=i
	return index
static func start(actor,until_hit=0.0):
	if actor.hp<=0 or actor.get("channeling",false): return false
	if actor.get("action_remaining",0.0)>0 and actor.get("action_key","") in ["heal","support","revive"]: return false
	actor.action_key="attack"
	actor.action_face=actor.get("face",1.0)
	actor.action_duration=DURATION
	actor.action_remaining=DURATION-IMPACT+clampf(until_hit,0,IMPACT)
	return true
static func mount(actor):
	var point=data().mounts[frame(actor)]
	return Vector2(point[0],point[1])
static func angle(actor):
	var index=frame(actor)
	var elapsed=DURATION-actor.action_remaining
	var next=mini(index+1,7)
	var end=TIMES[next] if next!=index else DURATION
	var t=smoothstep(TIMES[index],end,elapsed)
	return lerpf(data().angles[index],data().angles[next],t)
