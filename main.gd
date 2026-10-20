extends Node2D
# A self-contained, data-driven playable slice. All gameplay positions are world coordinates.
const Trail=preload("res://trail.gd")
const Campaign=preload("res://campaign.gd")
const Routes=preload("res://campaign_routes.gd")
const ValleyTrail=preload("res://valley_trail.gd")
var campaign_progress={}
var current_route={}
var map_theme=0
var map_stage=1
var map_difficulty="normal"
const Species=preload("res://creature_species.gd")
const EnemyPatterns=preload("res://enemy_patterns.gd")
const CreatureVisual=preload("res://animation/creature_visual.gd")
var creature_visual=CreatureVisual.new()
var current_stage=1
var stage_background:Texture2D
var cleared_stages=[]
var seen_species=[]
var run_success=false
const PLAYER_CLASS="druid"
var trail=Trail.new()
const Roles=preload("res://companion_roles.gd")
const Expedition=preload("res://expedition.gd")
var expedition=Expedition.new()
var bond_hint_seen=false
var preparation_seen=false
var bulk_selection=[]
var bulk_scroll=0
var report_contributions=false
const Town=preload("res://town.gd")
var town_position=Town.SPAWN
var town_entered=false
const WORLD_SIZE=Vector2(2900,1650)
const VIEW_SIZE=Vector2(1440,810)
const CAPTURE_CHANCE=0.15
const Loot=preload("res://companion_loot.gd")
const MenuUI=preload("res://ui/game_menu.gd")
var menu_page=""
var menu_back:Callable
var detail_origin_page=""
var inventory_selected=-1
var inventory_category=0
var inventory_scroll=0
var discovered=[]
const Special=preload("res://special_companions.gd")
const SpecialCombat=preload("res://special_combat.gd")
const Evolution=preload("res://evolution_rules.gd")
const EvolutionUI=preload("res://ui/evolution.gd")
const Synthesis=preload("res://synthesis_rules.gd")
const SynthesisUI=preload("res://ui/synthesis_preview.gd")
const Management=preload("res://companion_management.gd")
var roster_kind_filter=""
var roster_grade_filter=""
var roster_favorites_only=false
var roster_sort=0
var loot_rng=RandomNumberGenerator.new()
var recent_capture_id=-1
var pending_loot_id=-1
var loot_reveal_delay=0.0
const LootAudio=preload("res://ui/loot_audio.gd")
var loot_audio:AudioStreamPlayer
var loot_sounds={}
var loot_result_button:Button
const CaptureVisual=preload("res://animation/capture_visual.gd")
var capture_visual=CaptureVisual.new()
const SAVE_PATH = "user://grovebound_v1.json"
const SaveData = preload("res://save_data.gd")
var save_path = SAVE_PATH
var save_notice = ""
var save_blocked = false
var save_backup_path = ""
const Assault=preload("res://companion_assault.gd")
const NAMES = {"boar":"멧돼지", "marten":"담비", "fox":"여우", "turtle":"거북", "deer":"사슴", "wolf":"늑대", "druid":"드루이드","bat":"동굴박쥐"}
const ROLES = {"boar":"근접", "marten":"근접", "fox":"원거리", "turtle":"탱커", "deer":"힐러", "wolf":"근접","bat":"속공"}
const STATS = {"boar":[130,14,60,110],"marten":[85,21,62,150],"fox":[80,14,235,125],"turtle":[200,8,65,90],"deer":[95,8,240,120],"wolf":[95,12,60,130],"bat":[70,15,60,150]}
const TRAITS = ["강인함", "용맹함", "단단함", "민첩함"]
const BoarRig = preload("res://animation/boar_pixel.gd")
var boar_rig
const PixelActor = preload("res://animation/pixel_actor.gd")
var druid_rig
const WeaponVisual=preload("res://animation/weapon_visual.gd")
var weapon_visual
var druid_body:Texture2D
var animal_rigs={}
const ActionPlayer=preload("res://animation/action_player.gd")
const DruidAttack=preload("res://animation/druid_attack.gd")
var motion_actions
const PIXEL_KINDS = ["druid","marten","fox","turtle","deer","wolf"]
var textures = {}
var font: Font
var heading_font: Font
var rng = RandomNumberGenerator.new()
var owned = []
var squad = []
var units = []
var enemies = []
var enemy_visual_id=0
var captures = []
const CombatFeedback=preload("res://animation/combat_feedback.gd")
var combat_feedback=CombatFeedback.new()
var effects = []
var terrain = []
var trees = []
var player = {"pos":Vector2(300,760),"hp":180.0,"maxhp":180.0,"cd":0.0,"face":1.0}
var cam = Vector2.ZERO
var clock = 0.0
var materials = 0
var unlocked = false
var tutorial_done = false
var next_id = 1
var mode = "camp"
var tutorial_species = ""
var in_combat = false
var kills = 0
var heal_cd = 0.0
var buff_cd = 0.0
var revive_progress = 0.0
var revive_target = -1
var holding_revive = false
var stick = Vector2.ZERO
var stick_id = -1
var mouse_stick = false
var pointer = Vector2.ZERO
var message = ""
var message_time = 0.0
var ui: CanvasLayer
var hud: Control
var overlay: Control
var status_label: Label
var quest_label: Label
var toast_label: Label
var heal_button: Button
var buff_button: Button
var interact_button: Button
var dropdown: Control
var town_hidden_labels=[]
var party_buttons = []
var chosen_swap = -1
var is_test = false
var screenshot_mode = false
var stage_time = 0.0
var revive_touch_id = -1
var boss_label: Label
var boss_panel: Panel
const GroveUI=preload("res://ui/grove_ui.gd")
const CompanionCard=preload("res://ui/companion_card.gd")
const SupportButton=preload("res://ui/support_button.gd")
var player_hp_bar: ProgressBar
var boss_hp_bar: ProgressBar
var interact_progress: ProgressBar

func _ready():
	var combat_audio=preload("res://animation/combat_audio.gd").new()
	add_child(combat_audio)
	combat_feedback.sounded.connect(combat_audio.cue)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 10417
	font=load("res://assets/fonts/Galmuri11.res")
	heading_font=load("res://assets/fonts/Galmuri11-Bold.res")
	font=heading_font
	font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	heading_font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	textures["valley"]=load("res://assets/maps/greenwater-beginner-v3.webp")
	for key in ["druid","boar","marten","fox","turtle","deer","wolf","tree"]:
		textures[key] = load("res://assets/party-pixel/"+key+".png" if key in PIXEL_KINDS else "res://assets/"+key+".png")
	druid_body=load("res://assets/party-pixel/druid-body-v2.png")
	boar_rig=BoarRig.new()
	druid_rig=PixelActor.new("res://animation/druid_walk_frames.json","res://animation/druid_run_frames.json")
	weapon_visual=WeaponVisual.new()
	motion_actions=ActionPlayer.new()
	for species in ["wolf","fox","marten","deer","turtle"]:
		animal_rigs[species]=PixelActor.new("res://animation/"+species+"_walk_frames.json","res://animation/"+species+"_trot_frames.json")
	textures["boar"]=boar_rig.portrait()
	for kind in Species.NEW: textures[kind]=creature_visual.portrait(kind)
	build_terrain()
	build_ui()
	is_test = "--self-test" in OS.get_cmdline_user_args()
	screenshot_mode = "--screenshot" in OS.get_cmdline_user_args()
	if is_test:
		run_tests()
		return
	rng.randomize()
	loot_rng.randomize()
	load_game()
	show_camp()
	if "--screenshot" in OS.get_cmdline_user_args():
		demo_scene()

func build_terrain():
	for i in range(1700):
		var p = Vector2(rng.randf_range(0,2900),rng.randf_range(0,1650))
		terrain.append([p, rng.randf_range(2,7), rng.randi_range(0,4)])
	for i in range(200):
		var p = Vector2(rng.randf_range(40,2860),rng.randf_range(40,1600))
		if p.y < 490 or p.y > 1380 or p.x < 140 or p.x > 2750:
			trees.append([p,rng.randf_range(115,185)])
	trees.sort_custom(func(a,b): return a[0].y < b[0].y)

func build_ui():
	ui = CanvasLayer.new()
	add_child(ui)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	ui.add_child(hud)
	var theme=GroveUI.theme(heading_font)
	var hud_theme=theme.duplicate()
	hud_theme.default_font=heading_font
	hud.theme=hud_theme
	panel(hud,Rect2(22,18,320,86),Color("202823f2"))
	status_label=label(hud,"",Vector2(40,29),19)
	player_hp_bar=health_bar(hud,Rect2(40,72,284,10))
	panel(hud,Rect2(365,18,620,86),Color("202823f2"))
	quest_label=label(hud,"",Vector2(385,28),18)
	toast_label=label(hud,"",Vector2(385,210),17)
	toast_label.size=Vector2(650,54)
	toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	loot_result_button=button(hud,"새로운 인연 확인",Rect2(22,116,320,46),func(): show_loot_details(recent_capture_id))
	town_hidden_labels.append(label(hud,"동료 스킬",Vector2(365,650),14))
	for i in range(4):
		var b=CompanionCard.new()
		b.position=Vector2(363+i*158,676)
		b.size=Vector2(148,112)
		b.slot=i+1
		b.focus_mode=Control.FOCUS_NONE
		b.pressed.connect(func(): use_companion_skill(i))
		hud.add_child(b)
		party_buttons.append(b)
	heal_button=SupportButton.new()
	heal_button.position=Vector2(1050,676)
	heal_button.size=Vector2(160,112)
	heal_button.focus_mode=Control.FOCUS_NONE
	heal_button.pressed.connect(cast_heal)
	hud.add_child(heal_button)
	buff_button=SupportButton.new()
	buff_button.healing=false
	buff_button.position=Vector2(1220,676)
	buff_button.size=Vector2(160,112)
	buff_button.focus_mode=Control.FOCUS_NONE
	buff_button.pressed.connect(cast_buff)
	hud.add_child(buff_button)
	interact_button=button(hud,"",Rect2(1080,574,300,80),interact)
	interact_button.button_down.connect(func(): holding_revive=true)
	interact_button.button_up.connect(func(): holding_revive=false)
	interact_progress=health_bar(interact_button,Rect2(14,66,272,5))
	interact_progress.max_value=3
	boss_panel=panel(hud,Rect2(425,116,510,82),Color("202823f2"))
	boss_label=label(hud,"",Vector2(442,124),17)
	boss_hp_bar=health_bar(hud,Rect2(442,178,476,6),Color("bd8067"))
	label(hud,"WASD / 방향키 이동",Vector2(30,779),13)
	overlay = Control.new()
	overlay.theme = theme
	overlay.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)
	dropdown=preload("res://ui/dropdown_menu.gd").new()
	dropdown.theme=theme
	ui.add_child(dropdown)
	dropdown.setup(self)

func panel(parent, rect, color):
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s=GroveUI.frame(color)
	if rect.size==Vector2(1440,810):
		s.set_border_width_all(0)
		s.chamfer=0
		s.shadow_size=0
		s.bevel=false
	elif rect.size==Vector2(1100,630):
		s.chamfer=18
		s.shadow_size=8
		s.border_width=2
	p.add_theme_stylebox_override("panel",s)
	parent.add_child(p)
	return p

func health_bar(parent,rect,fill=GroveUI.GREEN):
	var bar=ProgressBar.new()
	bar.position=rect.position
	bar.size=rect.size
	bar.show_percentage=false
	bar.add_theme_font_size_override("font_size",1)
	bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background",GroveUI.bar(GroveUI.INK,Color("4e5647"),1))
	bar.add_theme_stylebox_override("fill",GroveUI.bar(fill,fill,0))
	parent.add_child(bar)
	bar.size=rect.size
	return bar

func label(parent, txt, pos, size=18):
	var l = Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size",size)
	if size>=24: l.add_theme_font_override("font",heading_font)
	l.add_theme_color_override("font_color",GroveUI.PAPER)
	l.add_theme_color_override("font_shadow_color",GroveUI.INK)
	l.add_theme_constant_override("shadow_offset_x",1)
	l.add_theme_constant_override("shadow_offset_y",1)
	parent.add_child(l)
	return l

func button(parent, txt, rect, callback):
	var b = Button.new()
	b.text = txt
	b.position = rect.position
	b.size = rect.size
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func clear_overlay():
	menu_page=""
	menu_back=Callable()
	for c in overlay.get_children():
		overlay.remove_child(c)
		c.queue_free()
	overlay.hide()
	overlay.size = Vector2.ZERO

func modal(title, subtitle,page="",back=Callable()):
	clear_overlay()
	menu_page=page
	menu_back=back
	overlay.show()
	overlay.size = Vector2(1440,810)
	panel(overlay,Rect2(0,0,1440,810),Color(0.03,0.08,0.06,0.85))
	panel(overlay,Rect2(170,90,1100,630),Color("252a2c"))
	var ornament=preload("res://ui/modal_ornament.gd").new()
	ornament.position=Vector2(170,90)
	ornament.size=Vector2(1100,630)
	overlay.add_child(ornament)
	label(overlay,title,Vector2(215,119),31).add_theme_color_override("font_color",Color("ead9af"))
	label(overlay,subtitle,Vector2(215,169),17)
	stick = Vector2.ZERO
	mouse_stick = false
	stick_id = -1
	revive_touch_id = -1
	holding_revive = false
	if back.is_valid(): button(overlay,"뒤로",Rect2(1130,116,95,45),navigate_back)

func resume_game():
	clear_overlay()

func navigate_back():
	if menu_back.is_valid():
		var callback=menu_back
		callback.call()
	elif mode=="camp": clear_overlay()
	elif mode in ["stage","tutorial"]: clear_overlay()

func open_game_menu():
	MenuUI.show_menu(self)

func open_inventory(selected_id=-1,reset_scroll=false):
	MenuUI.show_inventory(self,selected_id,reset_scroll)

func open_collection():
	preload("res://ui/campaign_menu.gd").collection(self)

func open_stage_select():
	preload("res://ui/campaign_menu.gd").stages(self)

func depart_route(c):
	if mode not in ["camp","result"] or squad.is_empty() or not Routes.available(c,Routes.progress_for(self)): return false
	for d in owned:
		if Special.pending(d):
			show_special_choice(d.id)
			return false
	start_stage(false,int(c.theme),c)
	return mode=="stage" and Routes.key(current_route)==Routes.key(c)

func route_can_exit():
	return mode=="stage" and not current_route.is_empty() and trail.ready_to_clear(enemies) and trail.near_exit(player.pos) and not in_combat

