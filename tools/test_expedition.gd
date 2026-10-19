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
	g.materials=8
	var d=g.make_owned("boar",1)
	g.squad=[d.id]
	g.tutorial_done=true
	g.start_stage(false)
	d=g.find_owned(d.id)
	var initial=g.owned.duplicate(true)
	g.gain_xp(d,100)
	g.materials+=3
	var newcomer=g.make_owned("fox",2)
	g.expedition.record_bond(newcomer)
	g.gain_xp(newcomer,22)
	g.stage_time=75
	g.kills=3
	g.show_camp()
	var failures=[]
	var r=g.expedition.report
	if r.materials!=3 or r.newcomers.size()!=1 or r.growth.size()!=2: failures.append("net gains and newly bonded XP")
	if r.growth[0].xp!=100 or r.growth[0].from!=1 or r.growth[0].to!=2: failures.append("XP across level boundary")
	if r.seconds!=75 or g.menu_page!="recap": failures.append("retreat recap")
	if g.expedition.baseline.owned!=initial: failures.append("baseline must be independent copy")
	var p=g.player.pos
	g.resume_game()
	if g.overlay.visible or g.player.pos!=p: failures.append("dismiss resumes same town position")
	var previous=r.duplicate(true)
	g.show_camp()
	if g.overlay.visible or g.expedition.report!=previous: failures.append("camp revisit must not duplicate recap")
	g.start_stage(false)
	g.finish(true)
	var reward=g.materials
	if g.expedition.report.materials!=10 or g.menu_page!="recap": failures.append("clear bonus counted once")
	g.finish(true)
	g.show_camp()
	if g.materials!=reward: failures.append("repeated result cannot grant bonus twice")
	g.start_stage(false)
	g.finish(false)
	if g.expedition.report.materials!=0 or g.expedition.report.newcomers.size()!=0: failures.append("defeat no extra rewards or stale bonds")
	g.show_camp()
	g.expedition.clear()
	g.tutorial_done=false
	g.update_hud()
	if not "첫 걸음" in g.quest_label.text: failures.append("first town contextual guide")
	g.tutorial_species="boar"
	g.start_stage(true)
	g.hit_enemy(g.enemies[0],10000,g.player.pos)
	g.player.pos=g.captures[0].pos
	g.interact()
	g.start_practice()
	var foe=g.enemies[-1]
	g.hit_enemy(foe,10000,g.player.pos)
	g.update_hud()
	if g.mode!="camp" or g.menu_page!="recap" or g.expedition.report.newcomers.size()!=1: failures.append("tutorial/practice share one expedition")
	if failures.is_empty(): print("PASS expedition: independent snapshots, XP, new bonds, retreat/clear/defeat, idempotent rewards, tutorial, same-position dismissal")
	else: push_error(str(failures))
	g.queue_free()
	quit(0 if failures.is_empty() else 1)
