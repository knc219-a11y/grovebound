extends RefCounted
# Presentation only: domain commands and atomic persistence belong to main.gd.
const UI=preload("res://ui/grove_ui.gd")
const Loot=preload("res://companion_loot.gd")
const Management=preload("res://companion_management.gd")
const Roles=preload("res://companion_roles.gd")

static func show(g):
	var camp=g.mode=="camp"
	g.modal("동료 관리", "한 번: 동료 선택 · 왼쪽 같은 동료 두 번: 동행/보관 · 오른쪽 같은 동료 두 번: 해제" if camp else "왼쪽에서 선택 후 오른쪽 칸으로 교체 · 탐험 중 동행 해제 불가", "companions",g.open_game_menu)
	var source=[]
	for d in g.owned:
		if camp or g.squad.has(d.id): source.append(d.duplicate(true))
	var roster=Management.filtered(source,g.squad,g.roster_kind_filter,"",g.roster_favorites_only,g.roster_sort)
	if not g.roster_grade_filter.is_empty():
		roster=roster.filter(func(d): return str(Loot.star(d))==g.roster_grade_filter or Loot.grade(d)==g.roster_grade_filter)
	filters(g,source.size(),roster.size())
	var scroll=ScrollContainer.new()
	scroll.name="CompanionScroll"
	scroll.position=Vector2(215,305)
	scroll.size=Vector2(658,318)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	g.overlay.add_child(scroll)
	var grid=GridContainer.new()
	grid.name="CompanionGrid"
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for d in roster: add_card(g,grid,d)
	if roster.is_empty():
		var empty=g.label(scroll,"조건에 맞는 동료가 없습니다.\n필터를 초기화해 보세요." if not source.is_empty() else "아직 동료가 없습니다.\n첫 인연을 만나보세요.",Vector2(16,24),20)
		empty.name="EmptyRoster"
	scroll.set_deferred("scroll_vertical",g.roster_scroll)
	lineup(g)
	selection(g,camp)
	g.label(g.overlay,"성장 재료 %d · 육성 3개 → 경험치 +40" % g.materials,Vector2(215,638),16)
	if camp:
		g.button(g.overlay,"일괄 작별",Rect2(215,665,145,44),func(): g.show_bulk_release(true))
		g.button(g.overlay,"특수개체 합성",Rect2(370,665,198,44),func(): g.show_synthesis())
	formation(g)
	var done=g.button(g.overlay,"완료",Rect2(1067,665,158,44),func(): g.show_camp() if camp else g.clear_overlay())
	done.name="RosterDone"

static func formation(g):
	var title=small_label(g.overlay,"집결 진형 · 주인공 이동 방향 기준",Rect2(585,635,460,25),16,UI.MUTED)
	title.name="FormationHint"
	var keys=["front","rear","surround"]
	var names=["앞","뒤","둘러싸기"]
	for i in keys.size():
		var key=keys[i]
		var selected=g.party_formation==key
		var b=g.button(g.overlay,("✓ " if selected else "")+names[i],Rect2(585+i*154,665,146,44),func(): g.set_party_formation(key))
		b.name="Formation_"+key
		b.tooltip_text="교전 전 집결 위치를 정합니다. 교전하면 동료가 사거리와 역할에 따라 움직입니다."
		if selected: b.add_theme_stylebox_override("normal",UI.frame(Color("344633"),Color("9ed5a2"),2))