func finish_route(success):
	if mode!="stage" or current_route.is_empty(): return false
	if success and not route_can_exit(): return false
	var progress=Routes.progress_for(self).duplicate(true)
	var legacy=cleared_stages.duplicate()
	if success:
		progress=Routes.completed(progress,current_route)
		if int(current_route.stage)==8 and int(current_route.theme) not in legacy: legacy.append(int(current_route.theme))
	var payload=save_payload().duplicate(true)
	payload.campaign_progress=progress
	payload.cleared_stages=legacy
	payload.unlocked=unlocked or 1 in legacy
	payload.materials=materials+(10 if success else 0)
	if not persist_payload(payload):
		notify("탐험 결과 저장에 실패했습니다. 길 잇기를 다시 눌러 주세요.")
		return false
	campaign_progress=progress; cleared_stages=legacy; unlocked=payload.unlocked; materials=payload.materials
	mode="result"; run_success=success
	for u in units:
		u.erase("assault"); u.erase("special_action")
	reset_player_visual_state()
	var ending=Routes.profile(current_route).ending if success else "드루이드가 쓰러져 귀환 · 클리어 보너스 없음"
	expedition.close(owned,materials,kills,stage_time,ending,units)
	show_run_report()
	return true

func depart_stage(id):
	if mode not in ["camp","result"] or squad.is_empty() or not Campaign.accessible(id,cleared_stages): return false
	start_stage(false,id)
	return true

func open_species_roster(kind):
	roster_kind_filter=kind
	roster_grade_filter=""
	roster_favorites_only=false
	roster_sort=0
	open_roster()

func return_from_details():
	if detail_origin_page=="inventory": open_inventory()
	elif detail_origin_page=="companions": open_roster()
	else: resume_game()

func open_controls():
	modal("조작 안내","탐험과 동료 지원을 위한 기본 조작입니다.","controls",open_game_menu)
	label(overlay,"이동  WASD / 방향키 · 터치 이동 스틱\n회복  Q · 야성 강화  E\n동료 스킬  1~4 · 하단 동료 초상 터치\n교감  F · 쓰러진 동료 소생은 F 길게 누르기\n가방  I · 편성  Tab · 메뉴 / 뒤로  Esc",Vector2(245,250),24)
	label(overlay,"메뉴를 열면 탐험이 일시정지됩니다. 편성은 비전투 중, 육성은 캠프에서 가능합니다.",Vector2(245,530),18)
	label(overlay,"동료 초상의 강·용·단·민·정은 상시 특성입니다. 가방의 상세 화면에서 효과를 확인하세요.",Vector2(245,575),16)
	button(overlay,"메뉴로",Rect2(925,630,285,55),open_game_menu)

func reset_player_visual_state():
	# Transitions stop combat animation without changing equipment or saved progression.
	for key in ["action_key","action_duration","action_remaining","action_face","pending_basic","channel_time","hit","swing","death","recoil","pixel_phase","pixel_running","pixel_moving","pixel_down","team_guard","special_barrier","barrier_time"]:
		player.erase(key)
	player.walk=false
	player.channeling=false
	player.move_speed=0.0
	player.pixel_last=player.pos
	revive_target=-1
	revive_progress=0.0
	holding_revive=false
	stick=Vector2.ZERO

func face_player_target(target):
	if absf(target.x-player.pos.x)>1.0: player.face=signf(target.x-player.pos.x)

func show_camp():
	var show_recap=false
	if expedition.active: show_recap=expedition.close(owned,materials,kills,stage_time,"마을로 중도 귀환",units)
	if mode!="camp" or not town_entered: player.pos=town_position
	town_entered=true
	message=""
	message_time=0.0
	mode="camp"
	in_combat=false
	player.hp=player.maxhp
	reset_player_visual_state()
	player.walk=false
	player.channeling=false
	revive_target=-1
	holding_revive=false
	stick=Vector2.ZERO
	units.clear()
	enemies.clear()
	captures.clear()
	effects.clear()
	combat_feedback.clear()
	clear_overlay()
	save_game()
	for d in owned:
		if Special.pending(d): show_special_choice(d.id); return
	if show_recap: show_run_report()

func show_run_report():
	preload("res://ui/expedition_report.gd").show_report(self)

func update_town(dt):
	var motion=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if stick.length()>0.1: motion=stick
	var previous=player.pos
	player.pos=Town.move(player.pos,motion.limit_length()*220*dt)
	player.walk=player.pos.distance_to(previous)>0.01
	player.move_speed=player.pos.distance_to(previous)/maxf(dt,0.001)
	if absf(player.pos.x-previous.x)>0.01: player.face=signf(player.pos.x-previous.x)
	town_position=player.pos
	druid_rig.advance(player,dt)

func town_interact():
	if overlay.visible or dropdown.popup.visible: return
	match Town.nearest(player.pos):
		0: open_roster()
		1:
			modal("잎그늘 쉼터 · 야영 자리","가칭 / 동료들과 탐험을 준비하는 작은 쉼터","home",resume_game)
			label(overlay,"함께할 동료 %d마리 · 성장 재료 %d\n동료 쉼터에서 편성과 육성을 준비하세요.\n동쪽 표지판에서 사냥길을 선택합니다." % [owned.size(),materials],Vector2(250,280),23)
			button(overlay,"동료 · 편성 · 육성",Rect2(260,510,400,64),open_roster)
			button(overlay,"마을로",Rect2(760,510,400,64),resume_game)
			button(overlay,"새 여정",Rect2(960,630,200,50),confirm_reset)
		2:
			if not tutorial_done: show_starters()
			else: open_stage_select()

func show_starters():
	modal("첫 인연을 선택하세요", "야수의 경계를 누그러뜨린 뒤 다가가 교감하세요. 첫 인연의 교감 기회는 확정입니다.","starters",resume_game)
	var kinds = Species.starters(PLAYER_CLASS)
	var desc = ["든든한 근접형\n관통 돌진 · 무리 제압", "빠른 근접형\n한 적에게 연속 공격", "원거리형\n넓은 야성 폭발"]
	for i in range(3):
		var x = 230+i*330
		var t = TextureRect.new()
		t.texture = textures[kinds[i]]
		t.position = Vector2(x,240)
		t.size = Vector2(250,175)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.add_child(t)
		label(overlay,desc[i],Vector2(x+20,440),20)
		button(overlay,NAMES[kinds[i]]+" 만나기",Rect2(x,560,260,65),func(): tutorial_species=kinds[i]; start_stage(true))

func make_owned(kind, level, rolled={}):
	if not STATS.has(kind) or not Species.can_tame(kind,PLAYER_CLASS): return {}
	var d=Loot.roll(kind,level,loot_rng) if rolled.is_empty() else rolled.duplicate(true)
	d.erase("pos")
	d.id=next_id
	d.favorite=d.get("favorite",false)
	Loot.normalize(d)
	next_id+=1
	owned.append(d)
	if not discovered.has(d.kind): discovered.append(d.kind)
	return d

func max_hp(d):
	return STATS[d.kind][0] * (Special.hp_scale(d) if Special.is_special(d) else (1.0 + (d.level-1)*Loot.hp_growth(d))) * (1.2 if d.trait=="강인함" else 1.0)*(1.0+Loot.bonus(d,"vitality"))*(1.0+Special.hp_bonus(d))

func attack(d):
	return STATS[d.kind][1] * (Special.attack_scale(d) if Special.is_special(d) else (1.0 + (d.level-1)*Loot.attack_growth(d))) * (1.18 if d.trait=="용맹함" else 1.0)*(1.0+Loot.bonus(d,"power"))

func find_owned(id):
	for d in owned:
		if d.id == id: return d
	return {}

func make_unit(d, p):
	if not d is Dictionary or not STATS.has(d.get("kind","")): return {}
	return {"data":d,"pos":p,"hp":max_hp(d),"maxhp":max_hp(d),"cd":0.0,"skill":0.0,"buff":0.0,"shield":0.0,"face":1.0,"walk":false}

func start_stage(tutorial,stage_id=1,route={}):
	for d in owned:
		if Special.pending(d):
			show_special_choice(d.id)
			notify("특수개체의 속성·고유 능력 선택을 마쳐 주세요.")
			return
	current_stage=stage_id if Campaign.STAGES.has(stage_id) and not tutorial else 1
	stage_background=load(Campaign.STAGES[current_stage].background)
	current_route=route.duplicate(true) if Routes.implemented(route) and not tutorial else {}
	run_success=false
	if current_route.is_empty():
		trail=Trail.new()
		trail.configure(current_stage)
	else:
		trail=ValleyTrail.new()
		trail.configure_route(current_route,Routes.profile(current_route))
	trail.reset()
	report_contributions=false
	expedition.begin(owned,materials,tutorial)
	expedition.baseline.stage_id=current_stage
	expedition.baseline.route=current_route.duplicate(true)
	bond_hint_seen=false
	if mode=="camp": town_position=player.pos
	pending_loot_id=-1
	repair_party()
	clear_overlay()
	mode = "tutorial" if tutorial else "stage"
	player.pos = Vector2(340,800)
	reset_player_visual_state()
	player.hp = player.maxhp
	player.cd = 0.0
	kills = 0
	stage_time = 0.0
	in_combat = false
	holding_revive = false
	stick = Vector2.ZERO
	heal_cd = 0.0
	buff_cd = 0.0
	revive_progress = 0.0
	enemies.clear()
	captures.clear()
	units.clear()
	effects.clear()
	combat_feedback.clear()
	for i in range(squad.size()):
		var unit = make_unit(find_owned(squad[i]),player.pos+Vector2(-65-i*25,40))
		if not unit.is_empty(): units.append(unit)
	if tutorial:
		spawn_enemy(tutorial_species,Vector2(650,800),1,false,true)
		notify("야수에게 다가가 경계를 누그러뜨리세요. 전투 후 쉬고 있는 야수와 교감할 수 있습니다.")
	else:
		if current_route.is_empty():
			Campaign.populate(self,current_stage)
			notify(Campaign.STAGES[current_stage].name+" · "+Campaign.STAGES[current_stage].theme)
		else:
			Routes.populate(self,current_route)
			notify(Routes.profile(current_route).story)
	update_hud()

func spawn_enemy(kind, p, level=1, boss=false, guaranteed=false):
	var h=24.0
	if mode!="tutorial":
		var base=Species.NEW[kind].stats if Species.NEW.has(kind) else STATS[kind]
		h=base[0]*0.72+level*10
	if boss: h=850.0
	enemy_visual_id+=1
	enemies.append({"feedback_id":enemy_visual_id,"kind":kind,"pos":p,"home":p,"hp":h,"maxhp":h,"level":int(level),"boss":boss,"guaranteed":guaranteed,"cd":1.3,"wind":0.0,"aim":p,"stun":0.0,"active":false,"face":-1.0,"pattern":0,"attack_kind":"bite","dash":0.0,"dash_hits":[],"death":0.0})

func active_units():
	return units.slice(0,mini(4,units.size()))

func alive_allies():
	var out = [player]
	for u in active_units():
		if u.hp>0: out.append(u)
	return out

func combat_enemies():
	if mode!="stage": return enemies
	return enemies.filter(func(e): return trail.engageable(e))

func nearest_enemy(p, radius=500.0):
	var result = {}
	var best = radius
	for e in combat_enemies():
		if e.hp<=0: continue
		var dist = p.distance_to(e.pos)
		if dist<best: best=dist; result=e
	return result

func move_entity(u, target, speed, dt, stop=0.0):
	var delta = target-u.pos
	if delta.length()>stop:
		u["walk"]=true
		# Ease into motion and brake near the requested stopping distance.
		var desired=speed*clampf((delta.length()-stop)/40.0,0.2,1.0)
		u.move_speed=move_toward(u.get("move_speed",0.0),desired,speed*6.0*dt)
		var v = delta.normalized()*minf(u.move_speed*dt,maxf(0,delta.length()-stop))
		u.pos = (u.pos+v).clamp(Vector2(150,345),Vector2(2750,1130))
		if absf(delta.x)>14: u.face=signf(delta.x)
		if u.has("walk"): u.walk=true

func _process(dt):
	clock += dt
	loot_reveal_delay=maxf(0,loot_reveal_delay-dt)
	if pending_loot_id>0 and loot_reveal_delay<=0 and mode=="stage" and not in_combat and not overlay.visible and not dropdown.popup.visible:
		show_loot_details(pending_loot_id)
	if is_test: return
	message_time = maxf(0,message_time-dt)
	if (mode=="stage" or mode=="tutorial") and not overlay.visible and not dropdown.popup.visible:
		if not screenshot_mode:
			update_game(minf(dt,0.05))
			druid_rig.advance(player,minf(dt,0.05))
			for actor in units+enemies:
				var species=actor.get("kind",actor.get("data",{}).get("kind",""))
				if species=="boar": boar_rig.advance(actor,minf(dt,0.05))
				elif animal_rigs.has(species): animal_rigs[species].advance(actor,minf(dt,0.05))
				elif Species.NEW.has(species): creature_visual.advance(actor,minf(dt,0.05))
	if mode=="camp" and not overlay.visible and not dropdown.popup.visible:
		update_town(minf(dt,0.05))
	cam = (player.pos-Vector2(720,400)).clamp(Vector2.ZERO,(Town.SIZE if mode=="camp" else WORLD_SIZE)-VIEW_SIZE)
	update_hud()
	queue_redraw()
	if "--screenshot" in OS.get_cmdline_user_args() and clock>2.0 and clock<2.2:
		take_screenshot()

