extends Node2D
# A self-contained, data-driven playable slice. All gameplay positions are world coordinates.
const WORLD_SIZE=Vector2(2900,1650)
const VIEW_SIZE=Vector2(1440,810)
const SAVE_PATH = "user://grovebound_v1.json"
const SaveData = preload("res://save_data.gd")
var save_path = SAVE_PATH
var save_notice = ""
var save_blocked = false
var save_backup_path = ""
const NAMES = {"boar":"멧돼지", "marten":"담비", "fox":"여우", "turtle":"거북", "deer":"사슴", "wolf":"늑대", "druid":"드루이드"}
const ROLES = {"boar":"근접", "marten":"근접", "fox":"원거리", "turtle":"탱커", "deer":"힐러", "wolf":"근접"}
const STATS = {"boar":[130,14,60,110],"marten":[85,21,62,150],"fox":[80,14,235,125],"turtle":[200,8,65,90],"deer":[95,8,240,120],"wolf":[95,12,60,130]}
const TRAITS = ["강인함", "용맹함", "단단함", "민첩함"]
const BoarRig = preload("res://animation/boar_pixel.gd")
var boar_rig
const PixelActor = preload("res://animation/pixel_actor.gd")
var druid_rig
var animal_rigs={}
const ActionPlayer=preload("res://animation/action_player.gd")
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
var team_button: Button
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 10417
	font=load("res://assets/fonts/Galmuri11.res")
	heading_font=load("res://assets/fonts/Galmuri11-Bold.res")
	font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	heading_font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	textures["valley"]=load("res://assets/maps/greenwater-beginner-v3.webp")
	for key in ["druid","boar","marten","fox","turtle","deer","wolf","tree"]:
		textures[key] = load("res://assets/party-pixel/"+key+".png" if key in PIXEL_KINDS else "res://assets/"+key+".png")
	boar_rig=BoarRig.new()
	druid_rig=PixelActor.new("res://animation/druid_walk_frames.json","res://animation/druid_run_frames.json")
	motion_actions=ActionPlayer.new()
	for species in ["wolf","fox","marten","deer","turtle"]:
		animal_rigs[species]=PixelActor.new("res://animation/"+species+"_walk_frames.json","res://animation/"+species+"_trot_frames.json")
	textures["boar"]=boar_rig.portrait()
	build_terrain()
	build_ui()
	is_test = "--self-test" in OS.get_cmdline_user_args()
	screenshot_mode = "--screenshot" in OS.get_cmdline_user_args()
	if is_test:
		run_tests()
		return
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
	var theme=GroveUI.theme(font)
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
	team_button=button(hud,"편성 [Tab]",Rect2(1142,18,132,62),open_roster)
	button(hud,"귀환",Rect2(1288,18,132,62),func(): confirm_return())
	label(hud,"동료 스킬",Vector2(365,650),14)
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

func panel(parent, rect, color):
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s=GroveUI.frame(color)
	if rect.size==Vector2(1440,810): s.set_border_width_all(0)
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
	for c in overlay.get_children():
		overlay.remove_child(c)
		c.queue_free()
	overlay.hide()
	overlay.size = Vector2.ZERO

func modal(title, subtitle):
	clear_overlay()
	overlay.show()
	overlay.size = Vector2(1440,810)
	panel(overlay,Rect2(0,0,1440,810),Color(0.03,0.08,0.06,0.85))
	panel(overlay,Rect2(170,90,1100,630),Color("252a2c"))
	label(overlay,title,Vector2(215,119),31)
	label(overlay,subtitle,Vector2(215,169),17)
	stick = Vector2.ZERO
	mouse_stick = false
	stick_id = -1
	revive_touch_id = -1
	holding_revive = false

