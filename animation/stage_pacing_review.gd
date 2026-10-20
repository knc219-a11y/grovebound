extends "res://animation/pixel_gameplay_preview.gd"
@export var view="battle"
var review_clock=0.0
var review_casts=0
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","fox","deer","turtle"]:
		var d=make_owned(kind,2,{"kind":kind,"level":2,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	if view=="battle":
		player.pos=Vector2(420,800)
		for i in units.size(): units[i].pos=player.pos+Vector2(70-i*20,i*30-25)
	else:
		# Prepared layout states only; not a claim of playing the preceding encounters.
		screenshot_mode=true
		player.pos=Vector2(1280,800)
		if view=="layout":
			for e in enemies:
				if e.get("pack",-1) in [0,1]: e.hp=0
		if view=="rest":
			for e in enemies:
				if e.get("pack",-1) in [0,1,3]: e.hp=0
			player.pos=Vector2(1510,630)
		elif view=="boss": player.pos=Vector2(2310,810)
		for i in units.size(): units[i].pos=player.pos+Vector2(-75+i*35,50)
		trail.update(self)
	message=""
	message_time=0
func _process(dt):
	review_clock+=dt
	if view=="battle":
		if review_clock>0.7 and review_casts==0:
			review_casts=1; use_companion_skill(0)
		elif review_clock>1.3 and review_casts==1:
			review_casts=2; use_companion_skill(1)
	super(dt)