func update_game(dt):
	SpecialCombat.advance(self,player,dt)
	stage_time += dt
	if mode=="stage": trail.update(self,dt)
	combat_feedback.advance(dt)
	for a in [player]+units+enemies:
		if not a.get("walk",false): a.move_speed=0.0
		motion_actions.advance(a,dt)
		if a.hp<=0: a.erase("pending_basic")
		a["hit"]=maxf(0,a.get("hit",0.0)-dt)
		a["swing"]=maxf(0,a.get("swing",0.0)-dt)
		a["death"]=maxf(0,a.get("death",0.0)-dt)
		a["walk"]=false
	heal_cd = maxf(0,heal_cd-dt)
	buff_cd = maxf(0,buff_cd-dt)
	for i in range(effects.size()-1,-1,-1):
		effects[i].time -= dt
		if effects[i].time<=0: effects.remove_at(i)
	var motion = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if stick.length()>0.1: motion=stick
	var held = holding_revive or Input.is_physical_key_pressed(KEY_F)
	var down = closest_down()
	player["channeling"]=held and down>=0
	player["channel_time"]=player.get("channel_time",0.0)+dt if player.channeling else 0.0
	if held and down>=0:
		if revive_target!=down: revive_progress=0.0
		revive_target=down
		revive_progress += dt
		if revive_progress>=3.0:
			units[down].hp=units[down].maxhp*0.3
			combat_feedback.emit("revive",player.pos,units[down].pos)
			combat_feedback.emit("skill_druid_revive",player.pos,units[down].pos)
			fx(units[down].pos,units[down].pos,Color("a8f79b"),"소생!",0.8)
			player.channeling=false
			revive_progress=0.0
			revive_target=-1
	else:
		revive_progress=0.0
		revive_target=-1
		player["walk"]=motion.length()>0.1
		player.pos += motion.limit_length()*210.0*dt
		player.pos=player.pos.clamp(Vector2(170,345),Vector2(2740,1130))
		if absf(motion.x)>0.1: player.face=signf(motion.x)
		player.cd-=dt
		var target=nearest_enemy(player.pos,250)
		if target.is_empty() and player.get("action_key","")=="attack" and player.get("action_remaining",0.0)>DruidAttack.DURATION-DruidAttack.IMPACT:
			player.action_remaining=0.0
		if not target.is_empty() and player.cd>0 and player.cd<=DruidAttack.IMPACT and not player.walk and player.get("action_remaining",0.0)<=0:
			face_player_target(target.pos)
			DruidAttack.start(player,player.cd)
		if not target.is_empty() and player.cd<=0:
			hit_enemy(target,6.0,player.pos,player)
			player.cd=0.85
	for i in range(units.size()):
		var u=units[i]
		u.skill=maxf(0,u.skill-dt)
		u.buff=maxf(0,u.buff-dt)
		u.shield=maxf(0,u.shield-dt)
		u.walk=false
		SpecialCombat.advance(self,u,dt)
		u.role_flash=maxf(0,u.get("role_flash",0.0)-dt)
		if u.hp<=0: u.erase("assault")
		if i>=4 or u.hp<=0: continue
		if Assault.advance(self,u,dt) or u.has("special_action"): continue
		u.cd-=dt
		if advance_basic_attack(u,dt): continue
		var kind=u.data.kind
		var speed=STATS[kind][3]*(1.2 if u.data.trait=="민첩함" else 1.0)*(1.0+Loot.bonus(u.data,"speed"))*Special.speed(u.data)
		var target=Roles.target(kind,u.pos,combat_enemies(),player.pos,410)
		if u.pos.distance_to(player.pos)>430 or (not target.is_empty() and target.pos.distance_to(player.pos)>550):
			move_entity(u,player.pos,speed*1.7,dt,75)
			continue
		if target.is_empty():
			var offset=Vector2(-75+(i%2)*110,55+(i/2)*60)
			move_entity(u,player.pos+offset,speed*1.3,dt,15)
		elif kind=="deer":
			if u.pos.distance_to(target.pos)<155: move_entity(u,u.pos+(u.pos-target.pos).normalized()*70,speed,dt)
			var injured=lowest_ally(player.pos,600)
			if not injured.is_empty() and injured.hp<injured.maxhp and u.pos.distance_to(injured.pos)>245 and u.pos.distance_to(target.pos)>=155:
				move_entity(u,injured.pos,speed,dt,225)
			var a=lowest_ally(u.pos,300)
			if u.cd<=0 and not a.is_empty() and a.hp<a.maxhp:
				heal(a,12*(1.25 if u.data.trait=="다정함" else 1.0),u.pos,u)
				u.cd=1.7
		else:
			var reach=STATS[kind][2]
			move_entity(u,target.pos,speed,dt,reach*0.85)
			if kind=="fox" and u.pos.distance_to(target.pos)<105:
				move_entity(u,u.pos+(u.pos-target.pos).normalized()*100,speed,dt)
			if u.pos.distance_to(target.pos)<=reach and u.cd<=0:
				if kind in ["boar","wolf","marten","fox"]:
					begin_basic_attack(u,target,attack(u.data)*(1.6 if u.buff>0 else 1.0))
				else: hit_enemy(target,attack(u.data)*(1.6 if u.buff>0 else 1.0),u.pos,u)
				u.cd=0.85 if kind=="marten" else 1.2
	for a in active_units():
		if a.hp<=0: continue
		for b in active_units():
			if a==b or b.hp<=0: continue
			var gap=a.pos-b.pos
			if gap.length()<35 and gap.length()>0.01:
				a.pos+=gap.normalized()*24*dt
	for e in enemies:
		e["hunt_time"]=maxf(0,e.get("hunt_time",0.0)-dt)
		if e.hp<=0 or (mode=="stage" and not trail.engageable(e)): continue
		e.stun=maxf(0,e.stun-dt)
		e.intro=maxf(0,e.get("intro",0.0)-dt)
		if e.get("intro",0.0)>0:
			e.active=true
			e.wind=0.0
			e.dash=0.0
			continue
		var targets=alive_allies()
		var target=player
		var best=99999.0
		for a in targets:
			var dist=e.pos.distance_to(a.pos)
			if a.has("data") and a.data.kind=="turtle" and dist<200: dist-=120
			if dist<best: best=dist; target=a
		if e.get("taunt_time",0.0)>0:
			e.taunt_time-=dt
			if e.taunt.hp>0 and e.pos.distance_to(e.taunt.pos)<450: target=e.taunt
		if not e.active and e.pos.distance_to(target.pos)<270: e.active=true
		if e.active and e.kind not in seen_species: seen_species.append(e.kind)
		if not e.active:
			# A charging boss can cross its leash; finish returning on subsequent frames.
			if e.pos.distance_to(e.home)>10: move_entity(e,e.home,130,dt,10)
			continue
		if e.pos.distance_to(player.pos)>650:
			e.active=false
			e.wind=0.0
			e.dash=0.0
			move_entity(e,e.home,130,dt)
			continue
		if e.stun>0: continue
		e.cd-=dt
		if e.get("dash",0.0)>0:
			advance_charge(e,dt)
		elif e.wind>0:
			e.wind-=dt
			if e.wind<=0: resolve_enemy_attack(e)
		elif e.boss and e.cd<=0:
			begin_boss_attack(e,target)
		elif e.pos.distance_to(target.pos)>(Species.NEW[e.kind].reach if Species.NEW.has(e.kind) else 49):
			move_entity(e,target.pos,Species.NEW[e.kind].speed if Species.NEW.has(e.kind) else 80 if e.boss else 95,dt,Species.NEW[e.kind].reach-5 if Species.NEW.has(e.kind) else 44)
		elif e.cd<=0:
			if Species.NEW.has(e.kind): EnemyPatterns.begin(e,target)
			else:
				e.aim=target.pos
				e.attack_kind="bite"
				e.wind=0.65
				e.wind_total=e.wind
	in_combat=false
	for e in enemies:
		if e.hp>0 and e.active: in_combat=true
	if player.hp<=0:
		finish(false)
		return
	if mode=="stage" and current_route.is_empty():
		var boss_alive=false
		for e in enemies:
			if e.boss and e.hp>0: boss_alive=true
		if not boss_alive:
			finish(true)

func begin_boss_attack(e, target):
	if Species.NEW.has(e.kind):
		EnemyPatterns.boss(e,target)
		return
	e.attack_kind="stomp" if e.get("route_mid",false) or e.pattern%2==0 else "charge"
	e.pattern+=1
	e["origin"]=e.pos
	if e.attack_kind=="stomp":
		e.aim=e.pos
		e.wind=1.15
	else:
		var direction=(target.pos-e.pos).normalized()
		if direction.length()<0.01: direction=Vector2.LEFT
		e.aim=(e.pos+direction*340).clamp(Vector2(170,345),Vector2(2740,1130))
		e.wind=1.25
	e.wind_total=e.wind
	if absf(e.aim.x-e.pos.x)>1: e.face=signf(e.aim.x-e.pos.x)

func resolve_enemy_attack(e):
	if Species.NEW.has(e.kind):
		EnemyPatterns.resolve(self,e)
		return
	if e.boss and e.attack_kind=="stomp": e.boss_recovery=0.38
	e["swing"]=0.22
	motion_actions.start(e,e.kind,"cast" if e.kind=="fox" else "attack")
	if e.attack_kind=="charge":
		e.dash=0.48
		e.dash_hits=[]
		return
	var radius=130.0 if e.attack_kind=="stomp" else 56.0
	for a in alive_allies():
		if a.pos.distance_to(e.aim)<radius:
			damage_ally(a,(28.0 if e.boss else (2.0 if mode=="tutorial" else 10.0+e.level*2))*(e.get("swarm_damage",0.4) if e.get("swarm",false) else 1.0)*e.get("damage_scale",1.0),e.pos)
	if e.attack_kind=="stomp":
		combat_feedback.emit("stomp",e.pos,e.pos,0,{"radius":130.0})
	e.cd=2.4 if e.boss else 1.5

func advance_charge(e, dt):
	var previous=e.pos
	e.pos=e.pos.move_toward(e.aim,850.0*dt)
	e.dash=maxf(0,e.dash-dt)
	e["walk"]=true
	for a in alive_allies():
		var id=a.data.id if a.has("data") else -1
		var closest=Geometry2D.get_closest_point_to_segment(a.pos,previous,e.pos)
		if a.pos.distance_to(closest)<48 and not e.dash_hits.has(id):
			damage_ally(a,35.0*e.get("damage_scale",1.0),e.pos)
			e.dash_hits.append(id)
	if e.pos.distance_to(e.aim)<2 or e.dash<=0:
		e.dash=0.0
		e.boss_recovery=0.32
		e.cd=2.8

func damage_ally(a, damage, source):
	if a.hp<=0: return
	var incoming=damage
	if a.has("data"):
		if a.data.trait=="단단함": damage*=0.85
		damage*=1.0-Loot.bonus(a.data,"armor")
		damage*=Special.armor(a.data)
		damage*=0.75 if a.get("special_guard",0.0)>0 else 1.0
	damage*=0.85 if a.get("team_guard",0.0)>0 else 1.0
	if a.has("data") and a.shield>0: damage*=0.4
	var absorbed=minf(damage,a.get("special_barrier",0.0))
	a["special_barrier"]=maxf(0,a.get("special_barrier",0.0)-absorbed)
	damage-=absorbed
	var taken=minf(a.hp,damage)
	if a.has("data"):
		var prevented=maxf(0,minf(a.hp,incoming)-taken)
		Roles.add_metric(a,"mitigation",prevented)
		if a.shield>0: Roles.signal_action(a,"방어 중")
	a.hp=maxf(0,a.hp-damage)
	a["hit"]=0.18
	a["recoil"]=(a.pos-source).normalized()*6
	combat_feedback.emit("block" if a.get("shield",0.0)>0 else "hurt",source,a.pos,taken,{"target_id":a.data.id if a.has("data") else -1,"height":sprite_height(a.data.kind) if a.has("data") else sprite_height("druid")})

func animate_attack(source,attacker={}):
	for a in ([attacker] if not attacker.is_empty() else [player]+active_units()):
		if a.pos.distance_to(source)<2:
			a["swing"]=0.22
			var species="druid" if a==player else a.data.kind
			if species=="druid": DruidAttack.start(a)
			else: motion_actions.start(a,species,"cast" if species=="fox" else "attack")
			# Immediate skills already applied damage; show the impact, not a late wind-up.
			if species in ["boar","wolf","marten","fox"]: a.action_remaining=a.action_duration*2.0/3.0
			return

func begin_basic_attack(u,target,damage):
	if u.hp<=0 or target.hp<=0 or u.has("pending_basic"): return false
	u.walk=false
	if absf(target.pos.x-u.pos.x)>1: u.face=signf(target.pos.x-u.pos.x)
	motion_actions.start(u,u.data.kind,"cast" if u.data.kind=="fox" else "attack")
	u.pending_basic={"target":target,"damage":damage,"remaining":0.14}
	return true

func advance_basic_attack(u,dt):
	if not u.has("pending_basic"): return false
	var pending=u.pending_basic
	if u.hp<=0:
		u.erase("pending_basic")
		return false
	pending.remaining-=maxf(0,dt)
	u.walk=false
	if pending.remaining<=0:
		u.erase("pending_basic")
		var target=pending.target
		# A target that died or left the species' normal reach is not hit remotely.
		if enemies.has(target) and target.hp>0 and u.pos.distance_to(target.pos)<=STATS[u.data.kind][2]+18:
			hit_enemy(target,pending.damage,u.pos,u,false)
	return true

func hit_enemy(e, damage, source,attacker={},animate=true,is_skill=false):
	if mode=="stage" and not trail.engageable(e): return
	if e.kind not in seen_species: seen_species.append(e.kind)
	if e.hp<=0: return
	if not attacker.is_empty() and attacker.has("data") and e.get("stun",0.0)>0:
		damage*=1.0+Loot.bonus(attacker.data,"stun_hunter")
	if not attacker.is_empty() and attacker.has("data"):
		damage*=Special.damage(attacker.data,is_skill,e)
		if e.get("hunt_owner",-1)==attacker.data.id and e.get("hunt_time",0.0)>0: damage*=1.20
	var dealt=minf(e.hp,damage)
	if not attacker.is_empty() and attacker.has("data"):
		Roles.add_metric(attacker,"damage",dealt)
		if attacker.get("role_flash",0.0)<=0:
			Roles.signal_action(attacker,"기절 집중" if attacker.data.kind=="marten" and e.get("stun",0.0)>0 else "추격 타격" if attacker.data.kind=="wolf" else "기본 공격")
	e.hp=maxf(0,e.hp-damage)
	e.active=true
	e["hit"]=0.16
	e["recoil"]=(e.pos-source).normalized()*7
	if animate:
		if attacker==player or (attacker.is_empty() and player.pos.distance_to(source)<2): face_player_target(e.pos)
		animate_attack(source,attacker)
	var visual="melee"
	if not attacker.is_empty():
		visual="support" if attacker==player else ("fox" if attacker.data.kind=="fox" else "melee")
	combat_feedback.emit(visual,source,e.pos,dealt,{"audio_kind":"hit_"+attacker.data.kind if attacker.has("data") else visual,"target_id":e.get("feedback_id",str(e.pos.round())),"height":sprite_height(e.kind,e.get("boss",false))})
	if not animate and not attacker.is_empty() and attacker.has("data") and attacker.data.kind!="fox":
		combat_feedback.emit("impact_"+attacker.data.kind,source,e.pos)
	if e.hp<=0:
		e["death"]=0.32
		kills+=1
		materials+=(0 if e.get("swarm",false) else (1 if not e.boss else 5))
		if not e.get("swarm",false):
			for u in units: gain_xp(u.data,12+int(e.level)*4)
		if not e.boss and not e.get("swarm",false) and Species.can_tame(e.kind,PLAYER_CLASS) and (e.guaranteed or rng.randf()<CAPTURE_CHANCE):
			var candidate=Loot.roll(e.kind,e.level,loot_rng,Campaign.wild_star(current_stage,loot_rng))
			candidate.pos=e.pos
			captures.append(candidate)
			if not bond_hint_seen:
				bond_hint_seen=true
				notify("경계를 푼 야수가 쉬고 있습니다. 가까이에서 교감 [F / 화면 버튼]으로 인연을 맺으세요.")
			if Loot.grade(candidate)!="common": play_loot_sound(Loot.grade(candidate))
			e.death=0.0 # The resting capture pose replaces the fading corpse.
		save_game()