func show_camp():
	mode="camp"
	save_game()
	modal("GROVEBOUND  ·  야수의 계곡","야영지  /  동료와 함께 다음 탐험을 준비하세요")
	panel(overlay,Rect2(215,215,610,330),Color("202823"))
	panel(overlay,Rect2(865,215,360,330),Color("202823"))
	label(overlay,"함께할 동료",Vector2(240,240),16)
	label(overlay,"성장 재료",Vector2(435,240),16)
	label(overlay,"탐험 기록",Vector2(630,240),16)
	label(overlay,str(owned.size())+"마리",Vector2(240,275),30)
	label(overlay,str(materials),Vector2(435,275),30)
	label(overlay,"계곡 정복" if unlocked else "첫 탐험" if not tutorial_done else "탐험 중",Vector2(630,281),23)
	label(overlay,"포획한 야수와 네 마리의 편성을 꾸리세요.\n회복·강화·소생으로 동료를 지켜주세요.",Vector2(240,345),20)
	label(overlay,"WASD 이동   ·   Q 회복   ·   E 야성   ·   1~4 동료 스킬\nF 포획 / 길게 소생   ·   Tab 편성   ·   Esc 일시정지\n터치: 왼쪽 이동 스틱과 화면 버튼",Vector2(240,435),16)
	label(overlay,"계곡의 길잡이",Vector2(975,239),20)
	label(overlay,"DRUID",Vector2(1010,511),16)
	if not save_notice.is_empty(): label(overlay,save_notice,Vector2(230,552),15)
	var depart=button(overlay,"첫 동료 만나기" if not tutorial_done else "계곡으로 출발",Rect2(215,590,340,72),show_starters if not tutorial_done else func(): start_stage(false))
	GroveUI.emphasize(depart)
	button(overlay,"동료 · 편성 · 성장",Rect2(575,590,340,72),open_roster)
	var reset=button(overlay,"새 여정",Rect2(1095,590,130,72),confirm_reset)
	GroveUI.emphasize(reset,"danger")
	var preview=TextureRect.new()
	preview.texture=textures["druid"]
	preview.position=Vector2(973,282)
	preview.size=Vector2(144,216)
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	overlay.add_child(preview)

func show_starters():
	modal("첫 인연을 선택하세요", "선택한 야수를 직접 쓰러뜨리면 첫 포획 기회는 확정입니다. 다른 종도 나중에 만날 수 있습니다.")
	var kinds = ["boar","marten","fox"]
	var desc = ["든든한 근접형\n돌진 · 잠깐 기절", "빠른 근접형\n한 적에게 연속 공격", "원거리형\n범위 기운탄"]
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

func make_owned(kind, level):
	var pool = TRAITS.duplicate()
	if kind == "deer": pool.append("다정함")
	var d = {"id":next_id,"kind":kind,"level":level,"xp":0,"trait":pool[rng.randi_range(0,pool.size()-1)]}
	next_id += 1
	owned.append(d)
	return d

func max_hp(d):
	return STATS[d.kind][0] * (1.0 + (d.level-1)*0.12) * (1.2 if d.trait=="강인함" else 1.0)

func attack(d):
	return STATS[d.kind][1] * (1.0 + (d.level-1)*0.1) * (1.18 if d.trait=="용맹함" else 1.0)

func find_owned(id):
	for d in owned:
		if d.id == id: return d
	return {}

func make_unit(d, p):
	if not d is Dictionary or not STATS.has(d.get("kind","")): return {}
	return {"data":d,"pos":p,"hp":max_hp(d),"maxhp":max_hp(d),"cd":0.0,"skill":0.0,"buff":0.0,"shield":0.0,"face":1.0,"walk":false}

func start_stage(tutorial):
	repair_party()
	clear_overlay()
	mode = "tutorial" if tutorial else "stage"
	player.pos = Vector2(340,800)
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
		notify("선택한 야수에게 다가가세요. 사거리 안에서 자동 공격합니다.")
	else:
		var packs = [Vector2(650,790),Vector2(1030,640),Vector2(1340,970),Vector2(1660,650),Vector2(1990,960),Vector2(2260,680)]
		var kinds = ["boar","turtle","deer","fox","marten","wolf"]
		for i in range(packs.size()):
			spawn_enemy(kinds[i],packs[i],1+i/2,false,i<3)
			if i>0: spawn_enemy("wolf",packs[i]+Vector2(85,90),1+i/2)
		spawn_enemy("boar",Vector2(2590,850),4,true,false)
		notify("동료를 모으며 동쪽으로 탐험하세요. 마지막 공터에 우두머리가 있습니다.")
	update_hud()

