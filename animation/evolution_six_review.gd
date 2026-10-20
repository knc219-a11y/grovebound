extends "res://animation/pixel_gameplay_preview.gd"
@export var screen="materials"
var review_time=0.0
var review_phase=0
var used={}
# Isolated production UI and combat; no player file reads/writes.
func persist_payload(_data): return true
func _ready():
	if screen=="battle":
		super()
		screenshot_mode=true
		loot_rng.seed=20261020
		setup_battle(0)
		return
	# Skip special_review's three-material fixture; run the real two-material transaction.
	screenshot_mode=true
	# main builds fonts/textures/HUD while overridden load/save keep this isolated.
	super()
	owned.clear()
	squad.clear()
	mode="camp"
	for kind in ["boar","fox","deer"]:
		var d=Loot.roll_special(Loot.roll(kind,40,loot_rng,3),kind,loot_rng)
		d.star=5
		d.level=60
		d.special.evolution={"version":1,"state":"ready","ability":Special.evolution_choices(kind).keys()[2]}
		d.special.state="ready"
		d.special.element="water"
		d.special.unique=Special.choices(kind).keys()[1]
		make_owned(kind,60,d)
	owned[0].favorite=true
	owned[0].legacy_options=true
	owned[0].options=[{"key":"power","value":8}]
	squad=[owned[0].id]
	var main_id=owned[0].id
	var support_id=owned[1].id
	if screen=="materials": EvolutionUI.show_page(self,main_id)
	elif screen=="confirm": EvolutionUI.show_confirmation(self,main_id,support_id)
	else:
		var plan=Evolution.preview(owned,squad,main_id,support_id)
		commit_evolution(main_id,support_id,plan.materials)
func setup_base(phase):
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
func setup_battle(phase):
	setup_base(phase)
	for u in units:
		u.data.star=6
		u.data.level=60
		var ability={"boar":"barrier","turtle":"guard","marten":"basic","wolf":"execute","bat":"skill","fox":"reach","deer":"potency"}[u.data.kind]
		u.data.special.evolution={"version":1,"state":"ready","ability":ability,"enhanced":true}
		u.maxhp=max_hp(u.data)
		u.hp=u.maxhp*0.6
	message="6성 진화 · 기존 강화 스킬과 진화 능력 · 격리 QA"
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
