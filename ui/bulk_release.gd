extends RefCounted
static func reward(g,ids):
	var total=0
	for id in ids: total+=g.Management.farewell_reward(g.find_owned(id))
	return total
static func visible_roster(g):
	return g.Management.filtered(g.owned,g.squad,g.roster_kind_filter,g.roster_grade_filter,g.roster_favorites_only,g.roster_sort)
static func show_page(g):
	g.bulk_selection=g.bulk_selection.filter(func(id): return g.Management.can_release(g.find_owned(id),g.squad))
	g.modal("동료와 일괄 작별","현재 동료 관리 필터를 사용합니다. 동행·즐겨찾기 동료는 선택할 수 없습니다.","bulk_release",g.open_roster)
	var visible=visible_roster(g)
	g.button(g.overlay,"현재 필터에서 선택",Rect2(230,215,250,48),func():
		for d in visible:
			if g.Management.can_release(d,g.squad) and not g.bulk_selection.has(d.id): g.bulk_selection.append(d.id)
		g.show_bulk_release())
	g.button(g.overlay,"선택 해제",Rect2(500,215,170,48),func(): g.bulk_selection.clear(); g.show_bulk_release())
	g.label(g.overlay,"선택 %d마리 · 성장 재료 %d개" % [g.bulk_selection.size(),reward(g,g.bulk_selection)],Vector2(710,230),20)
	var scroll=ScrollContainer.new()
	scroll.name="BulkReleaseScroll"
	scroll.position=Vector2(230,280)
	scroll.size=Vector2(980,300)
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for d in visible:
		var row=HBoxContainer.new()
		row.custom_minimum_size=Vector2(940,72)
		rows.add_child(row)
		var pick=CheckBox.new()
		pick.name="Select_"+str(d.id)
		pick.custom_minimum_size=Vector2(80,68)
		pick.button_pressed=g.bulk_selection.has(d.id)
		pick.disabled=not g.Management.can_release(d,g.squad)
		pick.toggled.connect(func(checked): g.toggle_bulk_release(d.id,checked))
		row.add_child(pick)
		var description=Label.new()
		description.text="[%s] %s Lv.%d · %s · %s" % [g.Loot.title(d),g.NAMES[d.kind],d.level,g.Roles.LABELS[d.kind],d.trait]
		description.custom_minimum_size=Vector2(620,60)
		description.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		description.add_theme_color_override("font_color",g.Loot.color(d))
		row.add_child(description)
		var protected=Label.new()
		protected.text="동행 중" if g.squad.has(d.id) else "즐겨찾기 보호" if d.get("favorite",false) else "재료 %d개" % g.Management.farewell_reward(d)
		protected.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		row.add_child(protected)
	if visible.is_empty(): g.label(g.overlay,"현재 필터에 맞는 동료가 없습니다.",Vector2(250,320),20)
	scroll.set_deferred("scroll_vertical",g.bulk_scroll)
	g.label(g.overlay,"Lv.1 기준 일반 2 · 희귀 5 · 영웅 10개 / 레벨마다 +1개",Vector2(235,600),17)
	g.button(g.overlay,"동료 관리로",Rect2(230,640,240,55),g.open_roster)
	var confirm=g.button(g.overlay,"선택한 동료와 작별",Rect2(900,640,310,55),g.confirm_bulk_release)
	confirm.disabled=g.bulk_selection.is_empty()
static func show_confirmation(g,ids):
	for id in ids:
		if not g.Management.can_release(g.find_owned(id),g.squad):
			g.notify("동행·즐겨찾기 상태를 다시 확인하세요.")
			g.show_bulk_release()
			return
	g.modal("선택한 동료를 자연으로 보낼까요?","%d마리와 작별 · 성장 재료 %d개가 남습니다. 아래 명단을 확인하세요." % [ids.size(),reward(g,ids)],"bulk_confirmation",g.show_bulk_release)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(240,230)
	scroll.size=Vector2(960,300)
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	scroll.add_child(rows)
	for id in ids:
		var d=g.find_owned(id)
		var line=Label.new()
		line.text="[%s] %s Lv.%d · %s" % [g.Loot.title(d),g.NAMES[d.kind],d.level,d.trait]
		line.custom_minimum_size=Vector2(900,40)
		rows.add_child(line)
	g.label(g.overlay,"작별한 동료는 되돌릴 수 없습니다. 도감의 인연 기록은 유지됩니다.",Vector2(240,560),18)
	g.button(g.overlay,"취소 · 선택으로",Rect2(240,630,300,60),g.show_bulk_release)
	var b=g.button(g.overlay,"%d마리와 최종 작별" % ids.size(),Rect2(850,630,350,60),func(): g.commit_bulk_release(ids))
	g.GroveUI.emphasize(b,"danger")
