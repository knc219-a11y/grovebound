extends "res://animation/pixel_gameplay_preview.gd"
var review_clock=0.0
var review_phase=0
func _ready():
	super()
	owned.clear(); squad.clear()
	for kind in ["boar","fox"]:
		var d=make_owned(kind,1,{"kind":kind,"level":1,"xp":0,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(390,790)
	units[0].pos=Vector2(480,790)
	units[1].pos=Vector2(430,850)
	message="동료 특수 스킬 · 관통 돌진으로 무리 제압"
	message_time=20
func _process(dt):
	review_clock+=dt
	if review_clock>0.7 and review_phase==0:
		review_phase=1
		use_companion_skill(0)
	elif review_clock>3 and review_phase==1:
		review_phase=2
		# Second isolated wave: production spawning and skill callbacks, no reset of cooldowns.
		enemies.clear()
		spawn_enemy("boar",Vector2(2590,850),4,true)
		for offset in [Vector2(-65,-25),Vector2(0,40),Vector2(60,-45),Vector2(110,25)]:
			spawn_enemy("boar",Vector2(660,790)+offset,1)
			enemies[-1].swarm=true
			enemies[-1].hp*=0.28
			enemies[-1].maxhp=enemies[-1].hp
		units[1].pos=Vector2(450,850)
		message="야성 폭발 · 짧은 집중 후 넓은 범위 타격"
		message_time=10
	elif review_clock>3.6 and review_phase==2:
		review_phase=3
		use_companion_skill(1)
	super(dt)
