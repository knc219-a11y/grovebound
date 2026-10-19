extends RefCounted
static func show_report(g):
	var r=g.expedition.report
	if r.is_empty(): return
	var leave=g.show_camp if g.mode=="result" else g.resume_game
	g.modal("이번 탐험의 발자취",r.outcome+" · 이번 탐험에서 맺은 인연과 성장을 확인하세요.","recap",leave)
	var values=["새로운 인연  %d" % r.newcomers.size(),"성장 재료  %+d" % r.materials,"제압 %d · %02d:%02d" % [r.kills,r.seconds/60,r.seconds%60]]
	for i in 3:
		g.panel(g.overlay,Rect2(230+i*330,215,310,58),Color("202823"))
		g.label(g.overlay,values[i],Vector2(248+i*330,232),21)
	for side in 2:
		var x=230+side*500
		g.label(g.overlay,"함께 돌아온 인연" if side==0 else "전투 기여" if g.report_contributions else "동료 성장",Vector2(x,294),23)
		if side==1:
			g.button(g.overlay,"성장 보기" if g.report_contributions else "기여 보기",Rect2(x+330,287,150,42),func(): g.report_contributions=not g.report_contributions; g.show_run_report())
		g.panel(g.overlay,Rect2(x,335,480,170),Color("202823"))
		var scroll=ScrollContainer.new()
		scroll.name="NewBonds" if side==0 else "GrowthLedger"
		scroll.position=Vector2(x+12,345)
		scroll.size=Vector2(456,150)
		g.overlay.add_child(scroll)
		var rows=VBoxContainer.new()
		rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		rows.add_theme_constant_override("separation",10)
		scroll.add_child(rows)
		var entries=r.newcomers if side==0 else r.get("contributions",[]) if g.report_contributions else r.growth
		if entries.is_empty():
			var empty=Label.new()
			empty.text="새로운 인연이 없어도 탐험은 이어집니다." if side==0 else "이번에는 전투 기여 기록이 없습니다." if g.report_contributions else "이번에는 경험치 변화가 없습니다."
			empty.add_theme_font_size_override("font_size",17)
			rows.add_child(empty)
		for d in entries:
			var line=Label.new()
			line.custom_minimum_size=Vector2(420,40)
			line.add_theme_font_size_override("font_size",19)
			if side==0:
				line.text="[%s] %s Lv.%d · %s" % [g.Loot.title(d),g.NAMES[d.kind],d.level,g.ROLES[d.kind]]
				line.add_theme_color_override("font_color",g.Loot.color(d))
			elif g.report_contributions:
				line.add_theme_font_size_override("font_size",16)
				var v=d["values"]
				line.text="%s · %s · %s\n피해 %.0f / 회복 %.0f / 경감 %.0f · 스킬 %d회" % [g.NAMES[d.kind],g.Roles.LABELS[d.kind],d.trait,v.get("damage",0),v.get("healing",0),v.get("mitigation",0),v.get("skills",0)]
				line.custom_minimum_size.y=54
			else: line.text="%s  Lv.%d → %d  · 경험치 +%d" % [g.NAMES[d.kind],d.from,d.to,d.xp]
			rows.add_child(line)
	g.label(g.overlay,"다음 준비",Vector2(235,530),20)
	var tip="동료 쉼터에서 역할을 비교하고 편성을 준비하세요.\n육성은 재료 3개로 경험치 40 · 동쪽 사냥길에서 다시 출발합니다."
	if g.owned.is_empty(): tip="동쪽 사냥길에서 첫 인연을 만나보세요.\n전투 뒤 쉬는 야수에게 다가가 교감할 수 있습니다."
	g.label(g.overlay,tip,Vector2(235,566),18)
	if g.report_contributions: g.label(g.overlay,"피해·회복은 실제 적용량, 경감은 해당 공격에서 막은 체력 피해입니다.",Vector2(235,613),14)
	var b=g.button(g.overlay,"마을에서 준비하기" if g.mode=="result" else "마을로 돌아가기",Rect2(925,640,285,55),leave)
	g.GroveUI.emphasize(b)
	if g.mode=="camp" and not g.owned.is_empty(): g.button(g.overlay,"동료 · 편성 · 육성",Rect2(230,640,310,55),g.open_roster)