func gain_xp(d, amount):
	var old_level=d.level
	var projected=Management.project(d,amount)
	d.level=projected.level
	d.xp=projected.xp
	if d.level>old_level:
		for u in units:
			if u.data.id==d.id:
				u.maxhp=max_hp(d)
				if u.hp>0 and active_units().has(u):
					combat_feedback.emit("level_up",u.pos,u.pos)
					fx(u.pos,u.pos,Color("e5ce87"),"Lv.%d" % d.level,0.9)

func lowest_ally(origin, reach):
	var best={}
	var ratio=2.0
	for a in alive_allies():
		if a.pos.distance_to(origin)<=reach and a.hp/a.maxhp<ratio:
			ratio=a.hp/a.maxhp
			best=a
	return best

func heal(a, amount, source,healer={}):
	for caster in ([healer] if not healer.is_empty() else [player]+active_units()):
		if caster.pos.distance_to(source)<2:
			var species="druid" if caster==player else caster.data.kind
			motion_actions.start(caster,species,"heal")
			break
	if not healer.is_empty() and healer.has("data"): amount*=(1.0+Loot.bonus(healer.data,"healing"))*Special.healing(healer.data)
	var restored=minf(amount,a.maxhp-a.hp)
	a.hp=minf(a.maxhp,a.hp+amount)
	if restored>0 and not healer.is_empty() and healer.has("data"):
		Roles.add_metric(healer,"healing",restored)
		Roles.signal_action(healer,"회복 지원")
	if restored>0: combat_feedback.emit("heal",source,a.pos,restored,{"target_id":a.data.id if a.has("data") else -1,"height":sprite_height(a.data.kind) if a.has("data") else sprite_height("druid")})

func cast_heal():
	if not can_act() or heal_cd>0: return
	var a=lowest_ally(player.pos,430)
	if not a.is_empty() and a.hp<a.maxhp:
		heal(a,55,player.pos,player)
		combat_feedback.emit("skill_druid_heal",player.pos,a.pos)
		heal_cd=8.0

func cast_buff():
	if not can_act() or buff_cd>0: return
	var best={}
	var power=-1.0
	for u in active_units():
		if u.hp>0 and u.pos.distance_to(player.pos)<430 and attack(u.data)>power:
			best=u
			power=attack(u.data)
	if not best.is_empty():
		motion_actions.start(player,"druid","support")
		best.buff=7.0
		buff_cd=14.0
		combat_feedback.emit("buff",player.pos,best.pos)
		combat_feedback.emit("skill_druid_buff",player.pos,best.pos)
		fx(player.pos,best.pos,Color("ffce6a"),"야성 +60%",0.9)

func can_act():
	return (mode=="stage" or mode=="tutorial") and not overlay.visible and not dropdown.popup.visible and revive_target<0

func use_companion_skill(i):
	if not can_act() or i>=active_units().size(): return
	var u=units[i]
	if u.hp<=0 or u.skill>0 or u.has("assault") or u.has("special_action"): return
	var target=Roles.target(u.data.kind,u.pos,combat_enemies(),player.pos,430)
	var skill_origin=u.pos
	if SpecialCombat.cast(self,u,target): return
	match u.data.kind:
		"deer":
			for a in alive_allies():
				if a.pos.distance_to(u.pos)<350: heal(a,35*(1.25 if u.data.trait=="다정함" else 1),u.pos,u)
			combat_feedback.emit("skill_deer",u.pos,u.pos)
		"turtle":
			motion_actions.start(u,"turtle","guard")
			u.shield=5.0
			for e in combat_enemies():
				if e.hp>0 and e.pos.distance_to(u.pos)<270:
					e.active=true
					e["taunt"]=u
					e["taunt_time"]=5.0
					e.aim=u.pos
					e.pos=e.pos.move_toward(u.pos,35)
			combat_feedback.emit("guard",u.pos,u.pos)
			combat_feedback.emit("skill_turtle",u.pos,u.pos)
			fx(u.pos,u.pos,Color("a7d9e8"),"도발 · 방어",1)
		_:
			if target.is_empty(): return
			u.erase("pending_basic")
			var multiplier=1.6 if u.buff>0 else 1.0
			if u.data.kind=="boar":
				Assault.begin_dash(self,u,target,attack(u.data)*3.5*multiplier)
			elif u.data.kind=="fox":
				Assault.begin_blast(self,u,target,attack(u.data)*2.5*multiplier)
			else:
				hit_enemy(target,attack(u.data)*3.5*multiplier,u.pos,u)
				combat_feedback.emit("skill_"+u.data.kind,skill_origin,target.pos)
	Roles.signal_action(u,Roles.SKILLS[u.data.kind])
	Roles.add_metric(u,"skills",1)
	u.skill=10.0*(1.0-Loot.bonus(u.data,"skill_haste"))*Special.haste(u.data)

func closest_down():
	var best=85.0
	var result=-1
	for i in range(active_units().size()):
		var u=units[i]
		var dist=u.pos.distance_to(player.pos)
		if u.hp<=0 and dist<best: best=dist; result=i
	return result

func closest_capture():
	var best=110.0
	var result=-1
	for i in range(captures.size()):
		var dist=captures[i].pos.distance_to(player.pos)
		if dist<best: best=dist; result=i
	return result

func interact():
	if mode=="camp":
		town_interact()
		return
	if route_can_exit() and not overlay.visible and not dropdown.popup.visible and closest_capture()<0:
		finish_route(true)
		return
	if not can_act() or closest_down()>=0: return
	var i=closest_capture()
	if i<0:
		if route_can_exit():
			finish_route(true)
			return
		if mode=="stage" and not in_combat and trail.near_rest(player.pos): show_trail_rest()
		return
	var c=captures[i]
	if not STATS.has(c.kind) or not Species.can_tame(c.kind,PLAYER_CLASS): return
	var d=make_owned(c.kind,int(c.level),c if c.has("grade") else {})
	expedition.record_bond(d)
	recent_capture_id=d.id
	# Cosmetic communion: support gesture and restorative light, no HP/stat changes.
	motion_actions.start(player,"druid","support")
	combat_feedback.emit("heal",player.pos,c.pos)
	combat_feedback.emit("capture_"+Loot.grade(d),c.pos,c.pos)
	play_loot_sound(Loot.grade(d))
	captures.remove_at(i)
	if squad.size()<6:
		squad.append(d.id)
		units.append(make_unit(d,c.pos))
	notify("[%s] %s Lv.%d · %s · 새로운 인연! %s" % [Loot.title(d),NAMES[d.kind],d.level,d.trait,"동행 합류" if squad.has(d.id) else "동료 쉼터로 이동"])
	save_game()
	if mode=="stage" and not in_combat:
		pending_loot_id=d.id
		loot_reveal_delay=0.45
	if mode=="tutorial":
		tutorial_done=true
		mode="tutorial_practice"
		modal("첫 인연을 맺었습니다!",NAMES[d.kind]+" · "+ROLES[d.kind]+" · "+d.trait+" / 이제 함께 싸워보세요.")
		label(overlay,"동료는 자동으로 싸우고, 초상화를 누르면 고유 스킬을 사용합니다.\nQ 회복과 E 야성 강화로 동료를 지원하세요.\n\n출전은 최대 4마리, 출발 준비는 6마리입니다.\n연습 후 마을의 동료 쉼터에서 편성·육성을 준비하세요.",Vector2(230,280),23)
		button(overlay,"협동 전투 시작",Rect2(500,570,420,65),start_practice)

func show_trail_rest():
	if mode!="stage" or in_combat or not trail.near_rest(player.pos): return
	modal(trail.rest_name,"동료들과 잠시 숨을 고르고 다음 길을 준비하세요.","trail_rest",resume_game)
	var hint="북쪽과 남쪽으로 갈라지는 길은 선택 동선입니다.\n동쪽의 표지판은 우두머리 공터로 이어집니다." if current_route.is_empty() else "옆길의 사슴과 거북은 선택해서 만날 수 있습니다.\n길목을 제압한 뒤 물길 표식에서 [F]로 탐험을 완료하세요."
	if not current_route.is_empty(): hint=trail.data.get("side_name","옆길 · 사슴과 거북")+" · 선택 동선입니다.\n길목 제압 후 "+trail.data.get("exit_name","물길 표식")+"에서 [F]로 탐험을 완료하세요."
	label(overlay,"동행 중인 6마리 안에서 출전 동료를 교체할 수 있습니다.\n회복은 기존 지원 스킬 [Q / 회복 버튼]을 사용하세요.\n\n"+hint,Vector2(240,270),22)
	button(overlay,"동행 편성",Rect2(240,550,285,60),open_roster)
	button(overlay,"가방 확인",Rect2(575,550,285,60),open_inventory)
	button(overlay,"길로 돌아가기",Rect2(925,630,285,55),resume_game)

func start_practice():
	clear_overlay()
	mode="tutorial"
	spawn_enemy("wolf",player.pos+Vector2(240,0),1,false,false)
	enemies[-1].maxhp=70.0
	enemies[-1].hp=70.0
	enemies[-1].guaranteed=false
	tutorial_species="practice"

func finish(success):
	if not current_route.is_empty():
		finish_route(success)
		return
	if mode=="result": return
	mode="result"
	for u in units:
		u.erase("assault")
		u.erase("special_action")
	reset_player_visual_state()
	if success:
		materials+=10
		run_success=true
		if current_stage not in cleared_stages: cleared_stages.append(current_stage)
		if current_stage==1: unlocked=true
		# Legacy revisits may add completed themes but never discard new stage progress.
		var progress=Routes.progress_for(self).duplicate(true)
		for stage in range(1,9):
			var c=Routes.coordinate(current_stage,stage)
			if not Routes.contains(progress,c): progress.cleared.append(c)
		campaign_progress=Routes.normalize({"campaign_progress":progress})
	expedition.close(owned,materials,kills,stage_time,"우두머리 제압 · 클리어 보너스 +10" if success else "드루이드가 쓰러져 귀환 · 클리어 보너스 없음",units)
	save_game()
	show_run_report()

func notify(txt):
	message=txt
	message_time=5.0

func fx(a,b,col,txt,time):
	effects.append({"a":a,"b":b,"color":col,"text":txt,"time":time,"duration":time})

func _exit_tree():
	if is_instance_valid(loot_audio):
		loot_audio.stop()
		loot_audio.stream=null
	loot_sounds.clear()

func play_loot_sound(grade):
	if not is_inside_tree() or is_test or DisplayServer.get_name()=="headless": return
	if loot_audio==null:
		loot_audio=AudioStreamPlayer.new()
		loot_audio.volume_db=-12
		add_child(loot_audio)
	if not loot_sounds.has(grade): loot_sounds[grade]=LootAudio.stream(grade)
	loot_audio.stream=loot_sounds[grade]
	loot_audio.play()

func loot_card(d,x,caption,animate=false):
	var color=Loot.color(d)
	var card=panel(overlay,Rect2(x,265,465,330),Color("202823"))
	card.add_theme_stylebox_override("panel",GroveUI.frame(Color("202823"),color,2))
	label(overlay,caption+" · "+Roles.LABELS[d.kind]+" / "+(Special.SKILLS[d.kind] if Special.ready(d) else Roles.SKILLS[d.kind]),Vector2(x+18,278),16)
	var title=label(overlay,"[%s] %s  Lv.%d" % [Loot.title(d),NAMES[d.kind],d.level],Vector2(x+18,312),25)
	title.add_theme_color_override("font_color",color)
	label(overlay,"고정 특성 · "+d.trait,Vector2(x+18,359),21)
	label(overlay,Loot.TRAIT_DESCRIPTIONS.get(d.trait,"고정된 개체 특성")+(" · 회복량에는 적용 안 됨" if d.kind=="deer" and d.trait=="용맹함" else ""),Vector2(x+18,389),16)
	label(overlay,"체력 %d   공격력 %.1f" % [max_hp(d),attack(d)],Vector2(x+18,421),19)
	var lines=Loot.lines(d)
	if lines.is_empty(): lines.append("고정 특성만 보유")
	if Special.ready(d):
		lines.append(Special.SKILL_DESCRIPTIONS[d.kind])
		lines.append(Special.ELEMENTS[Special.element(d)].description)
		lines.append(Special.choices(d.kind)[Special.unique(d)].description)
		if not Special.evolution(d).is_empty(): lines.append("진화 · "+Special.evolution_description(d))
	var scroller=ScrollContainer.new()
	scroller.position=Vector2(x+18,455)
	scroller.size=Vector2(425,100)
	overlay.add_child(scroller)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroller.add_child(rows)
	for i in lines.size():
		var line=Label.new()
		line.text=lines[i]
		line.custom_minimum_size=Vector2(395,27)
		line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size",17)
		line.add_theme_color_override("font_color",color)
		rows.add_child(line)
		if animate:
			line.modulate.a=0
			var tween=create_tween().bind_node(line)
			tween.tween_interval(0.35+i*0.3)
			tween.tween_property(line,"modulate:a",1.0,0.18)

	label(overlay,"최대 레벨" if Loot.is_max_level(d) else "경험치 %d / %d · 다음 레벨까지 %d" % [d.xp,Management.needed_xp(d),maxi(0,Management.needed_xp(d)-d.xp)],Vector2(x+18,566),15)