static func filters(g,total,shown):
	g.label(g.overlay,"보유 동료",Vector2(215,207),21)
	var count=g.label(g.overlay,"표시 %d / %d마리" % [shown,total],Vector2(671,212),16)
	count.name="RosterCount"
	var species=OptionButton.new()
	species.name="SpeciesFilter"
	species.position=Vector2(215,246)
	species.size=Vector2(153,44)
	species.add_item("모든 종")
	var kinds=g.STATS.keys()
	for i in kinds.size():
		species.add_item(g.NAMES[kinds[i]])
		if g.roster_kind_filter==kinds[i]: species.select(i+1)
	species.item_selected.connect(func(index): g.roster_kind_filter="" if index==0 else kinds[index-1]; g.roster_scroll=0; g.roster_click.clear(); g.open_roster())
	g.overlay.add_child(species)
	var rarity=OptionButton.new()
	rarity.name="GradeFilter"
	rarity.position=Vector2(376,246)
	rarity.size=Vector2(129,44)
	rarity.add_item("모든 성급")
	for star in range(1,7):
		rarity.add_item(str(star)+"성")
		if g.roster_grade_filter==str(star) or (star<=3 and g.roster_grade_filter==Loot.GRADES[star-1]): rarity.select(star)
	rarity.item_selected.connect(func(index): g.roster_grade_filter="" if index==0 else str(index); g.roster_scroll=0; g.roster_click.clear(); g.open_roster())
	g.overlay.add_child(rarity)
	var sorting=OptionButton.new()
	sorting.name="RosterSort"
	sorting.position=Vector2(513,246)
	sorting.size=Vector2(168,44)
	for caption in ["동행 순서","최근 인연순","높은 성급순","높은 레벨순"]: sorting.add_item(caption)
	sorting.select(g.roster_sort)
	sorting.item_selected.connect(func(index): g.roster_sort=index; g.roster_scroll=0; g.roster_click.clear(); g.open_roster())
	g.overlay.add_child(sorting)
	var favorite=g.button(g.overlay,"잠금만 ✓" if g.roster_favorites_only else "잠금만",Rect2(689,246,92,44),func(): g.roster_favorites_only=not g.roster_favorites_only; g.roster_scroll=0; g.roster_click.clear(); g.open_roster())
	favorite.name="FavoritesFilter"
	g.button(g.overlay,"초기화",Rect2(789,246,84,44),g.reset_roster_filters)

static func add_card(g,parent,d):
	var selected=d.id==g.roster_selected_id
	var card=Button.new()
	card.name="Companion_"+str(d.id)
	card.custom_minimum_size=Vector2(208,100)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.clip_contents=true
	card.tooltip_text="#%d %s · %s\n%s\n%s\n한 번: 선택 · 같은 카드 두 번: 동행/보관 전환" % [d.id,g.NAMES[d.kind],Roles.LABELS[d.kind],d.trait,"\n".join(Loot.lines(d))]
	card.add_theme_stylebox_override("normal",UI.frame(Color("344633") if selected else Color("202b27"),Loot.color(d) if selected else Color("58604b"),2 if selected else 1))
	card.pressed.connect(g.roster_select.bind(d.id))
	parent.add_child(card)
	portrait(g,card,d,Rect2(7,24,58,52))
	var name_label=small_label(card,g.NAMES[d.kind]+(" ◆" if d.get("favorite",false) else ""),Rect2(70,9,132,24),17)
	name_label.name="CompanionName"
	var stars=small_label(card,"★".repeat(Loot.star(d)),Rect2(70,33,130,20),15,Loot.color(d))
	stars.name="Stars"
	small_label(card,"Lv.%d · %s" % [d.level,Roles.LABELS[d.kind]],Rect2(70,54,130,21),14)
	var idx=g.squad.find(d.id)
	var status=status_text(idx)
	if selected: status="✓ 선택 · "+status
	var state=small_label(card,status,Rect2(10,77,190,21),14,Color("9ed5a2") if idx>=0 and idx<4 else (Color("e0bd7b") if idx>=4 else UI.MUTED))
	state.name="Participation"

static func lineup(g):
	var root=Control.new()
	root.name="PartyLineup"
	root.position=Vector2(899,205)
	root.size=Vector2(326,276)
	g.overlay.add_child(root)
	var active=Control.new()
	active.name="ActiveGroup"
	active.size=Vector2(326,174)
	root.add_child(active)
	small_label(active,"전투 출전 · 4마리",Rect2(0,0,326,25),21,Color("9ed5a2")).name="GroupLabel"
	for i in 4:
		party_slot(g,active,i,Rect2((i%2)*166,35+(i/2)*69,160,63))
	var reserve=Control.new()
	reserve.name="ReserveGroup"
	reserve.position=Vector2(0,180)
	reserve.size=Vector2(326,96)
	root.add_child(reserve)
	small_label(reserve,"교체 대기 · 2마리",Rect2(0,0,326,25),18,Color("e0bd7b")).name="GroupLabel"
	for i in 2: party_slot(g,reserve,i+4,Rect2(i*166,32,160,63))

