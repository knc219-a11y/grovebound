extends RefCounted
# Display-only inventory. Every operation is delegated to the existing transaction UI.
const H=preload("res://hero_progression.gd")
const UI=preload("res://ui/grove_ui.gd")
const FILTERS=["전체","무기","방어구","부적"]
const TYPES=["","weapon","armor","charm"]
const SLOT_NAMES={"weapon":"무기","armor":"방어구","charm1":"부적 1","charm2":"부적 2"}
static func items_for(profile,filter=0,order=0):
	var result=profile.items.filter(func(item): return filter==0 or H.CATALOG[item.catalog].slot==TYPES[filter])
	result.sort_custom(func(a,b):
		if order==1:
			var al=H.CATALOG[a.catalog].level
			var bl=H.CATALOG[b.catalog].level
			if al!=bl: return al>bl
		elif order==2 and a.enhance!=b.enhance: return a.enhance>b.enhance
		return a.id>b.id)
	return result
static func add_icon(parent,key,rect):
	# The atlas helper is owned by the integration/art task.
	return load("res://ui/equipment_icon.gd").add(parent,key,rect)
static func text(g,parent,value,pos,width,font_size=17):
	var label=g.label(parent,value,pos,font_size)
	label.custom_minimum_size.x=width
	label.size.x=width
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label
static func stats_line(values):
	var parts=[]
	for key in ["hp","attack","defense","support","haste"]:
		if values[key]>0: parts.append({"hp":"체력","attack":"공격","defense":"방어","support":"회복%","haste":"감소%"}[key]+" +%.1f" % (values[key]*(100 if key=="haste" else 1)))
	return " · ".join(parts)
static func delta_text(before,after):
	var parts=[]
	for key in ["hp","attack","defense","support","haste"]:
		var delta=(after[key]-before[key])*(100 if key=="haste" else 1)
		if absf(delta)>0.001: parts.append({"hp":"체력","attack":"공격","defense":"방어","support":"회복%","haste":"감소%"}[key]+" %+.1f" % delta)
	return "변화 없음" if parts.is_empty() else " · ".join(parts)
