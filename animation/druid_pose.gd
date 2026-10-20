extends RefCounted
const Attack=preload("res://animation/druid_attack.gd")
# Shared body/weapon pose selection keeps the rigid weapon attached to its hand.
static var data={}
static func config():
	if data.is_empty() and FileAccess.file_exists("res://animation/druid-support.json"):
		data=JSON.parse_string(FileAccess.get_file_as_string("res://animation/druid-support.json"))
	return data
static func active_key(actor):
	if actor.hp<=0: return ""
	if Attack.active(actor): return "attack"
	if actor.get("channeling",false): return "revive"
	if actor.get("walk",false) or actor.get("pixel_moving",false): return ""
	var key=actor.get("action_key","")
	if key not in ["heal","support"] or actor.get("action_remaining",0.0)<=0: return ""
	var phase=1-actor.action_remaining/maxf(0.001,actor.get("action_duration",0.6))
	return key if phase<2.0/3.0 else ""
static func mount(actor):
	if Attack.active(actor): return Attack.mount(actor)
	var key=active_key(actor)
	var cfg=config()
	if not cfg.is_empty() and cfg.mounts.has(key): return Vector2(cfg.mounts[key][0],cfg.mounts[key][1])
	return Vector2(8,-36)
static func angle(actor):
	if Attack.active(actor): return Attack.angle(actor)
	var key=active_key(actor)
	return float(config().get("angles",{}).get(key,0.0))