func spawn_enemy(kind, p, level=1, boss=false, guaranteed=false):
	var h = 24.0 if mode=="tutorial" else (STATS[kind][0]*0.72+level*10)
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

func nearest_enemy(p, radius=500.0):
	var result = {}
	var best = radius
	for e in enemies:
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
	if is_test: return
	message_time = maxf(0,message_time-dt)
	if (mode=="stage" or mode=="tutorial") and not overlay.visible:
		if not screenshot_mode:
			update_game(minf(dt,0.05))
			druid_rig.advance(player,minf(dt,0.05))
			for actor in units+enemies:
				var species=actor.get("kind",actor.get("data",{}).get("kind",""))
				if species=="boar": boar_rig.advance(actor,minf(dt,0.05))
				elif animal_rigs.has(species): animal_rigs[species].advance(actor,minf(dt,0.05))
	cam = (player.pos-Vector2(720,400)).clamp(Vector2.ZERO,WORLD_SIZE-VIEW_SIZE)
	update_hud()
	queue_redraw()
	if "--screenshot" in OS.get_cmdline_user_args() and clock>2.0 and clock<2.2:
		take_screenshot()

func update_game(dt):
	stage_time += dt
	combat_feedback.advance(dt)
	for a in [player]+units+enemies:
		if not a.get("walk",false): a.move_speed=0.0
		motion_actions.advance(a,dt)
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
		if not target.is_empty() and player.cd<=0:
			hit_enemy(target,6.0,player.pos,player)
			player.cd=0.85
	for i in range(units.size()):
		var u=units[i]
		u.skill=maxf(0,u.skill-dt)
		u.buff=maxf(0,u.buff-dt)
		u.shield=maxf(0,u.shield-dt)
		u.walk=false
		if i>=4 or u.hp<=0: continue
		u.cd-=dt
		var kind=u.data.kind
		var speed=STATS[kind][3]*(1.2 if u.data.trait=="민첩함" else 1.0)
		var target=nearest_enemy(u.pos,410)
		if u.pos.distance_to(player.pos)>430 or (not target.is_empty() and target.pos.distance_to(player.pos)>550):
			move_entity(u,player.pos,speed*1.7,dt,75)
			continue
		if target.is_empty():
			var offset=Vector2(-75+(i%2)*110,55+(i/2)*60)
			move_entity(u,player.pos+offset,speed*1.3,dt,15)
		elif kind=="deer":
			if u.pos.distance_to(target.pos)<155: move_entity(u,u.pos+(u.pos-target.pos).normalized()*70,speed,dt)
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
				hit_enemy(target,attack(u.data)*(1.6 if u.buff>0 else 1.0),u.pos,u)
				u.cd=0.85 if kind=="marten" else 1.2
	for a in active_units():
		if a.hp<=0: continue
		for b in active_units():
			if a==b or b.hp<=0: continue
			var gap=a.pos-b.pos
			if gap.length()<35 and gap.length()>0.01:
				a.pos+=gap.normalized()*24*dt
	for e in enemies:
		if e.hp<=0: continue
		e.stun=maxf(0,e.stun-dt)
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
		if not e.active: continue
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
		elif e.pos.distance_to(target.pos)>49:
			move_entity(e,target.pos,80 if e.boss else 95,dt,44)
		elif e.cd<=0:
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
	if mode=="stage":
		var boss_alive=false
		for e in enemies:
			if e.boss and e.hp>0: boss_alive=true
		if not boss_alive:
			finish(true)