static func party_slot(g,parent,index,rect):
	var slot=Button.new()
	slot.name="PartySlot_"+str(index+1)
	slot.position=rect.position
	slot.size=rect.size
	slot.clip_contents=true
	var caption="출전 %d" % (index+1) if index<4 else "대기 %d" % (index-3)
	slot.text=caption
	slot.add_theme_color_override("font_color",Color.TRANSPARENT)
	slot.add_theme_color_override("font_hover_color",Color.TRANSPARENT)
	slot.add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
	var accent=Color("9ed5a2") if index<4 else Color("e0bd7b")
	slot.add_theme_stylebox_override("normal",UI.frame(Color("223229") if index<4 else Color("302e24"),accent))
	slot.pressed.connect(g.roster_assign.bind(index))
	parent.add_child(slot)
	var d=g.find_owned(g.squad[index]) if index<g.squad.size() else {}
	if d.is_empty():
		small_label(slot,caption+" · 빈자리",Rect2(8,8,146,21),16,accent)
		small_label(slot,"+ 선택한 동료 배치",Rect2(8,33,146,21),14,UI.MUTED)
	else:
		portrait(g,slot,d,Rect2(6,19,42,36))
		small_label(slot,caption+" · "+g.NAMES[d.kind],Rect2(49,6,106,22),15,accent)
		small_label(slot,"★%d · Lv.%d" % [Loot.star(d),d.level],Rect2(49,31,106,22),13,Loot.color(d))
	if d.is_empty(): slot.tooltip_text="왼쪽 동료를 선택한 뒤 이 칸을 누르면 배치합니다.\n앞쪽 빈 출전 칸부터 편성하며 출전 4마리 다음에 대기 칸을 채웁니다."
	else: slot.tooltip_text="#%d %s\n한 번: 선택/배치 · 같은 칸 두 번: 동행 해제(캠프)" % [d.id,g.NAMES[d.kind]]

static func selection(g,camp):
	var box=Control.new()
	box.name="SelectionDetails"
	box.position=Vector2(899,496)
	box.size=Vector2(326,162)
	g.overlay.add_child(box)
	var d=g.find_owned(g.roster_selected_id)
	if d.is_empty():
		small_label(box,"왼쪽에서 동료를 선택하세요.",Rect2(0,0,326,29),18)
		small_label(box,"선택 후 위 칸을 누르면 편성합니다.",Rect2(0,34,326,24),16,UI.MUTED)
		return
	small_label(box,"선택 · %s #%d" % [g.NAMES[d.kind],d.id],Rect2(0,0,326,25),18,Loot.color(d))
	small_label(box,"Lv.%d · %s · %s" % [d.level,d.trait,status_text(g.squad.find(d.id))],Rect2(0,26,326,22),14,UI.MUTED)
	var detail=g.button(box,"상세·비교",Rect2(0,54,102,44),func(): g.show_loot_details(d.id,-1,false,true))
	detail.name="RosterDetail"
	var favorite=g.button(box,"잠금 해제" if d.get("favorite",false) else "즐겨찾기",Rect2(110,54,102,44),func(): g.toggle_favorite(d.id))
	favorite.name="RosterFavorite"
	if camp:
		var grow=g.button(box,"능력 선택" if g.Special.pending(d) else "육성",Rect2(220,54,106,44),func(): g.show_training(d.id))
		grow.name="RosterTraining"
		var remove=g.button(box,"동행 해제",Rect2(0,102,156,44),g.roster_remove.bind(d.id))
		remove.name="RosterRemove"
		remove.disabled=not g.squad.has(d.id)
		var release=g.button(box,"자연으로 보내기",Rect2(164,102,162,44),func(): g.confirm_release(d.id))
		release.name="RosterRelease"
		release.disabled=not Management.can_release(d,g.squad)

static func status_text(index):
	return "출전 %d" % (index+1) if index>=0 and index<4 else ("대기 %d" % (index-3) if index>=4 else "보관")

static func portrait(g,parent,d,rect):
	var image=TextureRect.new()
	image.name="Portrait"
	image.position=rect.position
	image.size=rect.size
	image.texture=g.textures.get(d.kind)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

static func small_label(parent,caption,rect,font_size,color=UI.PAPER):
	var text=Label.new()
	text.text=caption
	text.position=rect.position
	text.size=rect.size
	text.add_theme_font_size_override("font_size",font_size)
	text.add_theme_color_override("font_color",color)
	text.clip_text=true
	text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(text)
	return text