func show_loot_details(id,compare_id=-1,animate=true,from_roster=false):
	if in_combat and mode=="stage": notify("전투가 끝나면 새로운 인연을 확인할 수 있습니다."); return
	var d=find_owned(id)
	if d.is_empty(): return
	if menu_page!="detail": detail_origin_page="inventory" if menu_page=="inventory" else ("companions" if from_roster else "")
	pending_loot_id=-1
	var candidates=[]
	for member_id in squad:
		var other=find_owned(member_id)
		if other.is_empty() or other.id==id: continue
		candidates.append(other)
	if compare_id<0:
		for other in candidates:
			if compare_id<0 or other.kind==d.kind: compare_id=other.id
			if other.kind==d.kind: break
	modal((Loot.title(d)+" 특수개체  ·  " if Special.is_special(d) else "맺어진 인연  ·  ")+NAMES[d.kind],Roles.DESCRIPTIONS[d.kind]+" · 스킬 대기 %.1f초" % (10.0*(1.0-Loot.bonus(d,"skill_haste"))*Special.haste(d)),"detail",return_from_details)
	label(overlay,Special.summary(d) if Special.is_special(d) else "교감한 야수가 새로운 동료로 합류했습니다.",Vector2(232,222),18)
	if Special.pending(d): show_special_choice(id); return
	loot_card(d,230,"선택한 동료",animate)
	var comparison=find_owned(compare_id)
	if not comparison.is_empty(): loot_card(comparison,745,"동행 동료와 비교")
	else:
		panel(overlay,Rect2(745,265,465,330),Color("202823"))
		label(overlay,"비교할 다른 동행 동료가 없습니다.",Vector2(765,360),20)
	if not candidates.is_empty():
		var picker=OptionButton.new()
		picker.position=Vector2(745,215)
		picker.size=Vector2(465,42)
		for i in candidates.size():
			var other=candidates[i]
			picker.add_item("[%s] %s Lv.%d · %s" % [Loot.title(other),NAMES[other.kind],other.level,other.trait])
			if other.id==compare_id: picker.select(i)
		picker.item_selected.connect(func(index): show_loot_details(id,candidates[index].id,false,from_roster))
		overlay.add_child(picker)
	var arrange=button(overlay,"편성에서 교체하기" if mode=="camp" or squad.has(d.id) else "캠프에서 동행 편성",Rect2(230,620,290,55),open_roster)
	arrange.disabled=mode!="camp" and not squad.has(d.id)
	button(overlay,"즐겨찾기 잠금 ✓" if d.get("favorite",false) else "즐겨찾기 잠금",Rect2(540,620,240,55),func(): toggle_favorite(id,true,from_roster))
	if mode=="camp": button(overlay,"육성",Rect2(795,620,115,55),func(): show_training(id))
	button(overlay,"확인 · 돌아가기",Rect2(925,620,285,55),return_from_details)

func toggle_favorite(id,return_to_details=false,from_roster=true):
	var d=find_owned(id)
	if d.is_empty(): return
	d.favorite=not d.get("favorite",false)
	save_game()
	if return_to_details: show_loot_details(id,-1,false,from_roster)
	else: open_roster()

func reset_roster_filters():
	roster_kind_filter=""
	roster_grade_filter=""
	roster_favorites_only=false
	roster_sort=0
	open_roster()

func roster_filters(total,shown):
	var species=OptionButton.new()
	species.name="SpeciesFilter"
	species.position=Vector2(215,215)
	species.size=Vector2(170,44)
	species.add_item("모든 종")
	var kinds=STATS.keys()
	for i in kinds.size():
		species.add_item(NAMES[kinds[i]])
		if roster_kind_filter==kinds[i]: species.select(i+1)
	species.item_selected.connect(func(index): roster_kind_filter="" if index==0 else kinds[index-1]; open_roster())
	overlay.add_child(species)
	var rarity=OptionButton.new()
	rarity.name="GradeFilter"
	rarity.position=Vector2(397,215)
	rarity.size=Vector2(145,44)
	rarity.add_item("모든 성급")
	for i in Loot.GRADES.size():
		rarity.add_item(Loot.NAMES[Loot.GRADES[i]])
		if roster_grade_filter==Loot.GRADES[i]: rarity.select(i+1)
	rarity.item_selected.connect(func(index): roster_grade_filter="" if index==0 else Loot.GRADES[index-1]; open_roster())
	overlay.add_child(rarity)
	var sorting=OptionButton.new()
	sorting.name="RosterSort"
	sorting.position=Vector2(554,215)
	sorting.size=Vector2(180,44)
	for caption in ["동행 순서","최근 인연순","높은 성급순","높은 레벨순"]: sorting.add_item(caption)
	sorting.select(roster_sort)
	sorting.item_selected.connect(func(index): roster_sort=index; open_roster())
	overlay.add_child(sorting)
	button(overlay,"즐겨찾기만 ✓" if roster_favorites_only else "즐겨찾기만",Rect2(746,215,150,44),func(): roster_favorites_only=not roster_favorites_only; open_roster())
	button(overlay,"초기화",Rect2(908,215,90,44),reset_roster_filters)
	label(overlay,"표시 %d / %d마리" % [shown,total],Vector2(1020,225),17)

func open_roster():
	if mode=="camp": preparation_seen=true
	if in_combat and mode=="stage": notify("전투 중에는 편성을 바꿀 수 없습니다."); return
	if mode=="tutorial": notify("튜토리얼을 먼저 마쳐주세요."); return
	var camp=mode=="camp"
	modal("동료 관리  ·  출전 4 / 동행 6", "필터·정렬은 실제 편성을 바꾸지 않습니다. 두 동료의 이름을 눌러 동행 순서를 교체하세요.","companions",open_game_menu)
	chosen_swap=-1
	var source=owned if camp else []
	if not camp:
		for id in squad:
			var d=find_owned(id)
			if not d.is_empty(): source.append(d)
	var roster=Management.filtered(source,squad,roster_kind_filter,roster_grade_filter,roster_favorites_only,roster_sort)
	roster_filters(source.size(),roster.size())
	if roster.is_empty():
		label(overlay,"조건에 맞는 동료가 없습니다. 필터를 초기화해 보세요." if not source.is_empty() else "아직 동료가 없습니다. 첫 인연을 만나보세요.",Vector2(235,325),21)
	var scroll=ScrollContainer.new()
	scroll.name="CompanionScroll"
	scroll.position=Vector2(215,274)
	scroll.size=Vector2(1010,306)
	overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	for d in roster:
		var row=preload("res://ui/roster_row.gd").new()
		row.accent=Loot.color(d)
		row.name="Companion_"+str(d.id)
		row.custom_minimum_size=Vector2(970,90)
		rows.add_child(row)
		var idx=squad.find(d.id)
		var desc="[%s] %s  Lv.%d\n%s · %s" % [Loot.title(d),NAMES[d.kind],d.level,Roles.LABELS[d.kind],d.trait]
		if idx>=0: desc=("[출전 %d] " % (idx+1) if idx<4 else "[대기 %d] " % (idx-3))+desc
		else: desc="[보관] "+desc
		var portrait=TextureRect.new()
		portrait.texture=textures[d.kind]
		portrait.custom_minimum_size=Vector2(56,82)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
		var body=VBoxContainer.new()
		body.custom_minimum_size.x=330
		row.add_child(body)
		var b=Button.new()
		b.text=desc
		b.custom_minimum_size=Vector2(330,52)
		b.add_theme_font_size_override("font_size",17)
		b.add_theme_color_override("font_color",Loot.color(d))
		GroveUI.quiet(b,Loot.color(d))
		b.tooltip_text=Roles.describe(d,Loot)+"\n"+"\n".join(Loot.lines(d))
		b.clip_text=true
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): select_swap(d.id))
		body.add_child(b)
		var progress=health_bar(body,Rect2(0,0,330,6))
		progress.custom_minimum_size=Vector2(330,6)
		progress.max_value=maxi(1,Management.needed_xp(d))
		progress.value=0 if Loot.is_max_level(d) else d.xp
		var xp=Label.new()
		xp.text="최대 레벨 · 승급 준비" if Loot.is_max_level(d) and Loot.star(d)<3 else ("최대 레벨" if Loot.is_max_level(d) else "경험치 %d / %d · 다음 레벨까지 %d" % [d.xp,Management.needed_xp(d),maxi(0,Management.needed_xp(d)-d.xp)])
		xp.add_theme_font_size_override("font_size",14)
		body.add_child(xp)
		var favorite=Button.new()
		favorite.text="잠금 ✓" if d.get("favorite",false) else "즐겨찾기"
		favorite.add_theme_color_override("font_color",GroveUI.GREEN if d.get("favorite",false) else GroveUI.MUTED)
		favorite.custom_minimum_size=Vector2(86,64)
		GroveUI.quiet(favorite,GroveUI.GREEN)
		favorite.pressed.connect(func(): toggle_favorite(d.id))
		row.add_child(favorite)
		var detail=Button.new()
		detail.text="상세·비교"
		detail.custom_minimum_size=Vector2(100,64)
		GroveUI.quiet(detail)
		detail.pressed.connect(func(): show_loot_details(d.id,-1,false,true))
		row.add_child(detail)
		if camp:
			var equip=Button.new()
			equip.text="동행 해제" if idx>=0 else "동행 추가"
			equip.custom_minimum_size=Vector2(108,64)
			GroveUI.quiet(equip)
			equip.pressed.connect(func(): toggle_squad(d.id); open_roster())
			row.add_child(equip)
			var grow=Button.new()
			grow.text="능력 선택" if Special.pending(d) else "육성 미리보기"
			grow.custom_minimum_size=Vector2(126,64)
			grow.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			GroveUI.emphasize(grow)
			grow.pressed.connect(func(): show_training(d.id))
			row.add_child(grow)
			var release=Button.new()
			release.text="작별"
			release.tooltip_text="자연으로 보내기"
			release.custom_minimum_size=Vector2(68,64)
			GroveUI.quiet(release,Color("ad816d"))
			release.disabled=not Management.can_release(d,squad)
			release.pressed.connect(func(): confirm_release(d.id))
			row.add_child(release)
	label(overlay,"성장 재료 %d · 육성 3개 → 경험치 +40 · 즐겨찾기는 자연으로 보낼 수 없습니다." % materials,Vector2(230,600),17)
	if camp:
		button(overlay,"일괄 작별",Rect2(230,630,220,55),func(): show_bulk_release(true))
		button(overlay,"특수개체 합성",Rect2(480,630,380,55),func(): show_synthesis())
	button(overlay,"완료",Rect2(1000,630,210,55),func(): save_game(); show_camp() if camp else clear_overlay())

func growth_card(d,x,caption):
	var card=panel(overlay,Rect2(x,265,465,305),Color("202823"))
	card.add_theme_stylebox_override("panel",GroveUI.frame(Color("202823"),Loot.color(d),2))
	label(overlay,caption,Vector2(x+20,280),18)
	label(overlay,"[%s] %s  Lv.%d" % [Loot.title(d),NAMES[d.kind],d.level],Vector2(x+20,320),25).add_theme_color_override("font_color",Loot.color(d))
	label(overlay,"최대 체력  %d\n공격력       %.1f" % [roundi(max_hp(d)),attack(d)],Vector2(x+20,380),22)
	var bar=health_bar(overlay,Rect2(x+20,478,425,8))
	bar.max_value=maxi(1,Management.needed_xp(d))
	bar.value=0 if Loot.is_max_level(d) else d.xp
	label(overlay,"최대 레벨" if Loot.is_max_level(d) else "경험치 %d / %d" % [d.xp,Management.needed_xp(d)],Vector2(x+20,499),19)
	label(overlay,("승급 준비 완료" if Loot.star(d)<3 else "합성 재료 조건 충족") if Loot.is_max_level(d) else "다음 레벨까지 %d" % maxi(0,Management.needed_xp(d)-d.xp),Vector2(x+20,531),17)

func show_training(id,result={}):
	if mode!="camp": notify("육성은 캠프에서 할 수 있습니다."); return
	var d=find_owned(id)
	if d.is_empty(): return
	if Special.pending(d): show_special_choice(id); return
	var before=d if result.is_empty() else result.before
	var after=Management.project(d,40) if result.is_empty() else result.after
	modal("동료 육성  ·  "+NAMES[d.kind],"경험치만 성장합니다. 성급·고정 특성·기존 옵션은 바뀌지 않습니다.","training",open_roster)
	label(overlay,"보유 성장 재료 %d · 1회 3개 · 경험치 +40" % materials,Vector2(235,220),20)
	growth_card(before,230,"육성 전")
	growth_card(after,745,"육성 후 예상" if result.is_empty() else "육성 완료")
	var summary="레벨이 오르면 최대 체력과 공격력이 증가합니다."
	if after.level>before.level:
		summary="Lv.%d → %d · 최대 체력 +%d · 공격력 +%.1f" % [before.level,after.level,roundi(max_hp(after))-roundi(max_hp(before)),attack(after)-attack(before)]
	elif not result.is_empty(): summary="경험치 +40 획득 · 다음 레벨까지 %d" % (Management.needed_xp(d)-d.xp)
	label(overlay,summary,Vector2(235,586),19)
	var action=button(overlay,("%d성으로 승급" % (Loot.star(d)+1)) if Loot.is_max_level(d) and Loot.star(d)<3 else (("5성 진화" if Loot.star(d)==4 else "6성 진화" if Loot.star(d)==5 else "최고 성급" if Loot.star(d)==6 else "4성 합성") if Loot.is_max_level(d) else ("재료 3개로 육성" if result.is_empty() else "한 번 더 · 미리보기")),Rect2(230,630,350,55),func(): EvolutionUI.show_page(self,id) if Loot.is_max_level(d) and Loot.star(d) in [4,5] else show_promotion(id) if Loot.is_max_level(d) and Loot.star(d)<3 else (show_synthesis([id],id) if Loot.is_max_level(d) and Loot.star(d)==3 else (train_companion(id) if not Loot.is_max_level(d) and result.is_empty() else show_training(id))))
	action.disabled=(Loot.is_max_level(d) and Loot.star(d)>5) or (not Loot.is_max_level(d) and result.is_empty() and materials<3)
	var target_action=button(overlay,"목표 레벨 육성",Rect2(600,630,285,55),func(): show_target_training(id))
	target_action.disabled=Loot.is_max_level(d)
	button(overlay,"동료 목록으로",Rect2(925,630,285,55),open_roster)