func begin_boss_attack(e, target):
	e.attack_kind="stomp" if e.pattern%2==0 else "charge"
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
	e["swing"]=0.22
	motion_actions.start(e,e.kind,"cast" if e.kind=="fox" else "attack")
	if e.attack_kind=="charge":
		e.dash=0.48
		e.dash_hits=[]
		return
	var radius=130.0 if e.attack_kind=="stomp" else 56.0
	for a in alive_allies():
		if a.pos.distance_to(e.aim)<radius:
			damage_ally(a,28.0 if e.boss else (2.0 if mode=="tutorial" else 10.0+e.level*2),e.pos)
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
			damage_ally(a,35.0,e.pos)
			e.dash_hits.append(id)
	if e.pos.distance_to(e.aim)<2 or e.dash<=0:
		e.dash=0.0
		e.cd=2.8

func damage_ally(a, damage, source):
	if a.hp<=0: return
	if a.has("data"):
		if a.data.trait=="단단함": damage*=0.85
		if a.shield>0: damage*=0.4
	var taken=minf(a.hp,damage)
	a.hp=maxf(0,a.hp-damage)
	a["hit"]=0.18
	a["recoil"]=(a.pos-source).normalized()*6
	combat_feedback.emit("block" if a.get("shield",0.0)>0 else "hurt",source,a.pos,taken,{"target_id":a.data.id if a.has("data") else -1,"height":sprite_height(a.data.kind) if a.has("data") else sprite_height("druid")})

func animate_attack(source,attacker={}):
	for a in ([attacker] if not attacker.is_empty() else [player]+active_units()):
		if a.pos.distance_to(source)<2:
			a["swing"]=0.22
			var species="druid" if a==player else a.data.kind
			motion_actions.start(a,species,"support" if species=="druid" else ("cast" if species=="fox" else "attack"))
			return

func hit_enemy(e, damage, source,attacker={}):
	if e.hp<=0: return
	var dealt=minf(e.hp,damage)
	e.hp=maxf(0,e.hp-damage)
	e.active=true
	e["hit"]=0.16
	e["recoil"]=(e.pos-source).normalized()*7
	animate_attack(source,attacker)
	var visual="melee"
	if not attacker.is_empty():
		visual="support" if attacker==player else ("fox" if attacker.data.kind=="fox" else "melee")
	combat_feedback.emit(visual,source,e.pos,dealt,{"target_id":e.get("feedback_id",str(e.pos.round())),"height":sprite_height(e.kind,e.get("boss",false))})
	if e.hp<=0:
		e["death"]=0.32
		kills+=1
		materials+=1 if not e.boss else 5
		for u in units: gain_xp(u.data,12+int(e.level)*4)
		if not e.boss and (e.guaranteed or rng.randf()<0.45):
			captures.append({"kind":e.kind,"pos":e.pos,"level":e.level})
		save_game()

func gain_xp(d, amount):
	d.xp+=amount
	while d.xp>=d.level*35:
		d.xp-=d.level*35
		d.level+=1
		for u in units:
			if u.data.id==d.id: u.maxhp=max_hp(d)

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
	var restored=minf(amount,a.maxhp-a.hp)
	a.hp=minf(a.maxhp,a.hp+amount)
	if restored>0: combat_feedback.emit("heal",source,a.pos,restored,{"target_id":a.data.id if a.has("data") else -1,"height":sprite_height(a.data.kind) if a.has("data") else sprite_height("druid")})

func cast_heal():
	if not can_act() or heal_cd>0: return
	var a=lowest_ally(player.pos,430)
	if not a.is_empty() and a.hp<a.maxhp:
		heal(a,55,player.pos,player)
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
		fx(player.pos,best.pos,Color("ffce6a"),"야성 +60%",0.9)

func can_act():
	return (mode=="stage" or mode=="tutorial") and not overlay.visible and revive_target<0

