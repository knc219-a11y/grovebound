extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.expedition.clear()
	g.show_camp()
	g.owned.clear()
	g.squad.clear()
	g.discovered.clear()
	var ids=[]
	for kind in ["boar","fox","deer","wolf","turtle"]: ids.append(g.make_owned(kind,2).id)
	g.squad=[ids[0]]
	g.find_owned(ids[1]).favorite=true
	g.materials=7
	var survivors=g.owned.slice(0,2).duplicate(true)
	g.show_bulk_release(true)
	g.toggle_bulk_release(ids[0],true)
	g.toggle_bulk_release(ids[1],true)
	if not g.bulk_selection.is_empty(): push_error("protected companions selectable"); quit(1); return
	g.toggle_bulk_release(ids[2],true)
	g.toggle_bulk_release(ids[3],true)
	g.confirm_bulk_release()
	var failures=[]
	if g.owned.size()!=5 or g.materials!=7: failures.append("preview must not delete or grant")
	g.find_owned(ids[3]).favorite=true
	if g.commit_bulk_release([ids[2],ids[3]]) or g.owned.size()!=5 or g.materials!=7: failures.append("atomic revalidation of changed protection")
	g.find_owned(ids[3]).favorite=false
	var expected=7+g.Management.farewell_reward(g.find_owned(ids[2]))+g.Management.farewell_reward(g.find_owned(ids[3]))
	if not g.commit_bulk_release([ids[2],ids[2],ids[3]]) or g.materials!=expected or g.owned.size()!=3: failures.append("batch dedup and exact rewards")
	if g.commit_bulk_release([ids[2],ids[3]]) or g.materials!=expected: failures.append("duplicate submit grants again")
	if g.owned.slice(0,2)!=survivors or not g.discovered.has("deer"): failures.append("survivors/order/discovery preserved")
	g.open_roster()
	var filter=g.overlay.get_node("SpeciesFilter")
	if filter.get_theme_font("font")!=g.heading_font or filter.get_popup().get_theme_font("font")!=g.heading_font: failures.append("filter and popup pixel font")
	g.start_stage(false)
	if g.enemies.size()!=28: failures.append("original encounters plus sixteen weak followers")
	var census={}
	var bosses=0
	for e in g.enemies:
		if e.boss: bosses+=1
		elif not e.get("swarm",false): census[e.kind]=census.get(e.kind,0)+1
	if bosses!=1 or census.get("wolf")!=6 or census.get("deer")!=1: failures.append("same species/boss budget")
	if g.trail.core_progress(g.enemies)!={"cleared":0,"total":4}: failures.append("core route starts uncleared")
	for pack in g.Trail.CORE_PACKS:
		var members=0
		for e in g.enemies:
			if int(e.get("pack",-1))==pack:
				members+=1
				e.hp=0
		if members==0: failures.append("missing core pack metadata")
	if g.trail.core_progress(g.enemies)!={"cleared":4,"total":4}: failures.append("core progress independent of optional paths")
	var boss={}
	for e in g.enemies:
		if e.boss: boss=e
	g.player.pos=Vector2(2360,800)
	var hp_before=g.player.hp
	g.trail.update(g)
	if not boss.active or boss.get("intro",0.0)<=1.0 or not g.trail.visited.has("boss_intro"): failures.append("boss entry intro")
	g.update_game(0.2)
	if g.player.hp!=hp_before or boss.get("intro",0.0)>=1.35: failures.append("boss intro safety and countdown")
	g.player.pos=g.Trail.REST
	g.in_combat=false
	g.captures.clear()
	var before=g.materials
	var hp=g.player.hp
	g.interact()
	if g.menu_page!="trail_rest" or g.mode!="stage": failures.append("PC/touch rest route")
	g.resume_game()
	if g.player.pos!=g.Trail.REST or g.materials!=before or g.player.hp!=hp: failures.append("rest no extra reward/healing/teleport")
	g.in_combat=true
	g.interact()
	if g.overlay.visible: failures.append("rest blocked during combat")
	if g.commit_bulk_release([ids[4]]): failures.append("batch camp only")
	g.in_combat=false
	g.player.pos=Vector2(2300,800)
	g.trail.update(g)
	if not g.trail.visited.has("boss"): failures.append("boss advance warning")
	g.tutorial_species="boar"
	g.start_stage(true)
	if g.enemies.size()!=1 or not g.enemies[0].guaranteed or not g.trail.visited.is_empty(): failures.append("tutorial remains isolated")
	if failures.is_empty(): print("PASS bulk/font/trail: protected/atomic/dedup/camp-only, exact reward and discovery, popup font, encounter budget/core progress, boss intro safety, rest isolation, warning, tutorial")
	else: push_error(str(failures))
	g.queue_free()
	quit(0 if failures.is_empty() else 1)