func show_target_training(id):
	if mode!="camp": return
	var d=find_owned(id)
	if d.is_empty(): return
	modal("목표 레벨까지 육성 · "+NAMES[d.kind],"재료 3개마다 경험치 40 · 목표에 필요한 횟수만 사용하고 남는 경험치는 보존합니다.","target_training",func(): show_training(id))
	label(overlay,"현재 Lv.%d · 보유 성장 재료 %d개" % [d.level,materials],Vector2(240,245),23)
	label(overlay,"목표 레벨",Vector2(240,325),21)
	var target=SpinBox.new()
	target.name="TargetLevel"
	target.position=Vector2(450,310)
	target.size=Vector2(240,65)
	target.min_value=int(d.level)+1
	target.max_value=Loot.max_level(d) if Loot.max_level(d)>0 else int(d.level)+1000
	target.allow_greater=false
	target.step=1
	target.value=int(d.level)+1
	overlay.add_child(target)
	button(overlay,"필요 재료 · 결과 확인",Rect2(240,500,450,65),func(): preview_target_training(id,int(target.value)))

func preview_target_training(id,target):
	if mode!="camp": return
	var d=find_owned(id)
	var plan=Management.target_plan(d,target)
	if plan.is_empty(): return
	modal("목표 레벨 육성 확인","성급·고정 특성·기존 옵션은 유지됩니다. 확인 후 아래 재료를 한 번에 사용합니다.","target_preview",func(): show_target_training(id))
	label(overlay,"Lv.%d → %d · %d회분 · 필요 재료 %d / 보유 %d · 경험치 +%d" % [d.level,target,plan.charges,plan.cost,materials,plan.xp],Vector2(235,222),20)
	growth_card(d,230,"육성 전")
	growth_card(plan.after,745,"일괄 육성 후 예상")
	label(overlay,"남는 경험치도 동료에게 보존됩니다. 목표 레벨이 바뀌면 다시 계산하세요.",Vector2(235,586),17)
	var apply=button(overlay,"재료 %d개로 일괄 육성" % plan.cost,Rect2(230,630,450,55),func(): train_to_level(id,target,plan.before))
	apply.disabled=materials<plan.cost
	button(overlay,"목표 다시 선택",Rect2(925,630,285,55),func(): show_target_training(id))

func show_promotion(id):
	if mode!="camp": return
	var d=find_owned(id)
	var after=Management.promotion_preview(d)
	if after.is_empty(): return
	modal("동료 승급 확인 · "+NAMES[d.kind],"외형과 인연은 유지됩니다. 다음 성급 Lv.1부터 더 큰 레벨 성장폭을 얻습니다.","promotion",func(): show_training(id))
	growth_card(d,230,"승급 전 · %d성 만렙" % Loot.star(d))
	growth_card(after,745,"승급 후 · %d성 Lv.1" % Loot.star(after))
	label(overlay,"승급 직후 체력·공격력은 낮아집니다. %d성은 레벨업 성장폭이 더 커 빠르게 이전 전투력을 회복합니다." % Loot.star(after),Vector2(235,586),17)
	button(overlay,"%d성으로 승급" % Loot.star(after),Rect2(230,630,350,55),func(): promote_companion(id,d.duplicate(true)))
	button(overlay,"취소 · 육성으로",Rect2(925,630,285,55),func(): show_training(id))

func promote_companion(id,expected):
	if mode!="camp": return false
	var d=find_owned(id)
	if d.is_empty() or int(d.get("star",1))!=int(expected.get("star",-1)) or int(d.level)!=int(expected.get("level",-1)) or int(d.xp)!=int(expected.get("xp",-1)):
		notify("동료의 성장 정보가 바뀌었습니다. 승급 결과를 다시 확인하세요.")
		return false
	var promoted=Management.promotion_preview(d)
	if promoted.is_empty(): return false
	var before_star=Loot.star(d)
	d.star=promoted.star
	d.grade=promoted.grade
	d.level=promoted.level
	d.xp=promoted.xp
	d.erase("legacy_overcap")
	for u in units:
		if u.data.id==id:
			u.maxhp=max_hp(d)
			u.hp=minf(u.hp,u.maxhp)
	save_game()
	show_training(id)
	notify("%d성 → %d성 승급 · Lv.1부터 다시 성장합니다." % [before_star,Loot.star(d)])
	return true

func train_to_level(id,target,expected):
	if mode!="camp": return false
	var d=find_owned(id)
	if d.is_empty(): return false
	if int(d.level)!=int(expected.level) or int(d.xp)!=int(expected.xp):
		notify("동료의 성장 정보가 바뀌었습니다. 결과를 다시 확인하세요.")
		show_target_training(id)
		return false
	var plan=Management.target_plan(d,target)
	if Special.pending(d) or plan.is_empty() or materials<plan.cost: return false
	materials-=plan.cost
	var old_level=d.level
	d.level=plan.after.level
	d.xp=plan.after.xp
	for u in units:
		if u.data.id==id: u.maxhp=max_hp(d)
	save_game()
	show_training(id,{"before":plan.before,"after":d.duplicate(true)})
	notify("Lv.%d → %d · 재료 %d개 사용 · 경험치 +%d" % [old_level,d.level,plan.cost,plan.xp])
	return true

func train_companion(id):
	if mode!="camp" or materials<3: return false
	var d=find_owned(id)
	if d.is_empty() or Special.pending(d) or Loot.is_max_level(d): return false
	var before=d.duplicate(true)
	materials-=3
	gain_xp(d,40)
	save_game()
	show_training(id,{"before":before,"after":d.duplicate(true)})
	return true

func select_swap(id):
	if not squad.has(id): return
	if chosen_swap<0:
		chosen_swap=id
		notify("교체할 다른 동료를 누르세요.")
		label(overlay,"선택: "+NAMES[find_owned(id).kind]+" → 다른 동료를 눌러 교체",Vector2(230,650),18)
	else:
		var a=squad.find(chosen_swap)
		var b=squad.find(id)
		var temp=squad[a]
		squad[a]=squad[b]
		squad[b]=temp
		if mode!="camp" and a<units.size() and b<units.size():
			var u=units[a]
			units[a]=units[b]
			units[b]=u
			for x in active_units(): x.pos=player.pos+Vector2(rng.randf_range(-60,60),50)
		save_game()
		open_roster()

func toggle_squad(id):
	if squad.has(id): squad.erase(id)
	elif squad.size()<6: squad.append(id)
	save_game()

func show_bulk_release(reset=false):
	if mode!="camp": return
	if reset:
		bulk_selection.clear()
		bulk_scroll=0
	preload("res://ui/bulk_release.gd").show_page(self)

func toggle_bulk_release(id,checked):
	var scroll=overlay.get_node_or_null("BulkReleaseScroll")
	if scroll!=null: bulk_scroll=scroll.scroll_vertical
	if checked and Management.can_release(find_owned(id),squad):
		if not bulk_selection.has(id): bulk_selection.append(id)
	else: bulk_selection.erase(id)
	show_bulk_release()

func confirm_bulk_release():
	if mode!="camp" or bulk_selection.is_empty(): return
	preload("res://ui/bulk_release.gd").show_confirmation(self,bulk_selection.duplicate())

func commit_bulk_release(ids):
	if mode!="camp" or ids.is_empty(): return false
	var selected=[]
	for id in ids:
		if selected.has(id): continue
		if not Management.can_release(find_owned(id),squad):
			notify("선택한 동료 정보가 달라졌습니다. 동행·즐겨찾기를 다시 확인하세요.")
			show_bulk_release()
			return false
		selected.append(id)
	var reward=0
	for id in selected: reward+=Management.farewell_reward(find_owned(id))
	owned=owned.filter(func(d): return not selected.has(d.id))
	materials+=reward
	bulk_selection.clear()
	save_game()
	open_roster()
	notify("%d마리와 작별했습니다. 함께한 인연으로 성장 재료 %d개가 남았습니다." % [selected.size(),reward])
	return true

func release_companion(id):
	var d=find_owned(id)
	if mode!="camp" or not Management.can_release(d,squad): return false
	var reward=Management.farewell_reward(d)
	owned.erase(d)
	materials+=reward
	save_game()
	open_roster()
	return true

func confirm_release(id):
	var d=find_owned(id)
	if mode!="camp" or not Management.can_release(d,squad):
		notify("동행 중이거나 즐겨찾기한 동료는 자연으로 보낼 수 없습니다.")
		return
	modal("동료를 자연으로 보낼까요?", "[%s] %s Lv.%d · %s" % [Loot.title(d),NAMES[d.kind],d.level,d.trait],"",open_roster)
	label(overlay,"이 동료는 자연으로 돌아갑니다.\n함께한 인연으로 성장 재료 %d개가 남습니다.\n동행 중이거나 즐겨찾기한 동료는 자연으로 보낼 수 없습니다." % Management.farewell_reward(d),Vector2(230,300),22)
	button(overlay,"자연으로 보내기",Rect2(300,560,350,65),func(): release_companion(id))
	button(overlay,"취소",Rect2(750,560,300,65),open_roster)

func confirm_return():
	if mode!="stage" and mode!="tutorial": return
	modal("탐험을 마치고 귀환할까요?", "이미 획득한 동료와 재료는 유지됩니다. 클리어 보상은 지급되지 않습니다.","",open_game_menu)
	button(overlay,"귀환",Rect2(300,500,350,65),show_camp)
	button(overlay,"취소 · 메뉴로",Rect2(750,500,350,65),open_game_menu)

func confirm_reset():
	modal("새 여정 시작", "이 기기의 프로토타입 저장 데이터를 초기화합니다.","",show_camp)
	button(overlay,"초기화",Rect2(300,500,350,65),func(): expedition.clear(); preparation_seen=false; owned.clear(); squad.clear(); units.clear(); discovered.clear(); cleared_stages.clear(); campaign_progress.clear(); current_route.clear(); seen_species.clear(); materials=0; tutorial_done=false; unlocked=false; next_id=1; show_camp())
	button(overlay,"취소",Rect2(750,500,350,65),show_camp)

func update_hud():
	hud.visible=mode!="result" and mode!="tutorial_practice"
	if not hud.visible: return
	for b in party_buttons+town_hidden_labels: b.visible=mode!="camp"
	heal_button.visible=mode!="camp"
	buff_button.visible=mode!="camp"
	if mode=="camp":
		status_label.text="잎그늘 쉼터 · 안전 지대"
		player_hp_bar.value=player_hp_bar.max_value
		quest_label.text="동료 쉼터 · 편성 / 육성    →    동쪽 사냥길\nWASD / 이동 스틱 · 가까이에서 F / 상호작용"
		if not tutorial_done: quest_label.text="첫 걸음  ·  동쪽 사냥길 → 첫 인연 만나기\nWASD / 왼쪽 이동 스틱 · 가까이에서 F / 화면 버튼"
		elif not unlocked and not preparation_seen: quest_label.text="탐험 준비  ·  동료 쉼터에서 역할·편성 확인\n재료 3개 → 경험치 40 · 준비되면 동쪽 사냥길"
		toast_label.text=save_notice if not save_notice.is_empty() else message if message_time>0 else ""
		boss_panel.hide()
		boss_label.hide()
		boss_hp_bar.hide()
		loot_result_button.hide()
		var point=Town.nearest(player.pos)
		interact_button.visible=point>=0
		interact_progress.hide()
		if point>=0: interact_button.text=Town.LABELS[point]+" [F]"
		return
	loot_result_button.visible=recent_capture_id>0 and not find_owned(recent_capture_id).is_empty()
	loot_result_button.disabled=in_combat or mode=="tutorial"
	if loot_result_button.visible: loot_result_button.text="새로운 인연 · "+Loot.title(find_owned(recent_capture_id))+" / 상세 확인"
	status_label.text="드루이드  ·  %d / %d" % [player.hp,player.maxhp]
	player_hp_bar.max_value=player.maxhp
	player_hp_bar.value=player.hp
	quest_label.text=("첫 인연 · 쉬는 야수에게 교감 [F / 화면 버튼]" if not captures.is_empty() else "동료와 협동 연습 · Q 회복 / E 강화 / 동료 초상" if tutorial_species=="practice" else "첫 인연 · 야수에게 다가가 경계를 누그러뜨리세요") if mode=="tutorial" else (trail.area(player.pos)+" · "+trail.progress_text(enemies)+" · 동행 "+str(squad.size())+"/6\n%s · 제압 %d · %02d:%02d") % [trail.objective(enemies,player.pos),kills,int(stage_time)/60,int(stage_time)%60]
	toast_label.text=message if message_time>0 else ""
	boss_label.text=""
	for e in enemies:
		if e.boss and e.hp>0 and e.active:
			boss_label.text=(Campaign.STAGES[current_stage].boss if current_route.is_empty() else Routes.profile(current_route).get("boss","정예"))+"  ·  %d / %d" % [e.hp,e.maxhp]
			boss_hp_bar.max_value=e.maxhp
			boss_hp_bar.value=e.hp
			if e.get("intro",0.0)>0: boss_label.text+="\n"+("우두머리 · 경계 중" if Species.NEW.has(e.kind) else "거대한 발자국의 주인 · 경계 중")
			elif e.wind>0: boss_label.text+="\n"+("지면 강타! 원 밖으로 이동" if Species.NEW.has(e.kind) and e.attack_kind=="slam" else "표적 공격! 표시된 원을 피하세요" if Species.NEW.has(e.kind) else "발구르기! 원 밖으로 이동" if e.attack_kind=="stomp" else "돌진! 옆으로 피하세요")
			elif e.get("dash",0.0)>0: boss_label.text+="\n돌진 중!"
			else: boss_label.text+="\n공격 기회"
			break
	boss_panel.visible=not boss_label.text.is_empty()
	boss_hp_bar.visible=boss_panel.visible
	boss_label.visible=boss_panel.visible
	for i in range(4):
		var b=party_buttons[i]
		if i<units.size():
			var u=units[i]
			b.configure(textures[u.data.kind],NAMES[u.data.kind],Roles.LABELS[u.data.kind],u.hp,u.maxhp,u.skill,Loot.grade(u.data),10.0*(1.0-Loot.bonus(u.data,"skill_haste"))*Special.haste(u.data))
			b.insight(u.data.trait,Roles.describe(u.data,Loot),u.get("role_action",""),u.get("role_flash",0.0))
			b.disabled=u.hp<=0 or u.skill>0 or revive_target>=0
		else:
			b.configure(null,"빈자리","교감으로 합류",0,1,0)
			b.disabled=true
	heal_button.refresh(heal_cd)
	buff_button.refresh(buff_cd)
	heal_button.disabled=heal_cd>0 or revive_target>=0
	buff_button.disabled=buff_cd>0 or revive_target>=0
	var down=closest_down()
	var cap=closest_capture()
	interact_button.visible=down>=0 or cap>=0 or (mode=="stage" and not in_combat and trail.near_rest(player.pos)) or route_can_exit()
	interact_progress.visible=down>=0
	interact_progress.value=revive_progress
	if down>=0:
		interact_button.text="길게 눌러 소생 [F]\n%.1f / 3초" % revive_progress
	elif cap>=0: interact_button.text=NAMES[captures[cap].kind]+" 교감 [F]"
	else: interact_button.text="쉼터 · 편성 점검 [F]"
	if mode=="tutorial" and tutorial_species=="practice" and not overlay.visible and not dropdown.popup.visible:
		var alive=false
		for e in enemies:
			if e.hp>0: alive=true
		if not alive:
			tutorial_species=""
			expedition.close(owned,materials,kills,stage_time,"첫 인연 · 협동 연습 완료",units)
			show_camp()
			show_run_report()

	if route_can_exit() and cap<0: interact_button.text="길 잇기 [F]"

