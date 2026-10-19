extends RefCounted
const UI=preload("res://ui/grove_ui.gd")
const Loot=preload("res://companion_loot.gd")
const Slot=preload("res://ui/inventory_slot.gd")
static func show_menu(g):
	g.modal("여정 메뉴","탐험을 준비하고, 동료와 가방을 확인하세요.","menu",g.resume_game)
	var locations=[Vector2(230,225),Vector2(565,225),Vector2(900,225)]
	var names=["가방 · 인벤토리","동료 · 편성","야수 도감"]
	var descriptions=["보유 동료 %d마리\n성장 재료 %d개" % [g.owned.size(),g.materials],"출전 %d/4 · 동행 %d/6\n동료 비교 · 즐겨찾기 · 육성" % [mini(4,g.squad.size()),g.squad.size()],"발견한 종 %d / %d\n기록은 자연으로 돌아간 뒤에도 남습니다." % [g.discovered.size(),g.STATS.size()]]
	var callbacks=[g.open_inventory,g.open_roster,g.open_collection]
	for i in 3:
		var p=locations[i]
		g.panel(g.overlay,Rect2(p,Vector2(310,210)),UI.INK)
		g.label(g.overlay,names[i],p+Vector2(20,22),24)
		g.label(g.overlay,descriptions[i],p+Vector2(20,72),18)
		var b=g.button(g.overlay,"열기",Rect2(p+Vector2(20,145),Vector2(270,46)),callbacks[i])
		if i==1: b.disabled=(g.in_combat and g.mode=="stage") or g.mode=="tutorial"
	g.label(g.overlay,"여정 기록",Vector2(235,464),20)
	g.label(g.overlay,"첫 인연  "+("완료" if g.tutorial_done else "캠프에서 첫 동료를 만나세요.")+"     /     초록물 계곡  "+("우두머리 제압 완료" if g.unlocked else "동료를 모아 우두머리에 도전하세요."),Vector2(235,505),18)
	g.label(g.overlay,"동료와 성장 재료는 자동 저장됩니다. 탐험을 다시 시작하면 입구에서 출발합니다.",Vector2(235,550),16)
	var resume=g.button(g.overlay,"캠프로" if g.mode=="camp" else "탐험 계속하기",Rect2(230,630,310,55),g.resume_game)
	UI.emphasize(resume)
	if g.mode in ["stage","tutorial"]: g.button(g.overlay,"캠프로 귀환",Rect2(565,630,310,55),g.confirm_return)
	if g.mode=="camp" and not g.expedition.report.is_empty(): g.button(g.overlay,"지난 탐험 기록",Rect2(565,630,310,55),g.show_run_report)
	g.button(g.overlay,"조작 안내",Rect2(900,630,310,55),g.open_controls)