func use_companion_skill(i):
	if not can_act() or i>=active_units().size(): return
	var u=units[i]
	if u.hp<=0 or u.skill>0: return
	var target=nearest_enemy(u.pos,430)
	match u.data.kind:
		"deer":
			for a in alive_allies():
				if a.pos.distance_to(u.pos)<350: heal(a,35*(1.25 if u.data.trait=="다정함" else 1),u.pos,u)
		"turtle":
			motion_actions.start(u,"turtle","guard")
			u.shield=5.0
			for e in enemies:
				if e.hp>0 and e.pos.distance_to(u.pos)<270:
					e.active=true
					e["taunt"]=u
					e["taunt_time"]=5.0
					e.aim=u.pos
					e.pos=e.pos.move_toward(u.pos,35)
			combat_feedback.emit("guard",u.pos,u.pos)
			fx(u.pos,u.pos,Color("a7d9e8"),"도발 · 방어",1)
		_:
			if target.is_empty(): return
			if u.data.kind=="fox":
				for e in enemies:
					if e.hp>0 and e.pos.distance_to(target.pos)<125: hit_enemy(e,attack(u.data)*2.5*(1.6 if u.buff>0 else 1.0),u.pos,u)
			else:
				if u.data.kind=="boar":
					u.pos=target.pos+Vector2(-48,0)
					target.stun=1.5
				hit_enemy(target,attack(u.data)*3.5*(1.6 if u.buff>0 else 1.0),u.pos,u)
	u.skill=10.0

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
	if not can_act() or closest_down()>=0: return
	var i=closest_capture()
	if i<0: return
	var c=captures[i]
	var d=make_owned(c.kind,int(c.level))
	captures.remove_at(i)
	if squad.size()<6:
		squad.append(d.id)
		units.append(make_unit(d,c.pos))
	notify("%s Lv.%d · %s 획득! %s" % [NAMES[d.kind],d.level,d.trait,"동행 합류" if squad.has(d.id) else "보관함으로 이동"])
	save_game()
	if mode=="tutorial":
		tutorial_done=true
		mode="tutorial_practice"
		modal("첫 동료를 얻었습니다!",NAMES[d.kind]+" · "+d.trait+" / 이제 함께 싸워보세요.")
		label(overlay,"동료는 자동으로 싸우고, 초상화를 누르면 고유 스킬을 사용합니다.\nQ 회복과 E 야성 강화로 동료를 지원하세요.\n\n다음 전투를 마치면 캠프로 돌아갑니다.",Vector2(230,280),23)
		button(overlay,"협동 전투 시작",Rect2(500,570,420,65),start_practice)

func start_practice():
	clear_overlay()
	mode="tutorial"
	spawn_enemy("wolf",player.pos+Vector2(240,0),1,false,false)
	enemies[-1].maxhp=70.0
	enemies[-1].hp=70.0
	enemies[-1].guaranteed=false
	tutorial_species="practice"

func finish(success):
	mode="result"
	if success:
		materials+=10
		unlocked=true
	save_game()
	modal("계곡 탐험 완료" if success else "드루이드가 쓰러졌습니다", "포획한 동료 · 전투 경험치 · 획득 재료는 모두 유지됩니다.")
	label(overlay,"처치 %d마리  ·  보유 동료 %d마리\n성장 재료 %d\n\n%s" % [kills,owned.size(),materials,"클리어 보너스 +10 · 다음 지역 개방 기록 완료\n다음 지역 콘텐츠는 후속 버전에서 추가됩니다." if success else "클리어 보상은 받지 못했습니다.\n동료 구성과 지원 타이밍을 바꿔 다시 도전해보세요."],Vector2(230,280),23)
	button(overlay,"캠프로 돌아가기",Rect2(490,580,450,65),show_camp)

func notify(txt):
	message=txt
	message_time=5.0

func fx(a,b,col,txt,time):
	effects.append({"a":a,"b":b,"color":col,"text":txt,"time":time,"duration":time})

