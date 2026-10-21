extends SceneTree
const Fixture=preload("res://animation/equipment_map_review.gd")
const H=preload("res://hero_progression.gd")
const Inventory=preload("res://ui/equipment_inventory.gd")
const Icons=preload("res://ui/equipment_icon.gd")
const Loot=preload("res://ui/equipment_loot.gd")
var failures=[]
var checks=0
func _initialize(): call_deferred("run")
func check(value,caption):
	checks+=1
	if not value: failures.append(caption)
func text(node):
	var result=""
	if node is Label or node is Button: result+=node.text+"\n"
	for child in node.get_children(): result+=text(child)
	return result
func settle():
	await process_frame
	await process_frame
func bounds(node,in_scroll=false):
	var clipped=in_scroll or node is ScrollContainer
	if node is TextureRect and str(node.name).begins_with("EquipmentIcon_"):
		check(node.size.x<=52 and node.size.y<=52,"equipment icon keeps requested UI size "+str(node.name))
		check(node.mouse_filter==Control.MOUSE_FILTER_IGNORE,"equipment icon does not intercept input")
	if (node is Label or node is Button) and not clipped:
		check(Rect2(0,0,1440,810).encloses(node.get_global_rect()),"viewport "+str(node.name)+" "+str(node.get_global_rect()))
	for child in node.get_children(): bounds(child,clipped)