func _input(event):
	if event is InputEventScreenTouch and not event.pressed:
		if event.index==stick_id:
			stick_id=-1
			stick=Vector2.ZERO
		if event.index==revive_touch_id:
			holding_revive=false
			revive_touch_id=-1
	if event is InputEventScreenTouch and event.pressed and not overlay.visible and not dropdown.popup.visible:
		if interact_button.visible and interact_button.get_global_rect().has_point(event.position):
			revive_touch_id=event.index
	if event is InputEventScreenDrag and event.index==stick_id:
		stick=((event.position-Vector2(140,680))/72.0).limit_length()
	if event is InputEventMouseButton and event.device!=-1 and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		mouse_stick=false
		if stick_id<0: stick=Vector2.ZERO
		holding_revive=false

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		stick=Vector2.ZERO
		stick_id=-1
		mouse_stick=false
		holding_revive=false
		revive_touch_id=-1

func _unhandled_input(event):
	if dropdown.popup.visible:
		if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE: dropdown.close()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q: cast_heal()
			KEY_E: cast_buff()
			KEY_1: use_companion_skill(0)
			KEY_2: use_companion_skill(1)
			KEY_3: use_companion_skill(2)
			KEY_4: use_companion_skill(3)
			KEY_F: interact()
			KEY_TAB:
				if not overlay.visible: open_roster()
			KEY_I:
				if menu_page=="inventory": resume_game()
				elif not overlay.visible or not menu_page.is_empty(): open_inventory()
			KEY_ESCAPE:
				if overlay.visible: navigate_back()
				elif mode in ["camp","stage","tutorial"]: dropdown.open()
	if overlay.visible: return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(Vector2(140,680))<125:
			stick_id=event.index
			stick=(event.position-Vector2(140,680))/72.0
		elif not event.pressed and event.index==stick_id:
			stick_id=-1
			stick=Vector2.ZERO
	if event is InputEventScreenDrag and event.index==stick_id:
		stick=((event.position-Vector2(140,680))/72.0).limit_length()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.distance_to(Vector2(140,680))<125:
			mouse_stick=true
			stick=((event.position-Vector2(140,680))/72.0).limit_length()
		elif not event.pressed:
			mouse_stick=false
			stick=Vector2.ZERO
	if event is InputEventMouseMotion and mouse_stick:
		stick=((event.position-Vector2(140,680))/72.0).limit_length()

func backup_save():
	if not FileAccess.file_exists(save_path): return true
	var original = FileAccess.get_file_as_bytes(save_path)
	var suffix = Time.get_datetime_string_from_system().replace(":","-")+"-"+str(Time.get_ticks_usec())
	var target = save_path+".backup-"+suffix
	var file = FileAccess.open(target,FileAccess.WRITE)
	if file==null:
		save_blocked = true
		save_notice = "저장 백업에 실패해 자동 저장을 중지했습니다."
		return false
	file.store_buffer(original)
	file.close()
	save_backup_path = target
	return true

func repair_party():
	var result = SaveData.normalize({"owned":owned,"squad":squad,"next_id":next_id,"discovered":discovered},STATS.keys())
	if result.repaired:
		if backup_save(): save_notice = "저장 정보를 새 기능에 맞게 정리했습니다. 원본은 백업했습니다."
	discovered=result.discovered
	owned = result.owned
	squad = result.squad
	next_id = result.next_id

func save_payload():
	return {"version":2,"owned":owned,"squad":squad,"materials":materials,"tutorial_done":tutorial_done,"unlocked":unlocked,"next_id":next_id,"discovered":discovered,"cleared_stages":cleared_stages,"seen_species":seen_species,"campaign_progress":Routes.progress_for(self)}

func persist_payload(data):
	if save_blocked: return false
	if is_test or screenshot_mode: return true
	var temporary=save_path+".writing"
	var f=FileAccess.open(temporary,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data))
	f.flush()
	var written=f.get_error()==OK
	f.close()
	if not written: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(save_path))==OK

func save_game():
	return persist_payload(save_payload())

func load_game():
	if not FileAccess.file_exists(save_path): return
	var d=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not d is Dictionary or int(d.get("version",0)) not in [1,2]:
		save_blocked = true
		save_notice = "저장 데이터를 읽을 수 없어 원본을 유지하고 자동 저장을 중지했습니다."
		return
	var result = SaveData.normalize(d,STATS.keys())
	if d.has("campaign_progress") and (not d.campaign_progress is Dictionary or SaveData.id_value(d.campaign_progress.get("version",0))!=1):
		save_blocked=true
		save_notice="알 수 없는 탐험 진행 형식입니다. 원본을 유지하고 자동 저장을 중지했습니다."
		return
	if result.repaired or not d.has("campaign_progress"):
		if backup_save(): save_notice = "저장 정보를 새 기능에 맞게 정리했습니다. 원본은 백업했습니다."
	campaign_progress=Routes.normalize(d)
	discovered=result.discovered
	owned=result.owned
	squad=result.squad
	materials=SaveData.integer(d.get("materials",0),0)
	tutorial_done=d.get("tutorial_done",false)
	unlocked=d.get("unlocked",false)
	cleared_stages=Campaign.progress(d)
	seen_species=[]
	var history=d.get("seen_species",[])
	if history is Array:
		for kind in history:
			if kind in Species.kinds() and kind not in seen_species: seen_species.append(kind)
	next_id=result.next_id

func _draw():
	if mode=="camp":
		Town.draw(self)
		return
	draw_rect(Rect2(0,0,1440,810),Color("282a2b"))
	draw_texture_rect(stage_background if stage_background!=null else textures["valley"],Rect2(-cam.round(),WORLD_SIZE),false)
	if mode=="stage": trail.draw(self)
	for e in enemies: combat_feedback.draw_tell(self,e,cam)
	var nearest_cap=closest_capture()
	for i in captures.size():
		var c=captures[i]
		if c.kind=="bat":
			creature_visual.draw(self,c.pos-cam,sprite_height(c.kind),1,Color("d5dfbf"),c.kind,{"hp":1})
			draw_arc(c.pos-cam,22,0,TAU,20,Loot.color(c),2,false)
		else: capture_visual.draw(self,c.pos-cam,c.kind,sprite_height(c.kind),clock,i==nearest_cap,Loot.grade(c))
		if i==nearest_cap:
			text_at(Loot.title(c)+" · 교감 [F]",c.pos-cam+Vector2(-40,-sprite_height(c.kind)-20),15,Loot.color(c))
	var actors=[]
	actors.append({"kind":"druid","pos":player.pos,"hp":player.hp,"maxhp":player.maxhp,"face":player.face,"size":sprite_height("druid"),"ally":true,"state":player})
	for u in active_units():
		actors.append({"kind":u.data.kind,"pos":u.pos,"hp":u.hp,"maxhp":u.maxhp,"face":u.face,"size":sprite_height(u.data.kind),"ally":true,"unit":u,"state":u})
	for e in enemies:
		if e.hp>0 or e.get("death",0.0)>0: actors.append({"kind":e.kind,"pos":e.pos,"hp":e.hp,"maxhp":e.maxhp,"face":e.face,"size":sprite_height(e.kind,e.boss),"ally":false,"state":e})
	actors.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	for a in actors:
		var p=a.pos-cam
		if a.has("unit") and a.hp>0: preload("res://ui/rarity_aura.gd").draw(self,p,a.size,a.unit.data,clock)
		if p.x < -120 or p.x>1560 or p.y < -120 or p.y>930: continue
		draw_set_transform(p,0,Vector2(1,0.35))
		draw_circle(Vector2.ZERO,a.size*0.38,Color(0.1,0.2,0.12,0.22))
		draw_set_transform(Vector2.ZERO)
		var state=a.state
		var hit=state.get("hit",0.0)
		var swing=state.get("swing",0.0)
		var col=Color.WHITE if a.hp>0 else Color(0.5,0.55,0.5,0.7)
		if hit>0: col=Color(1.65,1.3,1.15)
		var bob=sin(clock*10+a.pos.x)*2.4 if state.get("walk",false) else 0.0
		var tilt=sin(clock*10+a.pos.x)*0.035 if state.get("walk",false) else 0.0
		var deformation=Vector2.ONE
		if swing>0:
			deformation=Vector2(1.0+sin(swing/0.22*PI)*0.14,1.0-sin(swing/0.22*PI)*0.09)
			tilt+=a.face*sin(swing/0.22*PI)*0.08
		if a.kind in PIXEL_KINDS:
			bob=0.0
			tilt=0.0
			deformation=Vector2.ONE
		var offset=state.get("recoil",Vector2.ZERO)*sin(clampf(hit/0.18,0.0,1.0)*PI)
		if a.hp<=0:
			tilt=-0.75*a.face
			if not a.ally: col.a=state.get("death",0.0)/0.32
		var front_weapon=a.kind=="druid" and weapon_visual.in_front(state)
		if a.kind=="druid" and not front_weapon: weapon_visual.draw(self,p+offset,a.size,a.face,col,state)
		if Species.NEW.has(a.kind):
			creature_visual.draw(self,p+offset,a.size,a.face,col,a.kind,state)
		elif motion_actions.draw(self,p+offset,a.size,a.face,col,a.kind,state):
			pass
		elif a.kind=="boar":
			# The rig owns breathing, gait and attack poses; never stack whole-image shaking.
			boar_rig.draw(self,p+offset,a.size,a.face,col,state)
		elif a.kind=="druid":
			druid_rig.draw(self,p+offset,a.size,a.face,col,state,druid_body)
		elif animal_rigs.has(a.kind):
			animal_rigs[a.kind].draw(self,p+offset,a.size,a.face,col,state,textures[a.kind])
		else:
			draw_sprite(a.kind,p+Vector2(0,bob)+offset,a.size,a.face,col,tilt,deformation)
		if a.has("unit") and Special.ready(a.unit.data): preload("res://ui/special_visual.gd").mark(self,p+offset,a.size,a.unit.data)
		if front_weapon: weapon_visual.draw(self,p+offset,a.size,a.face,col,state)
		if state.get("special_barrier",0.0)>0:
			draw_arc(p-Vector2(0,a.size*0.4),a.size*0.45,0,TAU,16,Color("a2d9e0"),1,false)
		var bar_height=motion_actions.boss_action.headroom(state,a.size)
		var bar=Rect2(p+Vector2(-27,-bar_height-10),Vector2(54,6))
		draw_rect(bar,Color("25392b"))
		bar.size.x*=maxf(0,a.hp/a.maxhp)
		draw_rect(bar,Color("b5e280") if a.ally else Color("eb8469"))
		if a.hp<=0 and a.ally: text_at("소생 필요",p+Vector2(-33,20),14,Color("f4d89b"))
		if a.has("unit"):
			if a.unit.buff>0: draw_arc(p,33,0,TAU,24,Color("ffd478"),2,true)
			if a.unit.shield>0: draw_arc(p-Vector2(0,25),40,0,TAU,24,Color("a9e5e5"),3,true)
	if not overlay.visible and (mode=="stage" or mode=="tutorial"):
		var heal_target=lowest_ally(player.pos,430)
		if not heal_target.is_empty() and heal_target.hp<heal_target.maxhp:
			draw_arc(heal_target.pos-cam,29,0,TAU,28,Color("d7f3ad"),2,true)
	for f in effects:
		var elapsed=f.duration-f.time
		var col=f.color
		col.a=clampf(f.time/0.3,0,1)
		if f.get("ring",false):
			draw_arc(f.b-cam,f.radius*(0.6+elapsed/f.duration*0.4),0,TAU,48,col,5,true)
		else:
			text_at(f.text,f.b-cam+Vector2(-15,-70-elapsed*32),20,col)
	if not overlay.visible:
		combat_feedback.draw(self,cam,heading_font)
		if player.get("channeling",false) and revive_target>=0:
			combat_feedback.draw_channel(self,player.pos,units[revive_target].pos,revive_progress,cam)
	if hud.visible:
		draw_minimap()
		GroveUI.draw_stick(self,stick)
	if revive_target>=0:
		var p=player.pos-cam+Vector2(-42,20)
		draw_rect(Rect2(p,Vector2(84,9)),Color("213f32"))
		draw_rect(Rect2(p,Vector2(84*revive_progress/3.0,9)),Color("bcf3b1"))
	if mode=="stage" and hud.visible and not overlay.visible: trail.draw_guidance(self)