func open_roster():
	if in_combat and mode=="stage": notify("전투 중에는 편성을 바꿀 수 없습니다."); return
	if mode=="tutorial": notify("튜토리얼을 먼저 마쳐주세요."); return
	var camp=mode=="camp"
	modal("동료 관리  ·  출전 4 / 동행 6", "동행 순서의 1~4번이 출전합니다. 두 동료를 차례로 눌러 순서를 교체하세요. 대기 중 체력은 유지됩니다.")
	chosen_swap=-1
	var roster=owned if camp else []
	if not camp:
		for id in squad: roster.append(find_owned(id))
	if roster.is_empty(): label(overlay,"아직 동료가 없습니다. 첫 인연을 만나보세요.",Vector2(250,310),23)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(215,215)
	scroll.size=Vector2(1010,365)
	overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for d in roster:
		var row=HBoxContainer.new()
		row.custom_minimum_size=Vector2(970,72)
		rows.add_child(row)
		var idx=squad.find(d.id)
		var desc="%s  Lv.%d\n%s · %s" % [NAMES[d.kind],d.level,ROLES[d.kind],d.trait]
		if idx>=0: desc=("[출전 %d] " % (idx+1) if idx<4 else "[대기 %d] " % (idx-3))+desc
		else: desc="[보관] "+desc
		var b=Button.new()
		b.text=desc
		b.custom_minimum_size=Vector2(440,64)
		b.clip_text=true
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		var portrait=TextureRect.new()
		portrait.texture=textures[d.kind]
		portrait.custom_minimum_size=Vector2(56,64)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
		b.pressed.connect(func(): select_swap(d.id))
		row.add_child(b)
		if camp:
			var equip=Button.new()
			equip.text="동행 해제" if idx>=0 else "동행 추가"
			equip.custom_minimum_size=Vector2(116,64)
			equip.pressed.connect(func(): toggle_squad(d.id); open_roster())
			row.add_child(equip)
			var grow=Button.new()
			grow.text="육성 (재료 3)"
			grow.custom_minimum_size=Vector2(142,64)
			grow.disabled=materials<3
			grow.pressed.connect(func(): materials-=3; gain_xp(d,40); save_game(); open_roster())
			row.add_child(grow)
			var release=Button.new()
			release.text="방생"
			release.custom_minimum_size=Vector2(76,64)
			release.disabled=idx>=0
			release.pressed.connect(func(): confirm_release(d.id))
			row.add_child(release)
	label(overlay,"성장 재료 %d · 출전/대기 모두 같은 전투 경험치 획득" % materials,Vector2(230,600),18)
	button(overlay,"완료",Rect2(1000,620,210,55),func(): save_game(); show_camp() if camp else clear_overlay())

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

func confirm_release(id):
	var d=find_owned(id)
	modal("동료를 방생할까요?",NAMES[d.kind]+" Lv.%d · %s" % [d.level,d.trait])
	label(overlay,"이 동료는 보유 목록에서 사라지고 성장 재료 2개를 얻습니다.\n동행 중인 동료는 먼저 동행을 해제해야 합니다.",Vector2(230,300),22)
	button(overlay,"방생하고 재료 받기",Rect2(300,560,350,65),func(): owned.erase(d); materials+=2; save_game(); open_roster())
	button(overlay,"취소",Rect2(750,560,300,65),open_roster)

func confirm_return():
	if mode!="stage" and mode!="tutorial": return
	modal("탐험을 마치고 귀환할까요?", "이미 획득한 동료와 재료는 유지됩니다. 클리어 보상은 지급되지 않습니다.")
	button(overlay,"귀환",Rect2(300,500,350,65),show_camp)
	button(overlay,"계속 탐험",Rect2(750,500,350,65),clear_overlay)

func confirm_reset():
	modal("새 여정 시작", "이 기기의 프로토타입 저장 데이터를 초기화합니다.")
	button(overlay,"초기화",Rect2(300,500,350,65),func(): owned.clear(); squad.clear(); units.clear(); materials=0; tutorial_done=false; unlocked=false; next_id=1; show_camp())
	button(overlay,"취소",Rect2(750,500,350,65),show_camp)

