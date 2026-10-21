extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Campaign=preload("res://campaign.gd")
const Species=preload("res://creature_species.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new(); root.add_child(g); g.set_process(false)
	for stage in [1,2,3]:
		g.start_stage(false,stage)
		assert(g.enemies.size()==(28 if stage==1 else 30))
		var families={"beast":0,"monster":0,"undead":0}
		var rewards=0
		var mains={}
		for e in g.enemies:
			if not e.get("swarm",false):
				rewards+=1
				if not e.boss: families[Species.family(e.kind)]+=1
			if e.get("pack",-1) in g.Trail.CORE_PACKS and not e.get("swarm",false): mains[e.kind]=true
			if stage==1 and not e.boss:
				assert(e.damage_scale==(0.5 if e.get("swarm",false) else 0.8))
			else: assert(not e.has("damage_scale"))
		assert(rewards==12)
		var dominant=["beast","monster","undead"][stage-1]
		for family in families: assert(families[family]==(7 if family==dominant else 2))
		assert("boar" in mains if stage==1 else "bat" in mains)
		if stage==1: assert("slime" in mains and "skeleton" in mains)
		if stage==3:
			var back=g.enemies.filter(func(e): return e.get("pack",-1)==5 and e.kind=="wraith")
			assert(back.size()==1 and back[0].home.x>g.Trail.PACKS[5].x)
		for player_class in ["druid","contractor","necromancer"]:
			assert(not Campaign.tamable_kinds(stage,player_class).is_empty())
		g.trail.unlock_paths(g.Trail.NORTH); g.trail.unlock_paths(g.Trail.SOUTH)
		g.trail.begin_boss_intro(g)
		g.captures.clear()
		var material_before=g.materials
		for e in g.enemies:
			e.guaranteed=true
			g.hit_enemy(e,99999,g.player.pos,g.player)
		assert(g.materials==material_before+16)
		assert(g.captures.size()==families.beast)
		for candidate in g.captures: assert(Species.family(candidate.kind)=="beast")
	assert(Campaign.tamable_kinds(1,"druid").size()==6)
	assert(Campaign.tamable_kinds(1,"contractor")==["slime"])
	assert(Campaign.tamable_kinds(1,"necromancer")==["skeleton"])
	assert(Species.condition("slime","contractor")=="현재 계열로 인연 가능")
	assert(Species.condition("boar","contractor")=="야수 계열의 인연이 필요")
	assert(Campaign.habitats("slime").size()==3)
	assert(not Species.can_tame("unknown","unknown"))
	assert(g.CAPTURE_CHANCE==0.15)
	assert(Species.starters("druid")==["boar","marten","fox"])
	assert(Species.starters("contractor")==["slime"] and Species.starters("necromancer")==["skeleton"])
	# A boss that charges beyond its leash must keep walking home after deactivation.
	g.start_stage(false)
	g.player.pos=Vector2(2400,850); g.trail.begin_boss_intro(g)
	var boss=g.enemies[-1]
	boss.pos=Vector2(1680,850); boss.active=true; boss.intro=0
	for e in g.enemies:
		if not e.boss: e.hp=0
	g.units.clear()
	g.update_game(0.05)
	var after_first=boss.pos.x
	assert(not boss.active)
	g.update_game(0.05)
	assert(boss.pos.x>after_first)
	# Existing starter flow still gives exactly one chosen companion before practice.
	for kind in ["boar","marten","fox"]:
		g.owned.clear(); g.squad.clear(); g.tutorial_done=false
		g.tutorial_species=kind; g.start_stage(true)
		assert(g.enemies.size()==1 and g.enemies[0].guaranteed and not g.enemies[0].has("damage_scale"))
		g.hit_enemy(g.enemies[0],99999,g.player.pos,g.player)
		g.player.pos=g.captures[0].pos; g.in_combat=false; g.interact()
		assert(g.owned.size()==1 and g.owned[0].kind==kind and g.tutorial_done)
		g.start_practice()
		assert(g.tutorial_species=="practice")
	# The actual selector and collection use the same current-class policy.
	g.expedition.clear(); g.show_camp(); g.open_stage_select()
	assert(g.overlay.get_children().any(func(n): return n is Label and n.text.contains("교감 가능 6종")))
	g.seen_species=Species.kinds(); g.open_collection()
	var cards=g.overlay.get_node("CreatureCollection").get_child(0)
	assert(cards.get_child_count()==16)
	print("MIXED STAGES PASS: 7/2/2 reward families, 28/30/30 totals, main-path bonds, rear wraith, unchanged reward/15% policy, class-aware conditions, original guaranteed starters, production selector/collection")
	g.free(); quit()
