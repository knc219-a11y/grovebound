extends RefCounted
static func show_page(g,id,element="",unique=""):
	var d=g.find_owned(id)
	if not g.Special.pending(d): return
	var expected=d.duplicate(true)
	g.modal("4성 특수개체 · "+g.NAMES[d.kind],"소환 결과와 랜덤 옵션은 이미 확정됐습니다. 선택은 한 번이며 변경할 수 없습니다.","special_choice",g.open_roster)
	g.label(g.overlay,"고정 특성: "+d.trait+" · 계승 옵션 "+str(d.get("options",[]).size())+"개",Vector2(235,215),18)
	var lines=PackedStringArray()
	for option in d.special.affixes: lines.append("%s +%d%%" % [g.Loot.OPTIONS[option.key].name,option.value])
	g.label(g.overlay,"신규 랜덤 옵션: "+" / ".join(lines),Vector2(235,247),18)
	g.label(g.overlay,"공통 속성 · 하나 선택",Vector2(235,290),21)
	var index=0
	for key in g.Special.ELEMENTS:
		var info=g.Special.ELEMENTS[key]
		var b=g.button(g.overlay,("✓ " if element==key else "")+info.name,Rect2(235+index*245,330,230,50),func(): show_page(g,id,key,unique))
		b.name="Element_"+key
		b.disabled=info.get("pending",false)
		b.tooltip_text=info.description
		index+=1
	g.label(g.overlay,g.Special.ELEMENTS[element].description if g.Special.ELEMENTS.has(element) else "불꽃·물·대지·바람 중 하나를 선택합니다. 물: 스킬 재사용 대기시간15% 감소.",Vector2(235,390),17)
	g.label(g.overlay,"야수 고유 능력 · 하나 선택",Vector2(235,430),21)
	index=0
	for key in g.Special.choices(d.kind):
		var info=g.Special.choices(d.kind)[key]
		var b=g.button(g.overlay,("✓ " if unique==key else "")+info.name,Rect2(235+index*330,470,315,50),func(): show_page(g,id,element,key))
		b.name="Unique_"+key
		b.tooltip_text=info.description
		index+=1
	g.label(g.overlay,g.Special.choices(d.kind)[unique].description if g.Special.choices(d.kind).has(unique) else "결과 종의 역할에 맞는 능력 중 하나를 선택합니다.",Vector2(235,535),18)
	g.label(g.overlay,g.Special.SKILLS[d.kind]+": "+g.Special.SKILL_DESCRIPTIONS[d.kind],Vector2(235,580),18)
	var confirm=g.button(g.overlay,"선택 최종 확정",Rect2(850,640,360,55),func(): g.commit_special_choice(id,element,unique,expected))
	confirm.name="ConfirmSpecial"
	confirm.disabled=element.is_empty() or unique.is_empty()
	g.button(g.overlay,"나중에 선택 · 동료 관리",Rect2(235,640,370,55),g.open_roster)