func update_hud():
	hud.visible=mode!="camp" and mode!="result" and mode!="tutorial_practice"
	if not hud.visible: return
	status_label.text="드루이드  ·  %d / %d" % [player.hp,player.maxhp]
	player_hp_bar.max_value=player.maxhp
	player_hp_bar.value=player.hp
	quest_label.text="첫 인연 · 가까이 가서 포획 [F]" if mode=="tutorial" else "01  초록물 계곡   →   동쪽 우두머리\n동행 %d/6 · 처치 %d · %02d:%02d · %s" % [squad.size(),kills,int(stage_time)/60,int(stage_time)%60,"전투 중" if in_combat else "탐험 중"]
	toast_label.text=message if message_time>0 else ""
	boss_label.text=""
	for e in enemies:
		if e.boss and e.hp>0 and e.active:
			boss_label.text="계곡의 우두머리  ·  %d / %d" % [e.hp,e.maxhp]
			boss_hp_bar.max_value=e.maxhp
			boss_hp_bar.value=e.hp
			if e.wind>0: boss_label.text+="\n"+("발구르기! 원 밖으로 이동" if e.attack_kind=="stomp" else "돌진! 옆으로 피하세요")
			elif e.get("dash",0.0)>0: boss_label.text+="\n돌진 중!"
			else: boss_label.text+="\n공격 기회"
			break
	boss_panel.visible=not boss_label.text.is_empty()
	boss_hp_bar.visible=boss_panel.visible
	boss_label.visible=boss_panel.visible
	team_button.disabled=in_combat or mode=="tutorial"
	for i in range(4):
		var b=party_buttons[i]
		if i<units.size():
			var u=units[i]
			b.configure(textures[u.data.kind],NAMES[u.data.kind],ROLES[u.data.kind],u.hp,u.maxhp,u.skill)
			b.disabled=u.hp<=0 or u.skill>0 or revive_target>=0
		else:
			b.configure(null,"빈자리","포획으로 합류",0,1,0)
			b.disabled=true
	heal_button.refresh(heal_cd)
	buff_button.refresh(buff_cd)
	heal_button.disabled=heal_cd>0 or revive_target>=0
	buff_button.disabled=buff_cd>0 or revive_target>=0
	var down=closest_down()
	var cap=closest_capture()
	interact_button.visible=down>=0 or cap>=0
	interact_progress.visible=down>=0
	interact_progress.value=revive_progress
	if down>=0:
		interact_button.text="길게 눌러 소생 [F]\n%.1f / 3초" % revive_progress
	elif cap>=0: interact_button.text=NAMES[captures[cap].kind]+" 포획 [F]"
	if mode=="tutorial" and tutorial_species=="practice" and not overlay.visible:
		var alive=false
		for e in enemies:
			if e.hp>0: alive=true
		if not alive:
			tutorial_species=""
			show_camp()

func _input(event):
	if event is InputEventScreenTouch and not event.pressed:
		if event.index==stick_id:
			stick_id=-1
			stick=Vector2.ZERO
		if event.index==revive_touch_id:
			holding_revive=false
			revive_touch_id=-1
	if event is InputEventScreenTouch and event.pressed and not overlay.visible:
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
			KEY_ESCAPE:
				if mode=="stage" or mode=="tutorial":
					if overlay.visible: clear_overlay()
					else:
						modal("잠시 쉬어가기", "전투가 일시정지되었습니다.")
						button(overlay,"계속",Rect2(500,500,400,65),clear_overlay)
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
	var result = SaveData.normalize({"owned":owned,"squad":squad,"next_id":next_id},STATS.keys())
	if result.repaired:
		if backup_save(): save_notice = "편성의 잘못된 연결을 복구했습니다. 원본 저장은 백업했습니다."
	owned = result.owned
	squad = result.squad
	next_id = result.next_id

func save_game():
	if is_test or screenshot_mode or save_blocked: return
	var f=FileAccess.open(save_path,FileAccess.WRITE)
	if f: f.store_string(JSON.stringify({"version":1,"owned":owned,"squad":squad,"materials":materials,"tutorial_done":tutorial_done,"unlocked":unlocked,"next_id":next_id}))

