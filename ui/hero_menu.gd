extends RefCounted
const H=preload("res://hero_progression.gd")
const UI=preload("res://ui/grove_ui.gd")
const SLOT_NAMES={"weapon":"무기","armor":"방어구","charm1":"부적 1","charm2":"부적 2"}
static func show_page(g,page=0,selected=0,filter=0,order=0,scroll_y=0):
	g.modal("드루이드 · 성장과 장비","Lv.%d   /   %s   /   골드 %d G" % [g.hero.level,"최대 레벨" if g.hero.level==H.CAP else "경험치 %d / %d" % [g.hero.xp,g.hero.level*100],g.hero.gold],"hero",g.open_game_menu)
	for i in 4:
		var b=g.button(g.overlay,["능력치","장비","지원 스킬","장비 상점"][i],Rect2(230+i*247,213,235,44),func(): show_page(g,i))
		if page==i: UI.emphasize(b)
	if page==0:
		var base=H.base_stats(g.hero)
		var total=H.stats(g.hero)
		g.panel(g.overlay,Rect2(230,278,470,310),UI.INK)
		g.label(g.overlay,"능력치                  기본 / 장비 / 합계",Vector2(250,293),21)
		var names={"hp":"체력","attack":"공격력","defense":"방어력","support":"회복 지원 %","haste":"재사용 감소 %"}
		var row=0
		for key in names:
			var scale=100 if key=="haste" else 1
			g.label(g.overlay,"%s     %.1f  /  +%.1f  /  %.1f" % [names[key],base[key]*scale,(total[key]-base[key])*scale,total[key]*scale],Vector2(250,338+row*43),18)
			row+=1
		g.label(g.overlay,"동료를 이끄는 지원 드루이드\n\n전투 경험치로 자동 성장 · 최대 Lv.30\n방어력은 주인공 피해만 감소합니다.\n회복 지원은 주인공 회복량을 높입니다.\n재사용 감소는 최대 30%입니다.\n\n장비 변경·구매·강화는 캠프에서 가능합니다.",Vector2(735,295),20)
	elif page==2:
		for i in 4:
			var key=H.SKILLS[i]
			var y=280+i*77
			g.label(g.overlay,"%s  %s" % [H.NAMES[key],"미습득" if g.hero.skills[key]==0 else "%d / 5단계" % g.hero.skills[key]],Vector2(240,y),21)
			g.label(g.overlay,H.skill_text(g.hero,key),Vector2(240,y+31),17)
			var plan=H.plan(g.hero,"skill",key)
			var b=g.button(g.overlay,"%d G · %s" % [plan.cost,"습득" if g.hero.skills[key]==0 else "강화"] if plan.error.is_empty() else plan.error,Rect2(920,y,280,51),func(): confirm(g,"skill",key,page,selected,H.NAMES[key]))
			b.disabled=g.mode!="camp" or not plan.error.is_empty()
	elif page==3:
		var scroll=list_box(g,Vector2(230,277),Vector2(980,320))
		for key in H.CATALOG:
			var d=H.CATALOG[key]
			var row=HBoxContainer.new()
			scroll.add_child(row)
			var picture=Control.new()
			picture.custom_minimum_size=Vector2(54,50)
			row.add_child(picture)
			preload("res://ui/equipment_inventory.gd").add_icon(picture,key,Rect2(0,0,48,48))
			var label=Label.new()
			label.text="%s · Lv.%d    %s" % [d.name,d.level,stat_line(H.item_stats({"catalog":key,"enhance":0}))]
			label.custom_minimum_size=Vector2(680,50)
			label.add_theme_font_size_override("font_size",18)
			row.add_child(label)
			var b=Button.new()
			b.text="구매 %d G" % d.price
			b.custom_minimum_size=Vector2(190,50)
			b.disabled=g.mode!="camp" or g.hero.level<d.level or g.hero.gold<d.price
			b.pressed.connect(func(): confirm(g,"buy",key,page,selected,d.name))
			row.add_child(b)
	else:
		preload("res://ui/equipment_inventory.gd").show(g,selected,filter,order,scroll_y,
			func(id,type,sort,y): show_page(g,page,id,type,sort,y),
			func(action,arg,id,caption,y): confirm(g,action,arg,page,id,caption,filter,order,y))
	g.button(g.overlay,"메뉴로",Rect2(230,630,235,55),g.open_game_menu)
	g.label(g.overlay,"캠프에서 관리 가능" if g.mode!="camp" else "자동 저장 · 동료 성장 재료와 별도 재화",Vector2(500,648),17)
	g.button(g.overlay,"돌아가기",Rect2(975,630,235,55),g.resume_game)
