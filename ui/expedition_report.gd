extends RefCounted
static func show_report(g):
	var r=g.expedition.report
	if r.is_empty(): return
	var leave=g.show_camp if g.mode=="result" else g.resume_game
	g.modal("이번 탐험의 발자취 · "+(g.Routes.title(r.route) if not r.get("route",{}).is_empty() else g.Campaign.STAGES[int(r.get("stage_id",1))].name),r.outcome if not r.get("route",{}).is_empty() else r.outcome+" · 이번 탐험에서 맺은 인연과 성장을 확인하세요.","recap",leave)
	var values=["새로운 인연  %d" % r.newcomers.size(),"성장 재료  %+d" % r.materials,"제압 %d · %02d:%02d" % [r.kills,r.seconds/60,r.seconds%60]]
	for i in 3:
		g.panel(g.overlay,Rect2(230+i*330,215,310,58),Color("202823"))
		g.label(g.overlay,values[i],Vector2(248+i*330,232),21)
	if g.report_contributions:
		show_graphs(g,r,leave)
		return
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
				line.text="%s · %s · %s · 스킬 %d회" % [g.NAMES[d.kind],g.Roles.LABELS[d.kind],d.trait,v.get("skills",0)]
				line.custom_minimum_size.y=28
				rows.add_child(line)
				var graph=preload("res://ui/contribution_chart.gd").new()
				graph.custom_minimum_size=Vector2(420,76)
				graph.values=v
				for metric in ["damage","healing","mitigation"]:
					var largest=0.0
					for member in entries: largest=maxf(largest,member["values"].get(metric,0.0))
					graph.maximums[metric]=largest
				rows.add_child(graph)
				continue
			else: line.text="%s  Lv.%d → %d  · 경험치 +%d" % [g.NAMES[d.kind],d.from,d.to,d.xp]
			rows.add_child(line)
	g.label(g.overlay,"다음 준비",Vector2(235,530),20)
	var tip="동료 쉼터에서 역할을 비교하고 편성을 준비하세요.\n육성은 재료 3개로 경험치 40 · 동쪽 사냥길에서 다시 출발합니다."
	if g.owned.is_empty(): tip="동쪽 사냥길에서 첫 인연을 만나보세요.\n전투 뒤 쉬는 야수에게 다가가 교감할 수 있습니다."
	g.label(g.overlay,tip,Vector2(235,566),18)
	if g.report_contributions: g.label(g.overlay,"막대는 항목별 최대 동료 대비 비율 · 숫자는 실제 적용량입니다.",Vector2(235,613),14)
	var b=g.button(g.overlay,"마을에서 준비하기" if g.mode=="result" else "마을로 돌아가기",Rect2(925,640,285,55),leave)
	g.GroveUI.emphasize(b)
	var stage_id=int(r.get("stage_id",1))
	if g.mode=="result" and g.run_success and not r.get("route",{}).is_empty():
		var next=g.Routes.next(r.route)
		if g.Routes.available(next,g.Routes.progress_for(g)):
			g.button(g.overlay,"다음 스테이지",Rect2(565,640,330,55),func(): g.depart_route(next))
		elif g.Routes.valid(next) and next.difficulty!=r.route.difficulty:
			g.button(g.overlay,g.Routes.DIFFICULTY_NAMES[next.difficulty]+" 해금 · 지도",Rect2(565,640,330,55),func(): g.show_camp(); g.map_difficulty=next.difficulty; g.map_theme=0; g.open_stage_select())
		elif g.Routes.valid(next) and next.difficulty=="normal" and int(next.stage)==1 and g.Campaign.accessible(int(next.theme),g.cleared_stages):
			g.button(g.overlay,g.Campaign.STAGES[int(next.theme)].name+"으로",Rect2(565,640,330,55),func(): g.depart_stage(int(next.theme)))
		else:
			g.button(g.overlay,"탐험 지도",Rect2(565,640,330,55),func(): g.show_camp(); g.open_stage_select())
	elif g.mode=="result" and g.run_success and stage_id<3:
		g.button(g.overlay,"다음 지역으로",Rect2(565,640,330,55),func(): g.depart_stage(stage_id+1))
	if g.mode=="camp" and not g.owned.is_empty(): g.button(g.overlay,"동료 · 편성 · 육성",Rect2(230,640,310,55),g.open_roster)

static func show_graphs(g,r,leave):
	g.label(g.overlay,"동료별 전투 기여",Vector2(235,294),23)
	g.label(g.overlay,"각 항목의 최대 동료 대비 길이 · 수치는 실제 적용량",Vector2(670,301),15)
	g.panel(g.overlay,Rect2(230,335,980,255),Color("202823"))
	var scroll=ScrollContainer.new()
	scroll.name="ContributionGraphs"
	scroll.position=Vector2(242,345)
	scroll.size=Vector2(952,235)
	g.overlay.add_child(scroll)
	var rows=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",4)
	scroll.add_child(rows)
	var entries=r.get("contributions",[])
	var maxima={"damage":0.0,"healing":0.0,"mitigation":0.0}
	for d in entries:
		for metric in maxima: maxima[metric]=maxf(maxima[metric],d["values"].get(metric,0.0))
	for d in entries:
		var title=Label.new()
		title.text="%s · %s · %s · 스킬 %d회" % [g.NAMES[d.kind],g.Roles.LABELS[d.kind],d.trait,d["values"].get("skills",0)]
		title.add_theme_font_size_override("font_size",17)
		title.custom_minimum_size=Vector2(920,22)
		rows.add_child(title)
		var graph=preload("res://ui/contribution_chart.gd").new()
		graph.custom_minimum_size=Vector2(920,27)
		graph.values=d["values"]
		graph.maximums=maxima
		rows.add_child(graph)
	if entries.is_empty(): g.label(g.overlay,"이번 탐험의 전투 기여 기록이 없습니다.",Vector2(260,390),20)
	g.label(g.overlay,"초과 피해·회복 제외 · 경감은 실제로 막은 체력 손실 · 기록 확인으로 보상은 바뀌지 않습니다.",Vector2(235,610),14)
	g.button(g.overlay,"성장 기록 보기",Rect2(230,640,285,55),func(): g.report_contributions=false; g.show_run_report())
	g.button(g.overlay,"마을로 돌아가기",Rect2(925,640,285,55),leave)