func load_game():
	if not FileAccess.file_exists(save_path): return
	var d=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not d is Dictionary or d.get("version",0)!=1:
		save_blocked = true
		save_notice = "저장 데이터를 읽을 수 없어 원본을 유지하고 자동 저장을 중지했습니다."
		return
	var result = SaveData.normalize(d,STATS.keys())
	if result.repaired:
		if backup_save(): save_notice = "편성의 잘못된 연결을 복구했습니다. 원본 저장은 백업했습니다."
	owned=result.owned
	squad=result.squad
	materials=SaveData.integer(d.get("materials",0),0)
	tutorial_done=d.get("tutorial_done",false)
	unlocked=d.get("unlocked",false)
	next_id=result.next_id

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("282a2b"))
	draw_texture_rect(textures["valley"],Rect2(-cam.round(),WORLD_SIZE),false)
	for e in enemies: combat_feedback.draw_tell(self,e,cam)
	for c in captures:
		var p=c.pos-cam
		draw_arc(p,36+sin(clock*3)*3,0,TAU,30,Color("ffde85"),3,true)
		draw_sprite(c.kind,p,59,1,Color(1,1,1,0.8))
		text_at("포획 가능",p+Vector2(-30,-57),15,Color("fff1ab"))
	var actors=[]
	actors.append({"kind":"druid","pos":player.pos,"hp":player.hp,"maxhp":player.maxhp,"face":player.face,"size":sprite_height("druid"),"ally":true,"state":player})
	for u in active_units():
		actors.append({"kind":u.data.kind,"pos":u.pos,"hp":u.hp,"maxhp":u.maxhp,"face":u.face,"size":sprite_height(u.data.kind),"ally":true,"unit":u,"state":u})
	for e in enemies:
		if e.hp>0 or e.get("death",0.0)>0: actors.append({"kind":e.kind,"pos":e.pos,"hp":e.hp,"maxhp":e.maxhp,"face":e.face,"size":sprite_height(e.kind,e.boss),"ally":false,"state":e})
	actors.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	for a in actors:
		var p=a.pos-cam
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
		if motion_actions.draw(self,p+offset,a.size,a.face,col,a.kind,state):
			pass
		elif a.kind=="boar":
			# The rig owns breathing, gait and attack poses; never stack whole-image shaking.
			boar_rig.draw(self,p+offset,a.size,a.face,col,state)
		elif a.kind=="druid":
			druid_rig.draw(self,p+offset,a.size,a.face,col,state,textures["druid"])
		elif animal_rigs.has(a.kind):
			animal_rigs[a.kind].draw(self,p+offset,a.size,a.face,col,state,textures[a.kind])
		else:
			draw_sprite(a.kind,p+Vector2(0,bob)+offset,a.size,a.face,col,tilt,deformation)
		var bar=Rect2(p+Vector2(-27,-a.size-10),Vector2(54,6))
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

func draw_minimap():
	var box=Rect2(1190,104,225,135)
	draw_style_box(map_style(),box)
	text_at("계곡 지도",box.position+Vector2(12,22),15,Color("edf0d4"))
	var origin=box.position+Vector2(12,35)
	var scale_map=Vector2(201.0/2900.0,88.0/1650.0)
	draw_line(origin+Vector2(0,810)*scale_map,origin+Vector2(2900,810)*scale_map,Color("b2a879"),3,true)
	for e in enemies:
		if e.hp>0:
			draw_circle(origin+e.pos*scale_map,5 if e.boss else 3,Color("ffbc67") if e.boss else Color("e78a75"))
	for c in captures: draw_arc(origin+c.pos*scale_map,4,0,TAU,12,Color("ffec96"),1.5,true)
	for u in active_units():
		draw_circle(origin+u.pos*scale_map,2.5,Color("bce78b") if u.hp>0 else Color("777e71"))
	draw_circle(origin+player.pos*scale_map,4,Color("eaf7ea"))
	var visible_rect=Rect2(cam*scale_map,Vector2(1440,810)*scale_map)
	draw_rect(Rect2(origin+visible_rect.position,visible_rect.size),Color(0.8,0.9,0.8,0.35),false,1)

func map_style():
	return GroveUI.frame(Color("202823ef"))

func sprite_height(kind,boss=false):
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
	# Fast travel must not turn the small walk cycle into frame flicker.
	var fast_actor={"pos":Vector2.ZERO,"hp":100.0,"walk":true}
	boar_rig.advance(fast_actor,0.05)
	fast_actor.pos.x=10
	boar_rig.advance(fast_actor,0.05)
	if fast_actor.rig_phase>TAU*0.05/0.36+0.001: failures.append("pixel gait cadence cap")
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
