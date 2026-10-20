extends RefCounted
const Campaign=preload("res://campaign.gd")
const Species=preload("res://creature_species.gd")
static func stages(g):
	if g.mode!="camp": return
	g.modal("사냥길 선택","드루이드는 야수와 교감합니다. 마물과 언데드는 다른 계열의 인연을 기다립니다.","stages",g.resume_game)
	for id in [1,2,3]:
		var stage=Campaign.STAGES[id]
		var x=230+(id-1)*330
		var accessible=Campaign.accessible(id,g.cleared_stages)
		g.panel(g.overlay,Rect2(x,235,310,340),g.GroveUI.INK)
		g.label(g.overlay,"%02d · %s" % [id,stage.name],Vector2(x+16,260),23)
		g.label(g.overlay,"권장 동료 Lv.%d" % stage.level,Vector2(x+16,310),18)
		var description=stage.theme.replace(" · ","\n")
		g.label(g.overlay,description,Vector2(x+16,352),18)
		var available=Campaign.tamable_kinds(id,g.PLAYER_CLASS)
		var missing=available.filter(func(kind): return kind not in g.discovered)
		var bonds=g.label(g.overlay,"교감 가능 %d종 · 미확보 %d종" % [available.size(),missing.size()],Vector2(x+16,442),16)
		bonds.tooltip_text="\n".join(available.map(func(kind): return Species.name_of(kind)))+"\n일반 보상 대상에게 교감 기회 15%"
		var status="우두머리 제압 완료" if id in g.cleared_stages else "탐험 가능" if accessible else "앞 지역의 우두머리를 제압하세요"
		g.label(g.overlay,status,Vector2(x+16,470),16)
		var b=g.button(g.overlay,"출발" if accessible else "아직 닫힌 길",Rect2(x+16,510,278,48),func(): g.depart_stage(id))
		b.disabled=not accessible or g.squad.is_empty()
	g.label(g.overlay,"권장 레벨은 입장 제한이 아닙니다. 활동 동료와 지원 스킬을 준비하세요.",Vector2(235,610),17)
	g.button(g.overlay,"마을로",Rect2(925,650,285,45),g.resume_game)
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