func draw_minimap():
	if mode=="stage" and not current_route.is_empty():
		trail.draw_minimap(self)
		return
	var box=Rect2(1190,104,225,135)
	draw_style_box(map_style(),box)
	text_at(("계곡" if current_stage==1 else "채석장" if current_stage==2 else "묘역")+" 지도 · 옆길은 선택",box.position+Vector2(12,22),14,Color("edf0d4"))
	var origin=box.position+Vector2(12,35)
	var scale_map=Vector2(201.0/2900.0,88.0/1650.0)
	if mode=="stage":
		var route=[Vector2(340,800),Trail.PACKS[0],Trail.PACKS[1],Trail.PACKS[3],Trail.PACKS[5],Vector2(2590,850)]
		for i in range(route.size()-1):
			draw_line(origin+route[i]*scale_map,origin+route[i+1]*scale_map,Color("b2a879"),2,false)
		for branch in [[Trail.PACKS[1],Trail.NORTH],[Vector2(1720,820),Trail.SOUTH],[Trail.PACKS[3],Trail.REST],[Trail.REST,Trail.PACKS[5]]]:
			for i in 4:
				draw_line(origin+branch[0].lerp(branch[1],i/4.0)*scale_map,origin+branch[0].lerp(branch[1],(i+0.5)/4.0)*scale_map,Color("8c9372"),1,false)
	else:
		draw_line(origin+Vector2(0,810)*scale_map,origin+Vector2(2900,810)*scale_map,Color("b2a879"),3,true)
	for e in enemies:
		if e.hp>0:
			var color=Color("ffbc67") if e.boss else Color("e78a75")
			if mode=="stage" and not trail.engageable(e): color=Color("8e947d")
			draw_circle(origin+e.pos*scale_map,5 if e.boss else 3,color)
	for c in captures: draw_arc(origin+c.pos*scale_map,4,0,TAU,12,Color("ffec96"),1.5,true)
	if mode=="stage":
		for point in [Trail.NORTH,Trail.SOUTH,Trail.REST]: draw_circle(origin+point*scale_map,2,Color("d9c68b"))
		for pack in Trail.CORE_PACKS:
			var cleared=trail.cleared_pack(enemies,pack)
			draw_circle(origin+Trail.PACKS[pack]*scale_map,3,Color("69735d") if cleared else Color("e0c27d"))
		var next=trail.next_stop(enemies)
		draw_arc(origin+next.pos*scale_map,6,0,TAU,16,Color("e9d49b"),1,false)
	for u in active_units():
		draw_circle(origin+u.pos*scale_map,2.5,Color("bce78b") if u.hp>0 else Color("777e71"))
	draw_circle(origin+player.pos*scale_map,4,Color("eaf7ea"))
	var visible_rect=Rect2(cam*scale_map,Vector2(1440,810)*scale_map)
	draw_rect(Rect2(origin+visible_rect.position,visible_rect.size),Color(0.8,0.9,0.8,0.35),false,1)

func map_style():
	return GroveUI.frame(Color("202823ef"))

func sprite_height(kind,boss=false):
	if Species.NEW.has(kind): return Species.NEW[kind].height*(1.6 if boss else 1.0)
	var h=48 if kind=="boar" else textures[kind].get_height()
	return h*(2 if boss else 1)

func draw_sprite(kind,p,height,face,col,tilt=0.0,deformation=Vector2.ONE):
	if kind=="boar":
		boar_rig.draw(self,p,height,face,col,{})
		return
	var tex=textures[kind]
	if kind in PIXEL_KINDS:
		height=tex.get_height()*maxi(1,roundi(float(height)/tex.get_height()))
		p=p.round()
	var ratio=float(tex.get_width())/tex.get_height()
	var w=height*ratio
	draw_set_transform(p,tilt,Vector2(face,1)*deformation)
	draw_texture_rect(tex,Rect2(-w/2,-height,w,height),false,col)
	draw_set_transform(Vector2.ZERO)

func text_at(txt,p,size,col):
	draw_string(font,p,txt,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)

func demo_scene():
	owned.clear()
	squad.clear()
	for kind in ["boar","turtle","fox","deer"]:
		squad.append(make_owned(kind,2).id)
	start_stage(false)
	player.pos=Vector2(930,790)
	units[0].pos=Vector2(1020,690)
	units[1].pos=Vector2(1110,710)
	units[2].pos=Vector2(850,830)
	units[3].pos=Vector2(1040,850)
	enemies.clear()
	spawn_enemy("boar",Vector2(1220,620),4,true)
	var boss=enemies[0]
	boss.active=true
	boss.pattern=1
	begin_boss_attack(boss,player)
	units[1].hp=units[1].maxhp*0.65
	units[1].shield=4.0
	units[2].buff=5.0
	in_combat=true
	message=""
	message_time=0.0
	fx(player.pos,units[1].pos,Color("a6f1aa"),"+55",3.0)

func take_screenshot():
	if has_meta("shot"): return
	set_meta("shot",true)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preview.png")
	get_tree().quit()

func run_tests():
	var failures=[]
	for kind in STATS.keys():
		var d=make_owned(kind,3)
		if max_hp(d)<=0 or attack(d)<=0: failures.append("invalid stats")
	owned.clear()
	squad.clear()
	for i in range(6): squad.append(make_owned("boar",1).id)
	start_stage(false)
	if units.size()!=6 or active_units().size()!=4: failures.append("6/4 party")
	var old=units[5].data.xp
	hit_enemy(enemies[0],99999,player.pos)
	if units[5].data.xp<=old: failures.append("reserve XP")
	captures=[{"kind":"fox","pos":player.pos,"level":3}]
	var count=owned.size()
	interact()
	if owned.size()!=count+1 or squad.size()!=6: failures.append("overflow capture")
	if owned[-1].level!=3: failures.append("wild level")
	units[0].hp=0.0
	units[0].pos=player.pos
	holding_revive=true
	enemies.clear()
	spawn_enemy("wolf",Vector2(2600,800),1,true)
	for i in range(61): update_game(0.05)
	if units[0].hp<=0: failures.append("revive")
	if units[0].hp>units[0].maxhp*0.31: failures.append("revive health")
	holding_revive=false
	var saved_count=owned.size()
	finish(false)
	if owned.size()!=saved_count: failures.append("failure rewards")
	var fixed=owned[0].trait
	gain_xp(owned[0],100)
	if fixed!=owned[0].trait: failures.append("trait mutation")
	owned.clear()
	squad.clear()
	units.clear()
	tutorial_done=false
	tutorial_species="fox"
	start_stage(true)
	player.pos=enemies[0].pos-Vector2(80,0)
	hit_enemy(enemies[0],1000,player.pos)
	interact()
	if not tutorial_done or squad.size()!=1: failures.append("tutorial capture")
	start_practice()
	hit_enemy(enemies[-1],1000,player.pos)
	update_hud()
	if mode!="camp": failures.append("tutorial completion")
	open_roster()
	show_camp()
	start_stage(false)
	for i in range(300): update_game(0.016)
	# Attack collision geometry: stomp can be dodged, charge is swept and hits once.
	clear_overlay()
	enemies.clear()
	spawn_enemy("boar",Vector2(1500,800),4,true)
	var boss=enemies[0]
	player.pos=Vector2(1550,800)
	player.hp=180
	begin_boss_attack(boss,player)
	if boss.attack_kind!="stomp" or boss.wind<=0: failures.append("stomp tell")
	player.pos=Vector2(1500,950)
	resolve_enemy_attack(boss)
	if player.hp!=180: failures.append("stomp dodge")
	boss.cd=0
	player.pos=Vector2(1800,800)
	begin_boss_attack(boss,player)
	if boss.attack_kind!="charge": failures.append("pattern alternation")
	resolve_enemy_attack(boss)
	advance_charge(boss,0.4)
	var after_hit=player.hp
	advance_charge(boss,0.05)
	if after_hit!=145 or player.hp!=145: failures.append("swept charge hits once")
	# Leaving the window or ending touch over a UI must not leave movement stuck.
	stick_id=5
	stick=Vector2.RIGHT
	var release=InputEventScreenTouch.new()
	release.index=5
	release.pressed=false
	_input(release)
	if stick!=Vector2.ZERO or stick_id!=-1: failures.append("touch release")
	holding_revive=true
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	if holding_revive: failures.append("focus release")
	# A stale party reference must never produce a unit with Nil HP or empty data.
	var repair_case=SaveData.normalize({"owned":[{"id":1,"kind":"boar","level":3,"xp":42,"trait":"용맹함"}],"squad":[1,999999],"next_id":1},STATS.keys())
	if not repair_case.repaired or repair_case.squad!=[1] or repair_case.owned[0].xp!=42:
		failures.append("saved party repair")
	if not make_unit({},Vector2.ZERO).is_empty(): failures.append("invalid saved unit rejected")
	# Gait must depend on distance and stop during pauses, never world-coordinate noise.
	var rig_actor={"pos":Vector2.ZERO,"hp":100.0,"walk":true}
	boar_rig.advance(rig_actor,0.1)
	if rig_actor.get("rig_phase",0.0)!=0.0: failures.append("rig stationary phase")
	rig_actor.pos.x=boar_rig.stride_pixels/4.0
	boar_rig.advance(rig_actor,0.1)
	if not is_equal_approx(rig_actor.rig_phase,PI/2.0): failures.append("rig distance phase")
	rig_actor.walk=false
	var stopped_phase=rig_actor.rig_phase
	for step in range(30): boar_rig.advance(rig_actor,0.05)
	if rig_actor.rig_move>0.001 or rig_actor.rig_phase!=stopped_phase: failures.append("rig stop blend")
	rig_actor.hp=0
	boar_rig.advance(rig_actor,0.3)
	if not is_equal_approx(rig_actor.rig_down,1.0): failures.append("rig down pose")
	rig_actor.hp=30
	boar_rig.advance(rig_actor,0.3)
	if not is_zero_approx(rig_actor.rig_down): failures.append("rig revive pose")
	# Fast travel uses a wider trot stride without discarding travelled distance.
	var fast_actor={"pos":Vector2.ZERO,"hp":100.0,"walk":true}
	boar_rig.advance(fast_actor,0.05)
	fast_actor.pos.x=10
	boar_rig.advance(fast_actor,0.05)
	if not fast_actor.rig_running or absf(fast_actor.rig_phase-TAU*10.0/boar_rig.trot_stride)>0.001: failures.append("pixel trot distance cadence")
	if boar_rig.display_scale(48)!=1 or boar_rig.display_scale(96)!=2: failures.append("pixel integer scale")
	var idle_image=boar_rig.idle_texture.get_image()
	if idle_image.get_size()!=Vector2i(96,72): failures.append("pixel idle dimensions")
	# Baked pixel walk frames must loop and remain entirely within the sheet.
	if boar_rig.walk_frames.size()!=8: failures.append("boar walk frame count")
	if boar_rig.frame_for_phase(0.0)!=0 or boar_rig.frame_for_phase(TAU)!=0 or boar_rig.frame_for_phase(TAU-0.001)!=7:
		failures.append("boar frame loop")
	for region in boar_rig.walk_frames:
		if region.size.x<=0 or region.size.y<=0 or not Rect2(Vector2.ZERO,Vector2(boar_rig.walk_texture.get_size())).encloses(region):
			failures.append("boar atlas bounds")
	if failures.is_empty(): print("SELF TEST PASS: party limits, reserve XP, overflow capture, wild level, revive, failure retention, fixed traits, tutorial flow, boss tells/dodge/swept charge, touch release")
	else: push_error(str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func show_synthesis(ids=[],main_id=-1,preserve="species"):
	if mode!="camp": return
	SynthesisUI.show_page(self,ids,main_id,preserve)

func preview_synthesis(ids,main_id,preserve):
	if mode!="camp": return
	SynthesisUI.show_result(self,ids,main_id,preserve)

func show_special_choice(id):
	if mode!="camp": return
	if Special.evolution_pending(find_owned(id)):
		EvolutionUI.show_choice(self,id)
	else:
		preload("res://ui/special_choice.gd").show_page(self,id)

func commit_synthesis(ids,main_id,preserve,expected):
	if mode!="camp" or save_blocked: return false
	var plan=Synthesis.preview(owned,squad,ids,main_id,preserve)
	if not plan.error.is_empty() or plan.materials!=expected:
		notify("동료 정보가 바뀌었습니다. 재료와 보호 상태를 다시 확인하세요.")
		return false
	var old_rng=loot_rng.state
	var kind=plan.pool[loot_rng.randi_range(0,plan.pool.size()-1)]
	var result=Loot.roll_special(plan.main,kind,loot_rng)
	var next=[]
	for d in owned:
		if d.id==main_id: next.append(result)
		elif not ids.has(d.id): next.append(d.duplicate(true))
	var payload=save_payload().duplicate(true)
	payload.owned=next
	if not payload.discovered.has(kind): payload.discovered.append(kind)
	if not persist_payload(payload):
		loot_rng.state=old_rng
		notify("저장에 실패해 합성을 취소했습니다. 동료는 소모되지 않았습니다.")
		return false
	owned=next
	discovered=payload.discovered
	units.clear()
	show_special_choice(main_id)
	return true

func commit_special_choice(id,element,unique,expected):
	if mode!="camp" or save_blocked: return false
	var d=find_owned(id)
	if Loot.star(d)!=4 or not Special.pending(d) or d!=expected or not Special.ELEMENTS.has(element) or Special.ELEMENTS[element].get("pending",false) or not Special.choices(d.kind).has(unique): return false
	var next=owned.duplicate(true)
	for record in next:
		if record.id==id:
			record.special.element=element
			record.special.unique=unique
			record.special.state="ready"
	var payload=save_payload().duplicate(true)
	payload.owned=next
	if not persist_payload(payload): notify("저장에 실패했습니다. 선택을 다시 확인하세요."); return false
	owned=next
	show_loot_details(id,-1,false,true)
	return true

func commit_evolution(main_id,support_id,expected):
	if mode!="camp" or save_blocked: return false
	var plan=Evolution.preview(owned,squad,main_id,support_id)
	if not plan.error.is_empty() or not Special.equivalent(plan.materials,expected):
		notify("동료 정보가 바뀌었습니다. 재료와 보호 상태를 다시 확인하세요.")
		return false
	var next=[]
	for d in owned:
		if d.id==main_id: next.append(plan.result.duplicate(true))
		elif d.id!=support_id: next.append(d.duplicate(true))
	var payload=save_payload().duplicate(true)
	payload.owned=next
	if not persist_payload(payload):
		notify("저장에 실패해 진화를 취소했습니다. 동료는 소모되지 않았습니다.")
		return false
	owned=next
	units.clear()
	if int(plan.result.star)==6: show_loot_details(main_id,-1,false,true)
	else: show_special_choice(main_id)
	return true

func commit_evolution_choice(id,ability,expected):
	if mode!="camp" or save_blocked: return false
	var d=find_owned(id)
	if Loot.star(d)!=5 or owned.filter(func(record): return record.get("id")==id).size()!=1 or not Special.evolution_pending(d) or not Special.ready(d) or not Special.equivalent(d,expected) or not Special.evolution_choices(d.kind).has(ability): return false
	var next=owned.duplicate(true)
	for record in next:
		if record.id==id: record.special.evolution={"version":1,"state":"ready","ability":ability}
	var payload=save_payload().duplicate(true)
	payload.owned=next
	if not persist_payload(payload): notify("저장에 실패했습니다. 선택을 다시 확인하세요."); return false
	owned=next
	show_loot_details(id,-1,false,true)
	return true
