extends "res://animation/pixel_gameplay_preview.gd"
# Two isolated production encounters; not a continuous stage clear or a respawn system.
var review_clock=0.0
var review_phase=0
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","fox","deer","wolf"]:
		var d=make_owned(kind,2,{"kind":kind,"level":2,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	setup_wave(3)
func setup_wave(pack):
	start_stage(false)
	enemies=enemies.filter(func(e): return e.get("pack",-1)==pack or e.boss)
	var direction=-1.0 if pack==3 else 1.0
	player.pos=Trail.PACKS[pack]-Vector2(direction*270,-20)
	for i in units.size():
		units[i].pos=player.pos+Vector2(direction*(110-i*15),i*27-25)
	message="중반 · 일반 적과 약한 무리 7마리" if pack==3 else "보스 직전 · 9마리 무리를 특수 스킬로 제압"
	message_time=10
func _process(dt):
	review_clock+=dt
	if review_clock>0.6 and review_phase==0:
		review_phase=1; use_companion_skill(0)
	elif review_clock>1.2 and review_phase==1:
		review_phase=2; use_companion_skill(1)
	elif review_clock>5 and review_phase==2:
		review_phase=3; setup_wave(5)
	elif review_clock>5.6 and review_phase==3:
		review_phase=4; use_companion_skill(0)
	elif review_clock>6.2 and review_phase==4:
		review_phase=5; use_companion_skill(1)
	super(dt)
