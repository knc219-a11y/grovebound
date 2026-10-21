extends RefCounted
# Selection and candidate previews are read-only; final confirmation calls the saved transaction.
static func show_page(g,ids,main_id,preserve):
	ids=ids.duplicate()
	g.modal("4성 특수개체 합성 · 재료 선택","3성 Lv.40 세 마리 · 성공 100% · 추가 비용 없음 · 보조 두 마리는 소모됩니다.","synthesis",g.open_roster)
	var ready=g.owned.filter(func(d): return int(d.get("star",0))==3 and int(d.get("level",0))==40 and g.Synthesis.EXISTING_SPECIAL_KINDS.has(d.kind))
	var supports=ready.filter(func(d): return not d.get("favorite",false))
	var possible=not preload("res://ui/growth_guidance.gd").synthesis_plan(g.owned,g.squad).is_empty()
	var summary=g.label(g.overlay,"합성 후보 %d마리 · 보조 가능 %d마리 | %s" % [ready.size(),supports.size(),"합성 가능 · 주재료를 선택하세요." if possible else "조건 부족 · 3성 Lv.40 세 마리 필요"],Vector2(230,205),18)
	summary.name="SynthesisCandidateSummary"
	var squad_notice=g.label(g.overlay,"동행 중 보조 재료는 합성 저장과 함께 동행에서 해제됩니다. 즐겨찾기는 보조로 소모할 수 없습니다.",Vector2(230,230),16)
	squad_notice.name="SynthesisSquadNotice"
	var scroll=ScrollContainer.new()
	scroll.name="SynthesisScroll"
	scroll.position=Vector2(230,260)
	scroll.size=Vector2(980,270)
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var ordered=g.owned.duplicate()
	ordered.sort_custom(func(a,b):
		var ar=int(a.get("star",0))==3 and int(a.get("level",0))==40
		var br=int(b.get("star",0))==3 and int(b.get("level",0))==40
		return ar and not br if ar!=br else int(a.id)<int(b.id))
	for d in ordered:
		var row=HBoxContainer.new()
		row.custom_minimum_size=Vector2(950,65)
		rows.add_child(row)
		var pick=Button.new()
		pick.name="SynthesisSelect_"+str(d.id)
		pick.text="선택 해제" if ids.has(d.id) else "재료 선택"
		pick.custom_minimum_size=Vector2(130,60)
		pick.disabled=not ids.has(d.id) and (ids.size()>=3 or not g.Synthesis.material_error(d,g.squad,d.id==main_id).is_empty())
		pick.pressed.connect(func():
			var next=ids.duplicate()
			if next.has(d.id): next.erase(d.id)
			else: next.append(d.id)
			g.show_synthesis(next,-1 if d.id==main_id and not next.has(d.id) else main_id,preserve))
		row.add_child(pick)
		var name_label=Label.new()
		var reason=g.Synthesis.material_error(d,g.squad,d.id==main_id)
		if reason.is_empty() and g.squad.has(d.id) and d.id!=main_id: reason="동행 중 · 합성 시 해제"
		name_label.text="%s %s Lv.%d · %s%s" % [g.Loot.title(d),g.NAMES[d.kind],d.level,d.trait," · "+reason if not reason.is_empty() else ""]
		name_label.custom_minimum_size=Vector2(660,60)
		name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size",17)
		row.add_child(name_label)
		var main=Button.new()
		main.name="SynthesisMain_"+str(d.id)
		main.text="주재료 ✓" if d.id==main_id else "주재료 지정"
		main.custom_minimum_size=Vector2(140,60)
		main.disabled=not g.Synthesis.material_error(d,g.squad,true).is_empty()
		main.pressed.connect(func():
			var next=ids.duplicate()
			if not next.has(d.id):
				if next.size()>=3: next.erase(main_id if next.has(main_id) else next[-1])
				next.append(d.id)
			g.show_synthesis(next,d.id,preserve))
		row.add_child(main)
	if g.owned.is_empty(): g.label(g.overlay,"아직 동료가 없습니다. 3성 Lv.40 동료를 육성해 주세요.",Vector2(240,280),20)
	g.button(g.overlay,("✓ " if preserve=="species" else "")+"종 보존",Rect2(230,545,225,50),func(): g.show_synthesis(ids,main_id,"species"))
	g.button(g.overlay,("✓ " if preserve=="position" else "")+"포지션 보존",Rect2(470,545,260,50),func(): g.show_synthesis(ids,main_id,"position"))
	var plan=g.Synthesis.preview(g.owned,g.squad,ids,main_id,preserve)
	g.label(g.overlay,"선택 %d / 3 · %s" % [ids.size(),plan.error if not plan.error.is_empty() else "후보를 확인할 수 있습니다."],Vector2(235,608),18)
	var confirm=g.button(g.overlay,"결과 후보 확인",Rect2(850,640,360,55),func(): g.preview_synthesis(ids,main_id,preserve))
	confirm.name="SynthesisCandidates"
	confirm.disabled=not plan.error.is_empty()
	g.button(g.overlay,"선택 초기화",Rect2(230,640,220,55),func(): g.show_synthesis())