static func show(g,selected,filter,order,scroll_y,reopen,confirm):
	var entries=items_for(g.hero,filter,order)
	var item=H.find(g.hero,selected)
	if item.is_empty() or not entries.any(func(entry): return entry.id==selected):
		item={} if entries.is_empty() else entries[0]
	selected=0 if item.is_empty() else item.id
	var filters=OptionButton.new()
	filters.name="EquipmentFilter"; filters.position=Vector2(230,278); filters.size=Vector2(160,40)
	for value in FILTERS: filters.add_item(value)
	filters.select(filter); g.overlay.add_child(filters)
	filters.item_selected.connect(func(value): reopen.call(selected,value,order,0))
	var sorting=OptionButton.new()
	sorting.name="EquipmentSort"; sorting.position=Vector2(400,278); sorting.size=Vector2(175,40)
	for value in ["최신 획득순","필요 레벨순","강화순"]: sorting.add_item(value)
	sorting.select(order); g.overlay.add_child(sorting)
	sorting.item_selected.connect(func(value): reopen.call(selected,filter,value,0))
	g.label(g.overlay,"%d / %d개" % [entries.size(),g.hero.items.size()],Vector2(590,290),17)
	var scroll=ScrollContainer.new()
	scroll.name="EquipmentInventory"; scroll.position=Vector2(230,327); scroll.size=Vector2(520,286)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	g.overlay.add_child(scroll)
	var grid=GridContainer.new(); grid.columns=2
	grid.name="EquipmentGrid"; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for entry in entries:
		var card=Button.new(); card.name="Equipment_"+str(entry.id)
		card.custom_minimum_size=Vector2(246,62)
		if entry.id==selected: UI.emphasize(card)
		grid.add_child(card)
		add_icon(card,entry.catalog,Rect2(5,7,48,48))
		text(g,card,H.title(entry),Vector2(58,7),180,16)
		var worn=entry.id in g.hero.equipped.values()
		text(g,card,("장착 중 · " if worn else "")+"Lv.%d" % H.CATALOG[entry.catalog].level,Vector2(58,35),180,14)
		card.pressed.connect(func(): reopen.call(entry.id,filter,order,scroll.scroll_vertical))
		card.tooltip_text=H.title(entry)+" · "+stats_line(H.item_stats(entry))
	scroll.set_deferred("scroll_vertical",scroll_y)
	if entries.is_empty():
		text(g,g.overlay,"상점과 사냥에서 장비를 얻으세요." if g.hero.items.is_empty() else "이 종류의 장비가 없습니다.",Vector2(250,390),465,21)
	g.panel(g.overlay,Rect2(770,278,440,335),UI.INK)
	for i in 4:
		var slot=H.SLOTS[i]
		var worn=H.find(g.hero,g.hero.equipped[slot])
		var pos=Vector2(780+(i%2)*214,286+int(i/2)*46)
		var caption=SLOT_NAMES[slot]+" · "+("비어 있음" if worn.is_empty() else H.title(worn))
		var button=g.button(g.overlay,"",Rect2(pos,Vector2(204,42)),func():
			if not worn.is_empty(): reopen.call(worn.id,0,order,scroll.scroll_vertical))
		button.name="Equipped_"+slot
		button.tooltip_text=caption
		if not worn.is_empty(): add_icon(button,worn.catalog,Rect2(2,3,36,36))
		text(g,button,caption,Vector2(40,4),158,14)
	if item.is_empty(): return
	var d=H.CATALOG[item.catalog]
	add_icon(g.overlay,item.catalog,Rect2(781,384,52,52))
	text(g,g.overlay,H.title(item),Vector2(842,384),212,22)
	text(g,g.overlay,"필요 Lv.%d · %s" % [d.level,"장착 중" if selected in g.hero.equipped.values() else "보유 장비"],Vector2(842,413),212,16)
	for slot in H.SLOTS:
		if g.hero.equipped[slot]==selected:
			g.button(g.overlay,"장착 해제",Rect2(1063,389,136,42),func(): confirm.call("unequip",slot,selected,H.title(item),scroll.scroll_vertical)).disabled=g.mode!="camp"
	text(g,g.overlay,stats_line(H.item_stats(item)),Vector2(782,442),415,16)
	var slots=[d.slot] if d.slot!="charm" else ["charm1","charm2"]
	for i in slots.size():
		var slot=slots[i]
		var plan=H.plan(g.hero,"equip",{"id":selected,"slot":slot})
		var reason="캠프에서 장착 가능" if g.mode!="camp" else plan.error
		var current=H.find(g.hero,g.hero.equipped[slot])
		var caption=SLOT_NAMES[slot]+": "+("비어 있음" if current.is_empty() else H.title(current))
		var y=475+i*42
		text(g,g.overlay,caption,Vector2(782,y),275,14)
		text(g,g.overlay,delta_text(H.stats(g.hero),H.stats(plan.after)) if reason.is_empty() else reason,Vector2(782,y+18),275,14)
		var button=g.button(g.overlay,SLOT_NAMES[slot]+" 장착",Rect2(1063,y,136,38),func(): confirm.call("equip",{"id":selected,"slot":slot},selected,H.title(item),scroll.scroll_vertical))
		button.name="EquipTo_"+slot; button.add_theme_font_size_override("font_size",16)
		button.disabled=not reason.is_empty(); button.tooltip_text=reason
	var enhance=H.plan(g.hero,"enhance",selected)
	var sell=H.plan(g.hero,"sell",selected)
	var enhance_button=g.button(g.overlay,"강화 %d G" % enhance.cost if enhance.error.is_empty() else enhance.error,Rect2(782,565,202,42),func(): confirm.call("enhance",selected,selected,H.title(item),scroll.scroll_vertical))
	enhance_button.name="EnhanceEquipment"; enhance_button.add_theme_font_size_override("font_size",16)
	enhance_button.disabled=g.mode!="camp" or not enhance.error.is_empty()
	enhance_button.tooltip_text="캠프에서 강화 가능" if g.mode!="camp" else enhance.error
	var sell_button=g.button(g.overlay,"판매 %d G" % int(d.price/4),Rect2(995,565,204,42),func(): confirm.call("sell",selected,selected,H.title(item),scroll.scroll_vertical))
	sell_button.name="SellEquipment"; sell_button.add_theme_font_size_override("font_size",16)
	sell_button.disabled=g.mode!="camp" or not sell.error.is_empty()
	sell_button.tooltip_text="캠프에서 판매 가능" if g.mode!="camp" else sell.error
