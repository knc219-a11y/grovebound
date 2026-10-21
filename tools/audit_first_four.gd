extends "res://tools/audit_valley_routes.gd"
func run():
	var history=JSON.parse_string(FileAccess.get_file_as_string("res://docs/normal-preparation-journeys.json"))
	var state=history.final_states[0]
	var g=Game.new(); root.add_child(g); g.set_process(false)
	g.rng.seed=10417; g.loot_rng.seed=10417
	g.show_camp(); g.clear_overlay()
	var fixed=g.SaveData.normalize(state,g.STATS.keys())
	g.owned=fixed.owned; g.squad=fixed.squad; g.next_id=fixed.next_id; g.materials=int(state.materials)
	g.discovered=fixed.discovered; g.cleared_stages=[1,2,3]; g.unlocked=true; g.campaign_progress=R.normalize(state)
	g.hero=state.get("hero",g.Hero.fresh()).duplicate(true); g.sync_hero()
	var initial=g.save_payload().duplicate(true); var repeats=[]; var actions=[]
	var ids=[g.squad[0],g.squad[4],g.squad[5]]
	while not ids.all(func(id): return g.Loot.star(g.find_owned(id))==3 and g.find_owned(id).level==40) and repeats.size()<240:
		g.show_camp(); g.clear_overlay()
		# Upgrade reserves freely; protect the main carry from a Lv1 power drop.
		for id in g.squad:
			var d=g.find_owned(id)
			if g.Loot.star(d)>=3 or not g.Loot.is_max_level(d): continue
			var promoted=g.Management.promotion_preview(d)
			var target=20 if promoted.star==3 else 15
			var cost=g.Management.target_plan(promoted,target).cost
			if id==ids[0] and g.materials<cost: continue
			assert(g.promote_companion(id,d.duplicate(true)))
			if id==ids[0]: assert(g.train_to_level(id,target,d.duplicate(true)))
			actions.append({"replay":repeats.size(),"id":id,"star":d.star,"level":d.level,"materials":g.materials})
		g.clear_overlay(); assert(g.depart_route(R.coordinate(4,1)))
		var farm=play_route(g,4,1,"boar",10417)
		assert(farm.success,"Previous-stage farming failed")
		repeats.append({"number":repeats.size()+1,"seconds":farm.seconds,"materials":g.materials,"party":g.owned.filter(func(d): return g.squad.has(d.id)).map(func(d): return {"id":d.id,"star":d.star,"level":d.level,"xp":d.xp})})
		if repeats.size()%10==0: print("FIRST FOUR FARM ",repeats.size())
	assert(ids.all(func(id): return g.Loot.star(g.find_owned(id))==3 and g.find_owned(id).level==40))
	g.show_camp(); g.clear_overlay()
	# Supports must leave preparation before the normal synthesis transaction accepts them.
	g.squad.erase(ids[1]); g.squad.erase(ids[2])
	var plan=g.Synthesis.preview(g.owned,g.squad,ids,ids[0],"species")
	assert(plan.error.is_empty() and g.commit_synthesis(ids,ids[0],"species",plan.materials))
	var d=g.find_owned(ids[0]); assert(g.commit_special_choice(d.id,"earth","guard",d.duplicate(true)))
	d=g.find_owned(ids[0])
	assert(g.train_to_level(d.id,15,d.duplicate(true))); g.clear_overlay()
	# Spend only naturally earned gold through the actual camp transactions.
	var purchases=[]
	for pair in [["grove_staff" if g.hero.level>=18 else "oak_staff","weapon"],["guardian_robe" if g.hero.level>=18 else "bark_robe","armor"],["vitality_charm","charm1"],["stream_charm","charm2"]]:
		var offer=g.Hero.CATALOG[pair[0]]
		if g.hero.level<offer.level or g.hero.gold<offer.price: continue
		assert(g.commit_hero_action("buy",pair[0],g.hero.duplicate(true)))
		var item=g.hero.items[-1]
		assert(g.commit_hero_action("equip",{"id":item.id,"slot":pair[1]},g.hero.duplicate(true)))
		purchases.append(pair[0])
	for key in g.Hero.SKILLS:
		for step in 5:
			var upgrade=g.Hero.plan(g.hero,"skill",key)
			if not upgrade.error.is_empty(): break
			assert(g.commit_hero_action("skill",key,g.hero.duplicate(true)))
	g.clear_overlay()
	var prepared=g.save_payload().duplicate(true)
	assert(g.depart_route(R.coordinate(5,7)))
	var approach=play_route(g,5,7,"boar",10417); assert(approach.success)
	g.show_camp(); g.clear_overlay()
	assert(g.depart_route(R.coordinate(5,8)))
	var final=play_route(g,5,8,"boar",10417)
	var out={"method":"Continues the real first-invitation boar/10417 path after 5-6; repeats actual 4-1 fights, spends only earned materials, promotes six travelers at cap, synthesizes three real 3-star40 records, selects earth/guard and trains 4-star15 before the final. No XP/material/companion injection.","hero_purchases":purchases,"initial":initial,"repeats":repeats,"promotions":actions,"prepared":prepared,"approach":approach,"final":final}
	var f=FileAccess.open("res://docs/first-four-journey.json",FileAccess.WRITE); f.store_string(JSON.stringify(out,"\t")+"\n"); f.close()
	var passed=final.success and repeats.size()>=15 and repeats.size()<=20
	print("FIRST FOUR ","PASS" if passed else "FAIL",": replays=",repeats.size(),", final=",final.success)
	g.free(); quit(0 if passed else 1)
