extends RefCounted
const H=preload("res://hero_progression.gd")
const Icon=preload("res://ui/equipment_icon.gd")
static func items(g):
	# A pending reward is never presented as a confirmed acquisition.
	if not g.hero_pending.is_empty() or g.expedition.report.is_empty() or not g.expedition.baseline.has("hero"): return []
	return g.expedition.report.get("equipment",[]).duplicate(true)
static func acquired(before,after):
	var old_ids=[]
	for item in before.items: old_ids.append(item.id)
	return after.items.filter(func(item): return item.id not in old_ids).duplicate(true)
static func show(g):
	var found=items(g)
	if found.is_empty(): return false
	g.label(g.overlay,"이번 탐험에서 발견한 장비 · %d개" % found.size(),Vector2(235,520),20)
	var compare=g.button(g.overlay,"장비 비교 · 관리",Rect2(1000,515,210,36),func():
		if g.mode=="result": g.show_camp()
		g.HeroUI.show_page(g,1,found[-1].id))
	compare.name="ReviewFoundEquipment"
	var scroll=ScrollContainer.new()
	scroll.name="FoundEquipment"
	scroll.position=Vector2(230,553); scroll.size=Vector2(980,54)
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	g.overlay.add_child(scroll)
	var row=HBoxContainer.new(); row.add_theme_constant_override("separation",10)
	scroll.add_child(row)
	for item in found:
		var card=Control.new(); card.custom_minimum_size=Vector2(230,48)
		row.add_child(card)
		Icon.add(card,item.catalog,Rect2(0,0,46,46))
		g.label(card,H.title(item),Vector2(50,1),15)
		g.label(card,"필요 Lv.%d" % H.CATALOG[item.catalog].level,Vector2(50,25),14)
		card.tooltip_text="이번 탐험에서 획득 · 저장 완료"
	return true
