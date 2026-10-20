extends "res://animation/pixel_gameplay_preview.gd"
@export var screen="choice"
var review_time=0.0
var review_phase=0
var used={}
func _ready():
	super()
	screenshot_mode=true
	owned.clear()
	squad.clear()
	loot_rng.seed=20261020
	if screen=="battle":
		setup_battle(0)
		return
	mode="camp"
	in_combat=false
	for kind in ["boar","fox","turtle"]:
		make_owned(kind,40,Loot.roll(kind,40,loot_rng,3))
	owned[0].legacy_options=true
	owned[0].options=[{"key":"power","value":8}]
	owned[0].favorite=true
	squad=[owned[0].id]
	var ids=[owned[0].id,owned[1].id,owned[2].id]
	if screen=="confirm":
		SynthesisUI.show_confirmation(self,ids,ids[0],"position")
	else:
		commit_synthesis(ids,ids[0],"position",owned.duplicate(true))
		if screen=="choice": preload("res://ui/special_choice.gd").show_page(self,ids[0],"water")
		if screen=="detail": commit_special_choice(ids[0],"earth","guard",owned[0].duplicate(true))
func setup_battle(phase):
	owned.clear()
	squad.clear()
	var kinds=["boar","fox","marten","wolf"] if phase==0 else ["turtle","deer","bat"]
	for i in kinds.size():
		var source=Loot.roll(kinds[i],40,loot_rng,3)
		source.id=next_id
		var d=Loot.roll_special(source,kinds[i],loot_rng)
		d.special.element=["earth","water","fire","wind"][i%4]
		d.special.unique=Special.choices(kinds[i]).keys()[1]
		d.special.state="ready"
		make_owned(kinds[i],1,d)
		squad.append(owned[-1].id)
	start_stage(false)
	screenshot_mode=false
	player.pos=Vector2(990,780)
	enemies.clear()
	for i in units.size():
		units[i].pos=Vector2(1050+(i%2)*70,735+floori(i/2.0)*90)
		units[i].hp*=0.6
	for i in 6:
		spawn_enemy("boar",Vector2(1210+(i%3)*65,725+floori(i/3.0)*90),3)
		enemies[-1].hp=15000
		enemies[-1].maxhp=15000
	# Keep the production clear condition active while reviewing the isolated wave.
	spawn_enemy("boar",Vector2(2590,850),3,true)
	player.hp*=0.6
	message="4성 실제 강화 스킬 · "+("돌진/잔여 폭발/연속 사냥/표식" if phase==0 else "아군 보호/회복 보호막/충격 급강하")
	message_time=20
	used.clear()
func _process(dt):
	if screen=="battle":
		review_time+=dt
		if review_time>6 and review_phase==0:
			review_phase=1
			setup_battle(1)
		var local=review_time-review_phase*6
		for i in units.size():
			if local>0.8+i*1.0 and not used.has(i):
				used[i]=true
				use_companion_skill(i)
	super(dt)
