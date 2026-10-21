extends RefCounted
const Roster=preload("res://ui/companion_roster.gd")

static func identity(g,d):
	var position=g.squad.find(d.id)
	return "#%d %s · %s Lv.%d · %s · %s%s" % [d.id,g.NAMES[d.kind],g.Loot.title(d),d.level,d.trait,Roster.status_text(position)," · 잠금" if d.get("favorite",false) else ""]

static func abilities(g,d):
	if not g.Special.ready(d): return "능력 선택 대기"
	var line=g.Special.ELEMENTS[g.Special.element(d)].name+" · "+g.Special.choices(d.kind)[g.Special.unique(d)].name
	var evolution=g.Special.evolution(d)
	if not evolution.is_empty(): line+=" · 진화: "+g.Special.evolution_choices(d.kind)[evolution].name
	return line

static func options(g,d):
	var parts=PackedStringArray()
	for option in g.Loot.all_options(d):
		parts.append("%s +%d%%" % [g.Loot.OPTIONS[option.key].name,int(option.value)])
	return "옵션: "+(" / ".join(parts) if not parts.is_empty() else "없음")

static func companion_info(g,parent,d,position,width=940):
	Roster.portrait(g,parent,d,Rect2(position+Vector2(10,14),Vector2(64,64)))
	Roster.small_label(parent,identity(g,d),Rect2(position+Vector2(88,7),Vector2(width-100,25)),18,g.Loot.color(d)).name="MaterialIdentity"
	Roster.small_label(parent,abilities(g,d),Rect2(position+Vector2(88,35),Vector2(width-100,24)),16).name="MaterialAbilities"
	var option_text=Roster.small_label(parent,options(g,d),Rect2(position+Vector2(88,61),Vector2(width-100,44)),15)
	option_text.name="MaterialOptions"
	option_text.clip_text=false
	option_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

static func show_page(g,id):
	var main=g.find_owned(id)
	if main.is_empty(): return
	var source=g.Loot.star(main)
	var target=source+1
	var result_level=1 if target==5 else 60
	var cap=60 if target==5 else 70
	g.modal("%d성 진화 · " % target+g.NAMES[main.kind],"#번호·특성·속성·옵션으로 재료를 확인하세요. 선택한 보조 동료 한 마리를 소비합니다.","evolution",func(): g.show_training(id))
	g.label(g.overlay,"유지: #%d %s · %d성 Lv.%d → %d성 Lv.%d / 상한%d" % [main.id,g.NAMES[main.kind],source,main.level,target,result_level,cap],Vector2(235,215),21).name="EvolutionMainIdentity"
	g.label(g.overlay,"성공100% · 추가 비용 없음 · 기존 능력/옵션 보존 · 보조 옵션 계승 없음",Vector2(235,250),18)
	g.label(g.overlay,"기본 체력·공격 +10% · "+("기존 진화 능력 자동 강화 · 재선택 없음" if target==6 else "Lv.1부터 재육성 · 진화 능력 하나 추가 선택"),Vector2(235,285),19)
	var scroll=ScrollContainer.new()
	scroll.name="EvolutionMaterials"
	scroll.position=Vector2(235,330)
	scroll.size=Vector2(975,280)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	for d in g.owned:
		if d.id==id: continue
		var error=g.Evolution.material_error(d,g.squad,false,source)
		var b=Button.new()
		b.custom_minimum_size=Vector2(940,140)
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		b.clip_contents=true
		b.disabled=not error.is_empty()
		b.name="EvolutionSupport_"+str(d.id)
		b.tooltip_text=identity(g,d)+"\n"+abilities(g,d)+"\n"+"\n".join(g.Loot.lines(d))+"\n"+("보조로 선택" if error.is_empty() else error)
		b.pressed.connect(func(): show_confirmation(g,id,d.id))
		rows.add_child(b)
		companion_info(g,b,d,Vector2.ZERO)
		Roster.small_label(b,"보조로 선택 →" if error.is_empty() else error,Rect2(88,112,835,22),16,Color("9ed5a2") if error.is_empty() else Color("bdaba2"))
	g.button(g.overlay,"동료 육성으로",Rect2(235,640,360,55),func(): g.show_training(id))

static func show_confirmation(g,id,support_id):
	var plan=g.Evolution.preview(g.owned,g.squad,id,support_id)
	if not plan.error.is_empty(): g.notify(plan.error); show_page(g,id); return
	var target=int(plan.result.star)
	var level=int(plan.result.level)
	var cap=g.Loot.max_level(plan.result)
	g.modal("%d성 진화 최종 확인" % target,"아래 #번호의 보조 동료를 소비합니다. 주 동료의 인연과 능력은 유지됩니다.","evolution_confirm",func(): show_page(g,id))
	var main=plan.materials[0]
	var support=plan.materials[1]
	g.label(g.overlay,"유지할 주 동료",Vector2(235,210),19).name="EvolutionKeep"
	companion_info(g,g.overlay,main,Vector2(235,225),975)
	g.label(g.overlay,"소비할 보조 동료 · 되돌릴 수 없음",Vector2(235,335),19).name="EvolutionConsume"
	companion_info(g,g.overlay,support,Vector2(235,365),975)
	g.label(g.overlay,"결과: #%d %s · %d성 Lv.%d / 최대%d · 성공100%% · 추가 비용 없음" % [main.id,g.NAMES[main.kind],target,level,cap],Vector2(235,475),21).name="EvolutionResult"
	g.label(g.overlay,"기본 체력·공격: %d성 Lv.%d의110%% → Lv.%d에130%%" % [target-1,main.level,cap],Vector2(235,520),20)
	g.label(g.overlay,("기존 능력 자동 강화: "+g.Special.evolution_description(plan.result) if target==6 else "진화 후 역할별 능력 3개 중1개 선택 · 기존 옵션 재추첨 없음"),Vector2(235,565),19)
	var confirm=g.button(g.overlay,"#%d 소비 · %d성 진화" % [support.id,target],Rect2(745,640,465,55),func(): g.commit_evolution(id,support_id,plan.materials))
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