static func show_result(g,ids,main_id,preserve):
	var plan=g.Synthesis.preview(g.owned,g.squad,ids,main_id,preserve)
	if not plan.error.is_empty():
		g.notify(plan.error)
		g.show_synthesis(ids,main_id,preserve)
		return
	g.modal("4성 특수개체 · 결과 후보","실제 추첨 전 후보 안내입니다. 동료·재료·랜덤 옵션은 변경되지 않습니다.","synthesis_candidates",func(): g.show_synthesis(ids,main_id,preserve))
	var names=PackedStringArray()
	for kind in plan.pool: names.append(g.NAMES[kind]+" 특수개체")
	g.label(g.overlay,"보존 방식: "+("종 보존" if preserve=="species" else "포지션 보존"),Vector2(235,225),22)
	var pool_list=g.label(g.overlay,"기존 종 후보 · 각 %.1f%%\n%s" % [100.0/plan.pool.size()," / ".join(names)],Vector2(235,270),22)
	pool_list.name="SynthesisPoolList"
	g.label(g.overlay,"예정 결과: 4성 Lv.1 · 주재료 %s #%d" % [g.NAMES[plan.main.kind],main_id],Vector2(235,350),22)
	g.label(g.overlay,"주재료 ID·특성·즐겨찾기·편성·기존 옵션 계승\n종이 바뀌어도 기존 옵션 유지 · 종에 따라 효과가 없을 수 있습니다.\n신규 특수종 목록·확률은 미정이며 현재 후보에 포함되지 않습니다.",Vector2(235,400),19)
	var parts=PackedStringArray()
	for d in plan.materials:
		if d.id!=main_id: parts.append("%s #%d" % [g.NAMES[d.kind],d.id])
	g.label(g.overlay,"합성 시 소비될 보조 동료: "+" / ".join(parts),Vector2(235,510),20)
	if not plan.leaving_squad.is_empty():
		var leaving_notice=g.label(g.overlay,"동행 자동 해제: %d마리 · 빈 동행 칸은 합성 후 다시 채울 수 있습니다." % plan.leaving_squad.size(),Vector2(235,535),17)
		leaving_notice.name="SynthesisLeavingNotice"
	g.label(g.overlay,"4성 Lv.1 기본 체력·공격은 같은 종 3성 만렙의70% · 소환 후 속성/고유 능력 선택",Vector2(235,575),18)
	g.button(g.overlay,"합성 최종 확인",Rect2(850,640,360,55),func(): show_confirmation(g,ids,main_id,preserve))
	g.button(g.overlay,"재료·보존 방식 다시 선택",Rect2(230,640,400,55),func(): g.show_synthesis(ids,main_id,preserve))

static func show_confirmation(g,ids,main_id,preserve):
	var plan=g.Synthesis.preview(g.owned,g.squad,ids,main_id,preserve)
	if not plan.error.is_empty(): g.notify(plan.error); return
	g.modal("합성을 실행할까요?","보조 두 마리는 소모되며 되돌릴 수 없습니다. 결과 종과 랜덤 옵션을 확정해 저장합니다.","synthesis_confirm",func(): show_result(g,ids,main_id,preserve))
	var y=245
	for d in plan.materials:
		g.label(g.overlay,("계승 · 주재료: " if d.id==main_id else "소모 · 보조 재료: ")+"%s #%d · %s" % [g.NAMES[d.kind],d.id,d.trait],Vector2(240,y),22)
		y+=65
	g.label(g.overlay,"결과: 4성 Lv.1 · 신규 랜덤 옵션2개 · 속성1개/고유 능력1개 선택
주재료 ID·특성·즐겨찾기·편성·기존 옵션은 유지됩니다.",Vector2(240,480),20)
	if not plan.leaving_squad.is_empty():
		var leaving_notice=g.label(g.overlay,"보조 재료 %d마리는 합성과 동시에 동행에서 해제됩니다." % plan.leaving_squad.size(),Vector2(240,550),18)
		leaving_notice.name="SynthesisLeavingNotice"
	g.button(g.overlay,"취소 · 후보 확인",Rect2(240,630,350,60),func(): show_result(g,ids,main_id,preserve))
	var b=g.button(g.overlay,"보조 두 마리로 합성",Rect2(850,630,350,60),func(): g.commit_synthesis(ids,main_id,preserve,plan.materials))
	b.name="CommitSynthesis"
	g.GroveUI.emphasize(b,"danger")
