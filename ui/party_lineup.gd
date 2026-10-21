extends RefCounted

static func show(g,y):
	var old=g.overlay.get_node_or_null("PartyLineup")
	if old!=null:
		g.overlay.remove_child(old)
		old.queue_free()
	var box=HBoxContainer.new()
	box.name="PartyLineup"
	box.position=Vector2(215,y)
	box.size=Vector2(1010,112)
	box.add_theme_constant_override("separation",20)
	g.overlay.add_child(box)
	add_group(g,box,"ActiveGroup","전투 출전  ·  4마리",0,4,Color("86c990"))
	add_group(g,box,"ReserveGroup","교체 대기  ·  2마리",4,2,Color("e0b86a"))

static func add_group(g,parent,group_name,caption,start,count,accent):
	var group=VBoxContainer.new()
	group.name=group_name
	group.add_theme_constant_override("separation",4)
	parent.add_child(group)
	var title=Label.new()
	title.name="GroupLabel"
	title.text=caption
	title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",accent)
	group.add_child(title)
	var row=HBoxContainer.new()
	row.name="Slots"
	row.add_theme_constant_override("separation",8)
	group.add_child(row)
	for offset in count:
		var i=start+offset
		var slot=Button.new()
		slot.name="PartySlot_"+str(i+1)
		slot.custom_minimum_size=Vector2(155,78)
		var role="출전 %d" % (i+1) if i<4 else "대기 %d" % (i-3)
		if i<g.squad.size():
			var d=g.find_owned(g.squad[i])
			slot.text="%s%s\n%s · %d성 Lv.%d" % ["✓ " if d.id==g.chosen_swap else "",role,g.NAMES[d.kind],g.Loot.star(d),d.level]
			slot.tooltip_text=("현재 전투에 참여합니다." if i<4 else "전투에는 참여하지 않으며 비전투 중 출전 칸과 교체할 수 있습니다.")+"\n눌러서 이동할 칸을 선택하세요."
			slot.pressed.connect(g.select_swap.bind(d.id))
			g.GroveUI.quiet(slot,g.Loot.color(d))
		else:
			slot.text=role+"\n빈자리"
			slot.disabled=true
			g.GroveUI.quiet(slot)
		row.add_child(slot)
