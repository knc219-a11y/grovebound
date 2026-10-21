extends "res://main.gd"
# Synthetic fixtures call the production UI and battle loop, with all save IO isolated.
var screen="roster"
var review_time=0.0
var cast_done={}
func load_game(): pass
func persist_payload(_data): return not save_blocked
func _ready():
	super()
	screen=OS.get_environment("GROVE_FEEDBACK_SCREEN")
	if screen not in ["roster","materials","confirm","front","rear","surround","combat"]: screen="roster"
	screenshot_mode=true
	preload("res://animation/roster_layout_review.gd").populate(self)
	if screen=="roster":
		roster_selected_id=owned[8].id
		open_roster()
	elif screen in ["materials","confirm"]:
		setup_materials()
	elif screen in ["front","rear","surround"]:
		setup_battle(false)
		set_party_formation(screen)
		clear_overlay()
		for i in units.size(): units[i].pos=formation_anchor(i)
		message={"front":"앞 진형 · 거북과 멧돼지가 전열을 형성합니다.","rear":"뒤 진형 · 주인공 뒤로 동료를 집결합니다.","surround":"둘러싸기 · 주인공을 중심으로 네 방향에 집결합니다."}[screen]
		message_time=20
	else:
		setup_battle(true)
		screenshot_mode=false
	cam=(player.pos-Vector2(720,400)).clamp(Vector2.ZERO,WORLD_SIZE-VIEW_SIZE)
	update_hud()
	queue_redraw()
	if screen!="combat": set_process(false)
func setup_materials():
	owned.clear()
	squad.clear()
	next_id=101
	for i in 4:
		var source=Loot.roll("fox",40,loot_rng,3)
		var record=Loot.roll_special(source,"fox",loot_rng)
		record.level=50
		record.options=[{"key":"skill_haste","value":12},{"key":"stun_hunter","value":24},{"key":"healing","value":16}]
		record.legacy_options=true
		record.special.affixes=[{"key":"armor","value":9},{"key":"vitality","value":14}]
		record.special.state="ready"
		record.special.element=["fire","water","wind","earth"][i]
		record.special.unique=Special.choices("fox").keys()[i%3]
		record.trait=["용맹함","민첩함","다정함","단단함"][i]
		record.favorite=i==3
		make_owned("fox",50,record)
	squad=[owned[0].id]
	if screen=="confirm": preload("res://ui/evolution.gd").show_confirmation(self,owned[0].id,owned[2].id)
	else: preload("res://ui/evolution.gd").show_page(self,owned[0].id)
func setup_battle(combat):
	owned.clear()
	squad.clear()
	next_id=201
	var kinds=["turtle","fox","deer","wolf"] if combat else ["fox","turtle","deer","boar"]
	for i in 4:
		var source=Loot.roll(kinds[i],40,loot_rng,3)
		var record=Loot.roll_special(source,kinds[i],loot_rng)
		record.special.state="ready"
		record.special.element=["earth","fire","water","wind"][i]
		record.special.unique=Special.choices(kinds[i]).keys()[1]
		make_owned(kinds[i],15,record)
		squad.append(owned[-1].id)
	start_stage(false)
	player.pos=Vector2(990,780)
	enemies.clear()
	for i in units.size():
		units[i].pos=Vector2(1080+(i%2)*70,715+(i/2)*105)
		units[i].hp*=0.65
	if combat:
		for i in 4:
			spawn_enemy(["skeleton","shaman","golem","thornling"][i],Vector2(1180+(i%2)*95,700+(i/2)*130),3)
			enemies[-1].hp=12000
			enemies[-1].maxhp=12000
			enemies[-1].active=true
		message="특수개체 4속성 · 도발/아군 보호 · 마물과 언데드의 일반공격"
		message_time=20
	# Preserve the production completion condition without introducing player saves.
	spawn_enemy("boar",Vector2(2590,850),3,true)
	player.hp*=0.7
	clear_overlay()
func _process(dt):
	if screen=="combat":
		review_time+=dt
		for i in units.size():
			if review_time>0.35+i*0.65 and not cast_done.has(i):
				cast_done[i]=true
				use_companion_skill(i)
	super(dt)