static func show_inventory(g,selected_id=-1,reset_scroll=false):
	var old=g.overlay.get_node_or_null("InventoryScroll")
	if old!=null and not reset_scroll: g.inventory_scroll=old.scroll_vertical
	if selected_id>0: g.inventory_selected=selected_id
	if g.find_owned(g.inventory_selected).is_empty() and not g.owned.is_empty(): g.inventory_selected=g.owned[-1].id
	g.modal("가방  ·  인벤토리","보유 동료와 성장 재료를 확인합니다. 육성은 캠프에서, 편성은 비전투 중에 가능합니다.","inventory",g.open_game_menu)
	for i in 2:
		var b=g.button(g.overlay,"동료 %d" % g.owned.size() if i==0 else "재료 %d" % g.materials,Rect2(230+i*180,215,168,44),func(): g.inventory_category=i; g.inventory_scroll=0; g.open_inventory(-1,true))
		if g.inventory_category==i: UI.emphasize(b)
	g.label(g.overlay,"전체 보유",Vector2(625,228),16)
	var scroll=ScrollContainer.new()
	scroll.name="InventoryScroll"
	scroll.position=Vector2(230,275)
	scroll.size=Vector2(565,320)
	g.overlay.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	if g.inventory_category==0:
		for d in g.owned:
			var slot=Slot.new()
			slot.custom_minimum_size=Vector2(128,110)
			slot.record=d
			slot.caption=g.NAMES[d.kind]
			slot.portrait=g.textures[d.kind]
			slot.selected=d.id==g.inventory_selected
			slot.pressed.connect(func(): g.open_inventory(d.id))
			grid.add_child(slot)
		if g.owned.is_empty(): g.label(g.overlay,"아직 동료가 없습니다.\n첫 인연을 만나보세요.",Vector2(250,330),20)
	else:
		var slot=Slot.new()
		slot.custom_minimum_size=Vector2(128,110)
		slot.resource_count=g.materials
		slot.selected=true
		grid.add_child(slot)
		slot.pressed.connect(func(): g.open_inventory())
	scroll.set_deferred("scroll_vertical",g.inventory_scroll)
	g.panel(g.overlay,Rect2(825,215,385,380),UI.INK)
	if g.inventory_category==0:
		var d=g.find_owned(g.inventory_selected)
		if not d.is_empty():
			g.label(g.overlay,"[%s] %s Lv.%d" % [Loot.title(d),g.NAMES[d.kind],d.level],Vector2(845,238),24).add_theme_color_override("font_color",Loot.color(d))
			g.label(g.overlay,g.ROLES[d.kind]+" · "+d.trait,Vector2(845,284),19)
			g.label(g.overlay,"체력 %d   공격력 %.1f" % [g.max_hp(d),g.attack(d)],Vector2(845,321),19)
			var lines=Loot.lines(d)
			if lines.is_empty(): lines.append("기존 동료 · 옵션 없음")
			for i in lines.size(): g.label(g.overlay,lines[i],Vector2(845,368+i*32),16)
			g.label(g.overlay,"경험치 %d / %d" % [d.xp,g.Management.needed_xp(d)],Vector2(845,484),17)
			var detail=g.button(g.overlay,"상세 · 동행 동료와 비교",Rect2(845,530,345,46),func(): g.show_loot_details(d.id,-1,false))
			detail.disabled=(g.in_combat and g.mode=="stage") or g.mode=="tutorial"
		else: g.label(g.overlay,"선택한 동료 정보",Vector2(845,245),22)
	else:
		g.label(g.overlay,"성장 재료",Vector2(845,240),26)
		g.label(g.overlay,"보유 %d개" % g.materials,Vector2(845,292),23)
		g.label(g.overlay,"사냥과 탐험으로 얻은 육성 재료.\n\n캠프에서 3개를 사용하면\n선택한 동료가 경험치 40을 얻습니다.",Vector2(845,345),18)
		var use=g.button(g.overlay,"동료 육성으로" if g.mode=="camp" else "캠프에서 육성 가능",Rect2(845,530,345,46),g.open_roster)
		use.disabled=g.mode!="camp"
	g.button(g.overlay,"메뉴로",Rect2(230,630,240,55),g.open_game_menu)
	g.button(g.overlay,"캠프로" if g.mode=="camp" else "탐험 복귀",Rect2(925,630,285,55),g.resume_game)
static func show_collection(g):
	g.modal("야수 도감","한 번 얻은 종의 발견 기록은 동료를 자연으로 보내도 보존됩니다.","collection",g.open_game_menu)
	var kinds=g.STATS.keys()
	for i in kinds.size():
		var kind=kinds[i]
		var found=g.discovered.has(kind)
		var p=Vector2(230+(i%3)*330,220+(i/3)*178)
		g.panel(g.overlay,Rect2(p,Vector2(310,160)),UI.INK)
		g.label(g.overlay,g.NAMES[kind] if found else "미발견",p+Vector2(110,20),23)
		var picture=TextureRect.new()
		picture.texture=g.textures[kind]
		picture.position=p+Vector2(12,26)
		picture.size=Vector2(82,82)
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.modulate=Color.WHITE if found else Color(0.16,0.19,0.17,0.8)
		picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
		g.overlay.add_child(picture)
		var count=0
		for d in g.owned:
			if d.kind==kind: count+=1
		g.label(g.overlay,g.ROLES[kind]+" · 보유 %d마리" % count if found else "교감해 인연을 기록하세요.",p+Vector2(110,61),16)
		if found:
			g.button(g.overlay,"동료 찾아보기" if count>0 else "현재 보유 없음",Rect2(p+Vector2(110,100),Vector2(182,42)),func(): g.open_species_roster(kind)).disabled=count==0 or (g.in_combat and g.mode=="stage") or g.mode=="tutorial"
	g.label(g.overlay,"발견 %d / %d종" % [g.discovered.size(),kinds.size()],Vector2(235,632),19)
	g.button(g.overlay,"메뉴로",Rect2(925,630,285,55),g.open_game_menu)
