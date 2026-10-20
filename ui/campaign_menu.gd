extends RefCounted
const Campaign=preload("res://campaign.gd")
const Species=preload("res://creature_species.gd")
static func stages(g):
	if g.mode!="camp": return
	var R=g.Routes
	var progress=R.progress_for(g)
	var theme=g.map_theme
	var difficulty=g.map_difficulty
	g.modal("탐험 지도" if theme==0 else R.THEMES[theme]+" · 스테이지", "끊어진 물길을 따라 동료들과 순환의 흔적을 찾으세요.","stages",g.resume_game)
	for i in 3:
		var value=R.DIFFICULTIES[i]
		var text=R.DIFFICULTY_NAMES[value]+(" · 준비 중" if i>0 else "")
		var b=g.button(g.overlay,text,Rect2(230+i*220,205,208,42),func(): g.map_difficulty=value; g.map_theme=0; stages(g))
		b.name="Difficulty_"+value
		if value==difficulty: g.GroveUI.emphasize(b)
	var map=preload("res://ui/exploration_map.gd").new()
	map.name="ExplorationMap"; map.position=Vector2(230,260); map.size=Vector2(660,340)
	map.theme_id=theme
	g.overlay.add_child(map)
	g.panel(g.overlay,Rect2(910,260,300,340),g.GroveUI.INK)
	if theme==0:
		map.points=[Vector2(75,220),Vector2(205,110),Vector2(335,225),Vector2(460,125),Vector2(580,240)]
		for id in range(1,6):
			var count=0
			for stage in range(1,9):
				if R.contains(progress,R.coordinate(id,stage,difficulty)): count+=1
			if count==8: map.cleared.append(id-1)
			var pos=map.position+map.points[id-1]
			var b=g.button(g.overlay,str(id),Rect2(pos-Vector2(28,24),Vector2(56,48)),func(): g.map_theme=id; g.map_stage=1; stages(g))
			b.name="Theme_"+str(id)
			g.GroveUI.quiet(b)
			var label=g.label(g.overlay,R.THEMES[id],pos+Vector2(-65,44),17)
			label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			g.label(g.overlay,"%d/8" % count if id<4 and difficulty=="normal" else "구현 예정",pos+Vector2(-28,70),14)
		g.label(g.overlay,"순환을 잇는 여정",Vector2(930,282),22)
		wrapped(g,"일반 · 5개 테마\n테마마다 8개 스테이지\n4번 중간보스\n8번 테마 보스",Vector2(930,330),260,19)
		wrapped(g,"일반 5-8 → 심층\n심층 5-8 → 도전\n현재 일반 계곡 1-1~1-8을 탐험할 수 있습니다.",Vector2(930,440),260,17)
		var available=Campaign.tamable_kinds(1,g.PLAYER_CLASS)
		var bonds=g.label(g.overlay,"계곡 · 교감 가능 %d종" % available.size(),Vector2(930,548),16)
		bonds.tooltip_text="\n".join(available.map(func(kind): return Species.name_of(kind)))
		if difficulty!="normal": wrapped(g,"이 난이도는 아직 준비 중입니다. 먼저 일반 탐험을 이어가세요.",Vector2(255,275),450,17)
	else:
		map.points=[Vector2(70,100),Vector2(230,85),Vector2(390,110),Vector2(555,90),Vector2(555,245),Vector2(390,225),Vector2(230,250),Vector2(70,230)]
		map.selected=g.map_stage-1
		for stage in range(1,9):
			var c=R.coordinate(theme,stage,difficulty)
			var done=R.contains(progress,c)
			if done: map.cleared.append(stage-1)
			var p=map.position+map.points[stage-1]
			var b=g.button(g.overlay,"%d-%d" % [theme,stage],Rect2(p-Vector2(36,25),Vector2(72,50)),func(): g.map_stage=stage; stages(g))
			b.name="Stage_"+str(stage)
			g.GroveUI.quiet(b)
			b.tooltip_text="중간보스" if stage==4 else "테마 보스" if stage==8 else "일반 길목"
			g.label(g.overlay,"완료" if done else "탐험 가능" if R.available(c,progress) else "준비 중" if not R.implemented(c) else "미해금",p+Vector2(-27,32),14)
		var selected=R.coordinate(theme,g.map_stage,difficulty)
		var data=R.profile(selected)
		g.label(g.overlay,"%d-%d · %s" % [theme,g.map_stage,"중간보스" if g.map_stage==4 else "테마 보스" if g.map_stage==8 else "탐험"],Vector2(930,280),21)
		if not data.is_empty():
			wrapped(g,data.name,Vector2(930,318),260,22)
			wrapped(g,data.story,Vector2(930,355),260,17)
			var reward=R.rewards(selected)
			wrapped(g,"적 Lv.%d · 활동4 / 준비6\n본선 전투 XP %d / 동행 각각\n재료 %d · 옆길 보상 별도\n야수 교감 15%% · 1성",Vector2(930,433),260,16,[data.level,reward.xp,reward.materials])
			var available=R.available(selected,progress)
			var b=g.button(g.overlay,"선택한 스테이지 출발" if available else "이전 스테이지를 완료하세요",Rect2(925,548,270,42),func(): g.depart_route(selected))
			b.name="DepartRoute"; b.disabled=not available or g.squad.is_empty()
			g.GroveUI.emphasize(b)
		else:
			wrapped(g,"스테이지 확장을 준비 중입니다. 완료 기록은 보존됩니다.",Vector2(930,330),260,19)
			if difficulty=="normal" and theme in [2,3]:
				wrapped(g,"기존 사냥터는 계속 탐험할 수 있습니다. 지역 보스를 제압하면 해당 테마의 완료 기록을 보존합니다.",Vector2(930,420),260,17)
				var b=g.button(g.overlay,"기존 사냥터 탐험",Rect2(925,548,270,42),func(): g.depart_stage(theme))
				b.name="DepartLegacy"; b.disabled=not Campaign.accessible(theme,g.cleared_stages) or g.squad.is_empty()
				if b.disabled: b.tooltip_text="앞 테마의 우두머리를 제압하세요."
			else: wrapped(g,"앞 테마 완료 후 순서대로 해금됩니다. 아직 출발할 수 없습니다.",Vector2(930,440),260,17)
	map.queue_redraw()
	g.label(g.overlay,"지역을 고른 뒤 스테이지를 선택하고 출발하세요. 완료한 길은 다시 탐험할 수 있습니다.",Vector2(235,618),16)
	if theme>0: g.button(g.overlay,"세계 지도",Rect2(230,655,250,45),func(): g.map_theme=0; stages(g))
	g.button(g.overlay,"마을로",Rect2(925,655,285,45),g.resume_game)

