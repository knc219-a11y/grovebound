extends "res://animation/pixel_gameplay_preview.gd"
@export var region=2
@export var view="battle"
var review_clock=0.0
var casts=0
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","fox","deer","turtle"]:
		var level=3 if region==2 else 5
		var d=make_owned(kind,level,{"kind":kind,"level":level,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	cleared_stages=[1,2]
	if view=="selector":
		expedition.clear(); show_camp(); open_stage_select()
		return
	start_stage(false,region)
	player.pos=Vector2(1260,820)
	for i in units.size(): units[i].pos=player.pos+Vector2(90-i*20,i*25-25)
	# Isolated production encounter for animation/AI QA; not an entire stage clear.
	enemies=enemies.filter(func(e): return e.get("pack",-1)==3 or e.boss)
	if view=="layout": screenshot_mode=true
	elif view=="boss":
		for e in enemies:
			if not e.boss: e.hp=0
		player.pos=Vector2(2360,850)
		for i in units.size(): units[i].pos=player.pos+Vector2(-55-i*15,30)
	elif view=="collection":
		seen_species=Species.kinds()
		open_collection()
		overlay.get_node("CreatureCollection").set_deferred("scroll_vertical",10000)
	message=""; message_time=0
func _process(dt):
	review_clock+=dt
	if view=="battle":
		if review_clock>0.8 and casts==0: casts=1; use_companion_skill(0)
		elif review_clock>1.5 and casts==1: casts=2; use_companion_skill(1)
	elif view=="boss" and review_clock>1.6:
		for i in active_units().size(): use_companion_skill(i)
		cast_heal()
	super(dt)