func run():
	var g=Fixture.new(); root.add_child(g); await settle()
	for key in H.CATALOG:
		var texture=Icons.texture(key)
		check(texture is AtlasTexture,"icon atlas "+key)
		if texture is AtlasTexture:
			var index=Icons.KEYS.find(key)
			check(texture.region.get_center().x>=index%3*512 and texture.region.get_center().x<(index%3+1)*512,"icon column "+key)
			check(Rect2(0,0,1536,1024).encloses(texture.region) and texture.region.size.x>300 and texture.region.size.y>300,"icon full silhouette bounds "+key)
		var icon=Icons.add(g.overlay,key,Rect2(20,20,48,48))
		check(icon.size==Vector2(48,48),"atlas pixels never enlarge requested icon "+key)
		icon.queue_free()
	check(Icons.texture("unknown")==null,"invalid icon does not alias another item")
	Fixture.prepare(g,"shop"); Fixture.present(g,"shop"); await settle()
	bounds(g.overlay)
	for state in ["empty","one","inventory"]:
		Fixture.prepare(g,state)
		var before=g.save_payload().duplicate(true)
		Fixture.present(g,state); await settle()
		bounds(g.overlay)
		var scroll=g.overlay.find_child("EquipmentInventory",true,false)
		check(scroll is ScrollContainer and scroll.size.y>=270,"expanded inventory "+state)
		var grid=g.overlay.find_child("EquipmentGrid",true,false)
		check(grid.get_child_count()==g.hero.items.size(),"each ID has one card "+state)
		for slot in H.SLOTS: check(g.overlay.find_child("Equipped_"+slot,true,false)!=null,"equipped slot "+slot)
		check(g.save_payload()==before,"opening UI preserves all progress "+state)
		if state=="inventory":
			check(grid.get_child_count()==36 and grid.columns==2,"36 items two columns")
			check(scroll.size.y/(grid.get_child(0).size.y+8)>=4,"four visible rows / eight cards")
			scroll.scroll_vertical=99999; await settle()
			check(scroll.scroll_vertical>0,"last item reachable by scroll")
			check(grid.get_child(35).get_global_rect().end.y<=scroll.get_global_rect().end.y+1,"last card visible at end")
			for filter in 4:
				for order in 3:
					var entries=Inventory.items_for(g.hero,filter,order)
					check(entries.size()==(36 if filter==0 else 12),"filter counts %d/%d" % [filter,order])
					for item in entries: check(filter==0 or H.CATALOG[item.catalog].slot==Inventory.TYPES[filter],"filter category")
					for i in range(1,entries.size()):
						var a=entries[i-1]; var b=entries[i]
						check(a.id>b.id if order==0 else H.CATALOG[a.catalog].level>=H.CATALOG[b.catalog].level if order==1 else a.enhance>=b.enhance,"sort %d" % order)
				check(g.save_payload()==before,"filter/sort does not mutate payload or RNG")
	Fixture.prepare(g,"inventory")
	# Compare known unenhanced wind charm against each differently equipped charm.
	var chosen=H.add_item(g.hero,"wind_charm")
	g.hero.items[6].enhance=0; g.hero.items[7].enhance=0
	g.HeroUI.show_page(g,1,chosen.id); await settle()
	var words=text(g.overlay)
	check("부적 1:" in words and "부적 2:" in words,"both charm comparison targets named")
	check("감소% +7.0" in words and "체력 -20.0" in words,"charm1 actual replacement difference")
	check("감소% +3.0" in words and "회복% -3.0" in words,"charm2 actual replacement difference")
	check(not g.overlay.find_child("EquipTo_charm1",true,false).disabled and not g.overlay.find_child("EquipTo_charm2",true,false).disabled,"both charm destinations usable")
	var snapshot=g.hero.duplicate(true)
	g.save_blocked=true
	g.HeroUI.confirm(g,"equip",{"id":chosen.id,"slot":"charm1"},1,chosen.id,H.title(chosen))
	await settle()
	for child in g.overlay.get_children():
		if child is Button and child.text=="확인": child.pressed.emit(); break
	await settle()
	check(g.hero==snapshot and "소모되지 않았습니다" in text(g.overlay),"failed equipment transaction leaves inventory/gold unchanged")
	g.save_blocked=false; g.hero.level=1
	g.HeroUI.show_page(g,1,chosen.id); await settle()
	check(g.overlay.find_child("EquipTo_charm1",true,false).disabled and "레벨" in text(g.overlay),"level requirement disabled and explained")
	g.hero.level=18; g.mode="stage"
	g.HeroUI.show_page(g,1,chosen.id); await settle()
	check(g.overlay.find_child("EquipTo_charm1",true,false).disabled and g.overlay.find_child("EnhanceEquipment",true,false).disabled and g.overlay.find_child("SellEquipment",true,false).disabled,"field actions disabled")
	g.mode="camp"; g.hero.gold=0
	g.HeroUI.show_page(g,1,chosen.id); await settle()
	check(g.overlay.find_child("EnhanceEquipment",true,false).disabled,"insufficient gold cannot enhance")
	g.hero.gold=10000; chosen.enhance=5
	g.HeroUI.show_page(g,1,chosen.id); await settle()
	check(g.overlay.find_child("EnhanceEquipment",true,false).disabled,"max enhancement respected")
	g.HeroUI.show_page(g,1,2); await settle()
	check(g.overlay.find_child("SellEquipment",true,false).disabled,"equipped item protected from sale")
	for state in ["no_drop","loot","pending"]:
		Fixture.prepare(g,state); Fixture.present(g,state); await settle()
		bounds(g.overlay)
		check(Loot.items(g).size()==(2 if state=="loot" else 0),"confirmed acquisitions only "+state)
		check((g.overlay.find_child("FoundEquipment",true,false)!=null)==(state=="loot"),"loot display presence "+state)
		if state=="pending":
			var candidate=g.hero_pending.duplicate(true)
			var original=g.hero.duplicate(true)
			check(not g.save_game() and g.hero==original and g.hero_pending==candidate,"failed reward save preserves pending candidate/RNG")
			check("저장 대기" in text(g.overlay),"pending reward clearly identified")
			g.save_blocked=false
			check(g.save_game(),"same pending candidate retry succeeds")
			check(g.hero==candidate and g.hero_pending.is_empty(),"retry publishes original reward without reroll")
			g.show_run_report(); await settle()
			check(Loot.items(g).size()==2 and not "저장 대기" in text(g.overlay),"retry updates report once")
			g.show_run_report(); await settle()
			check(Loot.items(g).size()==2,"reopening report does not duplicate awards")
			var summary=g.expedition.report.hero_growth
			H.add_item(g.hero,"twig_staff")
			g.show_run_report(); await settle()
			check(Loot.items(g).size()==2,"later purchase is not a new expedition drop")
			check(g.expedition.report.hero_growth==summary,"later purchase does not alter expedition reward summary")
	Fixture.prepare(g,"inventory")
	for theme in 6:
		g.map_theme=theme; g.map_stage=8; g.map_difficulty="normal"
		var before=g.save_payload().duplicate(true)
		g.open_stage_select(); await settle()
		var map=g.overlay.find_child("ExplorationMap",true,false)
		check(map.mouse_filter==Control.MOUSE_FILTER_IGNORE,"map decoration ignores input")
		check(map.points.size()==(5 if theme==0 else 8),"all map nodes "+str(theme))
		if theme>0:
			check(g.overlay.find_child("Stage_4",true,false).tooltip_text=="중간보스" and g.overlay.find_child("Stage_8",true,false).tooltip_text=="테마 보스","boss identity retained")
			check("교감 15%" in text(g.overlay),"capture/reward information retained")
		if theme in [2,3]: check(g.overlay.find_child("DepartLegacy",true,false)!=null,"legacy exploration retained")
		check(g.save_payload()==before,"map display preserves progression "+str(theme))
		bounds(g.overlay)
	g.campaign_progress={"version":1,"cleared":[]}; g.cleared_stages=[]
	g.map_theme=5; g.map_stage=8; g.open_stage_select(); await settle()
	check(g.overlay.find_child("DepartRoute",true,false).disabled,"unearned stage remains locked")
	var locked=g.overlay.find_child("ExplorationMap",true,false)
	check(locked.locked.size()==8,"locked graphics follows actual availability")
	g.map_difficulty="depth"; g.map_theme=1; g.map_stage=1; g.open_stage_select(); await settle()
	check(g.overlay.find_child("DepartRoute",true,false)==null and "준비 중" in text(g.overlay),"unimplemented depth cannot depart")
	g.queue_free(); await process_frame
	if failures.is_empty(): print("EQUIPMENT MAP PASS ",checks," checks"); quit(0)
	else:
		for failure in failures: push_error("EQUIPMENT MAP FAIL "+failure)
		quit(1)