static func wrapped(g,text,p,width,font_size,values=[]):
	# Labels added to a plain Control can retain their initial natural minimum width.
	# Measure explicit lines with the actual pixel font so long Korean text stays inside.
	var source=text % values if not values.is_empty() else text
	var lines=[]
	for paragraph in source.split("\n"):
		var line=""
		for letter in paragraph:
			if not line.is_empty() and g.font.get_string_size(line+letter,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
				var space=line.rfind(" ")
				if space>0:
					lines.append(line.substr(0,space)); line=line.substr(space+1)
				else:
					lines.append(line); line=""
			line+=letter
		lines.append(line)
	return g.label(g.overlay,"\n".join(lines),p,font_size)

static func collection(g):
	g.modal("생물 도감","만난 생물의 계열과 교감 조건을 확인합니다. 보유 동료의 기록은 계속 보존됩니다.","collection",g.open_game_menu)
	var scroll=ScrollContainer.new()
	scroll.name="CreatureCollection"
	scroll.position=Vector2(230,220); scroll.size=Vector2(990,390)
	g.overlay.add_child(scroll)
	var grid=GridContainer.new(); grid.columns=3
	grid.add_theme_constant_override("h_separation",18); grid.add_theme_constant_override("v_separation",14)
	scroll.add_child(grid)
	for kind in Species.kinds():
		var found=kind in g.seen_species or kind in g.discovered
		var card=PanelContainer.new(); card.custom_minimum_size=Vector2(310,218)
		var style=g.GroveUI.frame(g.GroveUI.INK)
		style.content_margin_left=0; style.content_margin_right=0
		style.content_margin_top=0; style.content_margin_bottom=0
		card.add_theme_stylebox_override("panel",style)
		grid.add_child(card)
		# Children of a plain Control preserve manual placement inside the themed card.
		var content=Control.new(); content.custom_minimum_size=Vector2(310,218); card.add_child(content)
		g.label(content,Species.name_of(kind) if found else "미발견",Vector2(108,16),21)
		var picture=TextureRect.new(); picture.texture=g.textures.get(kind)
		picture.position=Vector2(12,25); picture.size=Vector2(82,85)
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.modulate=Color.WHITE if found else Color(0.15,0.18,0.16)
		content.add_child(picture)
		g.label(content,Species.FAMILIES.get(Species.family(kind),""),Vector2(108,50),17)
		g.label(content,Species.condition(kind,g.PLAYER_CLASS) if found else "탐험에서 만나보세요",Vector2(12,112),16)
		var places=Campaign.habitats(kind)
		var location="출현 · "+str(places[0])+(" 외 %d곳" % (places.size()-1) if places.size()>1 else "") if found and not places.is_empty() else "출현 지역 미확인"
		var habitat=g.label(content,location,Vector2(12,142),15)
		habitat.tooltip_text="\n".join(places) if found else ""
		var count=0
		for d in g.owned:
			if d.kind==kind: count+=1
		g.label(content,"보유 %d마리" % count if found and Species.can_tame(kind,g.PLAYER_CLASS) else "",Vector2(108,82),16)
		if found and Species.can_tame(kind,g.PLAYER_CLASS):
			var b=g.button(content,"동료 찾아보기" if count>0 else "현재 보유 없음",Rect2(108,177,182,32),func(): g.open_species_roster(kind))
			b.disabled=count==0 or (g.in_combat and g.mode=="stage") or g.mode=="tutorial"
	g.label(g.overlay,"드루이드 · 야수 교감",Vector2(235,647),18)
	g.button(g.overlay,"메뉴로",Rect2(925,630,285,55),g.open_game_menu)
