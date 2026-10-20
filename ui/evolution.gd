extends RefCounted
static func show_page(g,id):
	var main=g.find_owned(id)
	if main.is_empty(): return
	g.modal("5성 진화 · "+g.NAMES[main.kind],"주 동료는 유지하고, 선택한 보조 동료 한 마리를 소비합니다.","evolution",func(): g.show_training(id))
	g.label(g.overlay,"주 동료: "+g.NAMES[main.kind]+" · 4성 Lv.50 → 5성 Lv.50 / 상한60",Vector2(235,220),21)
	g.label(g.overlay,"성공100% · 추가 비용 없음 · 기존 능력/옵션 보존 · 보조 옵션 계승 없음",Vector2(235,260),18)
	g.label(g.overlay,"기본 체력·공격 +10% · 역할별 진화 능력 하나 추가 선택",Vector2(235,300),19)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(235,350)
	scroll.size=Vector2(975,245)
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for d in g.owned:
		if d.id==id: continue
		var error=g.Evolution.material_error(d,g.squad)
		var b=Button.new()
		b.text="%s · %s Lv.%d · %s" % [g.NAMES[d.kind],g.Loot.title(d),d.level,"보조로 선택" if error.is_empty() else error]
		b.custom_minimum_size=Vector2(940,52)
		b.disabled=not error.is_empty()
		b.name="EvolutionSupport_"+str(d.id)
		b.pressed.connect(func(): show_confirmation(g,id,d.id))
		rows.add_child(b)
	g.button(g.overlay,"동료 육성으로",Rect2(235,640,360,55),func(): g.show_training(id))
static func show_confirmation(g,id,support_id):
	var plan=g.Evolution.preview(g.owned,g.squad,id,support_id)
	if not plan.error.is_empty(): g.notify(plan.error); show_page(g,id); return
	g.modal("5성 진화 최종 확인","아래 보조 동료는 소비되며 되돌릴 수 없습니다. 주 동료의 인연과 능력은 유지됩니다.","evolution_confirm",func(): show_page(g,id))
	var main=plan.materials[0]
	var support=plan.materials[1]
	g.label(g.overlay,"유지: #%d %s · %s" % [main.id,g.NAMES[main.kind],g.Special.summary(main)],Vector2(235,230),19)
	g.label(g.overlay,"소비: #%d %s · 4성 Lv.50 · %s" % [support.id,g.NAMES[support.kind],support.trait],Vector2(235,290),23)
	g.label(g.overlay,"5성 Lv.50 / 최대60 · 성공100% · 추가 비용 없음",Vector2(235,365),22)
	g.label(g.overlay,"기본 체력·공격: 4성 Lv.50의110% → Lv.60에130%",Vector2(235,420),20)
	g.label(g.overlay,"진화 후 역할별 능력 3개 중1개 선택 · 기존 옵션 재추첨 없음",Vector2(235,475),19)
	var confirm=g.button(g.overlay,"보조 동료 소비 · 5성 진화",Rect2(745,640,465,55),func(): g.commit_evolution(id,support_id,plan.materials))
	confirm.name="ConfirmEvolution"
	g.button(g.overlay,"돌아가기",Rect2(235,640,360,55),func(): show_page(g,id))
static func show_choice(g,id,selected=""):
	var d=g.find_owned(id)
	if not g.Special.evolution_pending(d): return
	var expected=d.duplicate(true)
	g.modal("5성 진화 능력 · "+g.NAMES[d.kind],"기존 속성·고유 능력·옵션은 유지됩니다. 추가 능력을 하나 선택해 영구 확정하세요.","evolution_choice",g.open_roster)
	g.label(g.overlay,g.Special.ELEMENTS[g.Special.element(d)].name+" · "+g.Special.choices(d.kind)[g.Special.unique(d)].name+" · 기존 옵션 모두 보존",Vector2(235,230),20)
	var index=0
	for key in g.Special.evolution_choices(d.kind):
		var info=g.Special.evolution_choices(d.kind)[key]
		var b=g.button(g.overlay,("✓ " if selected==key else "")+info.name+"\n"+info.description,Rect2(235,310+index*88,975,65),func(): show_choice(g,id,key))
		b.name="EvolutionAbility_"+key
		b.tooltip_text=info.description
		index+=1
	g.label(g.overlay,g.Special.evolution_choices(d.kind).get(selected,{"description":"3개 중 하나를 선택하세요. 선택 전에는 탐험을 출발할 수 없습니다."}).description,Vector2(235,590),20)
	var confirm=g.button(g.overlay,"진화 능력 최종 확정",Rect2(810,640,400,55),func(): g.commit_evolution_choice(id,selected,expected))
	confirm.name="ConfirmEvolutionChoice"
	confirm.disabled=selected.is_empty()
	g.button(g.overlay,"나중에 선택 · 동료 관리",Rect2(235,640,370,55),g.open_roster)
