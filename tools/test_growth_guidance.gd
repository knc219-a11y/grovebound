extends SceneTree
const Fixture=preload("res://animation/growth_guidance_review.gd")
const Guidance=preload("res://ui/growth_guidance.gd")
var failures=[]
var checks=0
func _init(): call_deferred("run")
func check(value,caption):
	checks+=1
	if not value: failures.append(caption)
func text(node):
	var result=""
	if node is Label or node is Button: result+=node.text+"\n"
	for child in node.get_children(): result+=text(child)
	return result
func bounds(node):
	if node is Label or node is Button:
		var rect=node.get_global_rect()
		# Scroll contents may intentionally extend outside the clipped viewport.
		var parent=node.get_parent()
		var clipped=false
		while parent!=null:
			if parent is ScrollContainer: clipped=true
			parent=parent.get_parent()
		if not clipped: check(Rect2(-1,-1,1442,812).encloses(rect),"viewport contains "+node.name+": "+str(rect))
	for child in node.get_children(): bounds(child)
func settle():
	await process_frame
	await process_frame
func direct_overlap(node):
	var content=[]
	for child in node.get_children():
		if (child is Label or child is Button) and child.position.y>=200: content.append(child)
	for i in content.size():
		for j in range(i+1,content.size()):
			var a=content[i]; var b=content[j]
			var intersection=a.get_global_rect().intersection(b.get_global_rect())
			check(not intersection.has_area() or intersection.size.x*intersection.size.y<2,"no text/button overlap: "+str(a.name)+" / "+str(b.name))
func run():
	var g=Fixture.new()
	root.add_child(g)
	g.set_process(false)
	Fixture.populate(g,"synthesis")
	var original=g.save_payload().duplicate(true)
	var random_state=g.rng.state
	var loot_state=g.loot_rng.state
	var plan=Guidance.synthesis_plan(g.owned,g.squad)
	check(not plan.is_empty(),"three ready records allow synthesis")
	check(plan.leaving_squad.size()==2,"squad supports are actually allowed")
	g.owned[0].favorite=true
	check(not Guidance.synthesis_plan(g.owned,g.squad).is_empty(),"one favorite can be main")
	g.owned[1].favorite=true
	check(Guidance.synthesis_plan(g.owned,g.squad).is_empty(),"two favorites cannot supply two supports")
	g.owned[0].favorite=false; g.owned[1].favorite=false
	check(Guidance.synthesis_plan(g.owned.slice(0,2),g.squad).is_empty(),"two records are insufficient")
	check(Guidance.synthesis_plan([g.owned[0],g.owned[0],g.owned[1]],g.squad).is_empty(),"duplicate IDs never yield ready")
	for count in [0,8,24,25,39,40]:
		Fixture.progress(g,count)
		var model=Guidance.model(g)
		check(not model.route.is_empty(),"route provided count "+str(count))
		check(g.Routes.available(model.route,g.campaign_progress),"recommended route available count "+str(count))
		check(g.Routes.implemented(model.route),"recommended route implemented count "+str(count))
		if count==24: check(not model.route_text.contains("재탐험"),"uncleared4-1 is not multiplied replay")
		if count>=25: check(g.Routes.growth_replay(Guidance.recommended(g.campaign_progress),g.campaign_progress),"late replay only completed route")
		if count==40: check(model.completed and model.goal.contains("완료") and model.detail.contains("준비 중"),"completed priority and depth preparation")
	Fixture.populate(g,"goal")
	check(Guidance.model(g).active==1,"completed four-star active")
	g.squad.erase(g.owned[0].id)
	check(Guidance.model(g).active==0,"stored four-star is not active")
	g.squad=[g.owned[1].id,g.owned[2].id,-1,-2,g.owned[0].id]
	check(Guidance.model(g).active==0,"reserve four-star is not active")
	g.owned[0].special.state="pending"
	check(Guidance.model(g).active==0 and Guidance.model(g).detail.contains("선택 대기"),"pending owned choice guidance matches departure block")
	for state in ["goal","materials","synthesis","completed","boss"]:
		Fixture.populate(g,state)
		var before=g.save_payload().duplicate(true)
		var rng_before=g.rng.state; var loot_before=g.loot_rng.state
		Fixture.show_screen(g,state)
		await settle()
		bounds(g.overlay)
		direct_overlap(g.overlay)
		check(g.Special.equivalent(before,g.save_payload()),state+" screen never mutates save payload")
		check(g.rng.state==rng_before and g.loot_rng.state==loot_before,state+" screen never rolls RNG")
		var shown=text(g.overlay)
		if state=="materials":
			var d=g.owned[0]
			var cost=g.Management.target_plan(d,40).cost
			check(shown.contains("부족 재료 %d" % cost),"zero materials shows exact target deficit")
			for amount in [cost-1,cost]:
				g.materials=amount; g.preview_target_training(d.id,40)
				await settle()
				check(text(g.overlay).contains("부족 재료 %d" % maxi(0,cost-amount)),"target deficit boundary "+str(amount))
		if state=="completed": check(shown.contains("일반 40개 완료"),"completed shown in actual UI")
		if state=="boss": check(shown.contains("갑주") and shown.contains("6초"),"boss core response visible")
		g.open_game_menu()
		await settle()
		bounds(g.overlay)
		direct_overlap(g.overlay)
		check(text(g.overlay).contains(Guidance.model(g).goal),state+" menu contains goal")
	Fixture.populate(g,"synthesis")
	check(Guidance.level_status(g.owned[0]).contains("합성 후보"),"three-star cap is candidate only")
	g.owned[0].star=2; g.owned[0].level=30
	check(Guidance.level_status(g.owned[0]).contains("승급"),"actual promotion cap")
	Fixture.populate(g,"goal")
	g.owned[0].level=g.Loot.max_level(g.owned[0])
	check(not Guidance.level_status(g.owned[0]).contains("합성"),"four-star cap no synthesis material claim")
	check(g.rng.state==random_state,"read-only helper preserves gameplay random state")
	for state in ["closed","open"]:
		Fixture.populate(g,state)
		Fixture.show_screen(g,state)
		await settle()
		check(g.boss_panel.visible,"boss HUD visible "+state)
		check(g.boss_panel.get_global_rect().encloses(g.boss_label.get_global_rect()),"boss panel encloses all HUD text "+state)
		check(g.boss_label.text.contains("가까이서") if state=="closed" else g.boss_label.text.contains("6.0초"),"boss HUD armor response "+state)
		check(not g.toast_label.text.is_empty(),"production departure story toast visible "+state)
		check(not g.boss_panel.get_global_rect().intersects(g.toast_label.get_global_rect()),"departure story does not overlap armor HUD "+state)
		check(g.toast_label.position.y==g.boss_panel.position.y+g.boss_panel.size.y+12,"story moves below visible boss panel "+state)
		for e in g.enemies: e.hp=0
		g.update_hud()
		check(g.toast_label.position.y==210,"nonboss HUD restores toast position "+state)
		g.mode="camp"
		g.update_hud()
		check(g.toast_label.position.y==210,"camp HUD restores toast position "+state)
	g.queue_free()
	await process_frame
	if failures.is_empty(): print("GROWTH GUIDANCE PASS: ",checks," independent policy, state preservation and viewport checks")
	else: push_error("GROWTH GUIDANCE FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