static func list_box(g,pos,dimensions):
	var scroll=ScrollContainer.new()
	scroll.position=pos; scroll.size=dimensions
	g.overlay.add_child(scroll)
	var box=VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	scroll.add_child(box)
	return box
static func stat_line(s):
	var parts=[]
	for k in ["hp","attack","defense","support","haste"]:
		if s[k]>0: parts.append({"hp":"체력","attack":"공격","defense":"방어","support":"회복%","haste":"감소%"}[k]+" +%.1f" % (s[k]*(100 if k=="haste" else 1)))
	return " · ".join(parts)
static func delta_line(before,after):
	var parts=[]
	for k in before:
		var delta=(after[k]-before[k])*(100 if k=="haste" else 1)
		if absf(delta)>0.001: parts.append({"hp":"체력","attack":"공격","defense":"방어","support":"회복%","haste":"감소%"}[k]+" %+.1f" % delta)
	return " · ".join(parts) if not parts.is_empty() else "변화 없음"
static func confirm(g,action,arg,page,selected,caption,filter=0,order=0,scroll_y=0):
	var expected=g.hero.duplicate(true)
	var plan=H.plan(expected,action,arg)
	if not plan.error.is_empty(): g.notify(plan.error); return
	g.modal(caption,"%s · %s" % [{"buy":"구매","equip":"장착","unequip":"해제","sell":"판매","enhance":"강화","skill":"스킬 성장"}[action],"캠프에서 골드를 사용합니다." if plan.cost>0 else "변경 내용을 확인하세요."],"hero",func(): show_page(g,page,selected,filter,order,scroll_y))
	g.label(g.overlay,"골드 %d → %d G\n\n%s" % [expected.gold,plan.after.gold,delta_line(H.stats(expected),H.stats(plan.after))],Vector2(260,290),24)
	if action=="skill": g.label(g.overlay,H.skill_text(expected,arg)+"\n→ "+H.skill_text(plan.after,arg),Vector2(260,430),20)
	if action=="enhance": g.label(g.overlay,H.title(H.find(expected,arg))+" → "+H.title(H.find(plan.after,arg))+"\n확정 강화 · 최대 +5",Vector2(260,430),22)
	if action=="sell": g.label(g.overlay,"판매하면 해당 장비가 사라집니다.",Vector2(260,430),22)
	g.button(g.overlay,"확인",Rect2(230,630,450,55),func():
		if g.commit_hero_action(action,arg,expected): show_page(g,page,selected,filter,order,scroll_y)
		else:
			g.modal("변경하지 못했습니다",g.message,"hero",func(): show_page(g,page,selected,filter,order,scroll_y))
			g.label(g.overlay,"골드와 장비는 소모되지 않았습니다.\n캠프에서 현재 정보를 다시 확인하세요.",Vector2(260,330),24)
			g.button(g.overlay,"돌아가기",Rect2(925,630,285,55),func(): show_page(g,page,selected,filter,order,scroll_y)))
	g.button(g.overlay,"취소",Rect2(925,630,285,55),func(): show_page(g,page,selected,filter,order,scroll_y))
