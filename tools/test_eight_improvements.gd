extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Manager=preload("res://companion_management.gd")
const Source=preload("res://animation/quadruped_source.gd")
const Weapon=preload("res://animation/weapon_visual.gd")
func record(level,grade):
	return {"id":90+level,"kind":"wolf","level":level,"xp":0,"trait":"민첩함","grade":grade,"options":[],"favorite":false}
func _initialize(): call_deferred("check")
func check():
	var failures=[]
	if Manager.farewell_reward(record(1,"common"))!=2 or Manager.farewell_reward(record(1,"rare"))!=5 or Manager.farewell_reward(record(1,"epic"))!=10: failures.append("grade farewell bases")
	if Manager.farewell_reward(record(8,"common"))<=Manager.farewell_reward(record(7,"common")): failures.append("level farewell growth")
	var growing=record(3,"rare")
	growing.xp=41
	var plan=Manager.target_plan(growing,8)
	if plan.is_empty() or plan.after.level!=8 or plan.after.xp<0 or plan.cost!=plan.charges*3: failures.append("target plan")
	if Manager.project(growing,plan.xp)!=plan.after: failures.append("target plan equals repeated XP")
	if not Manager.target_plan(growing,3).is_empty() or not Manager.target_plan(growing,1004).is_empty(): failures.append("target bounds")
	var deer=Source.new()
	deer.configure("deer",false)
	if deer.config.roots[2].x>=40 or deer.config.feet[2].x>=40: failures.append("deer front leg mapped outside sprite")
	var phases=deer.beats()
	var moved=[]
	for i in 4: moved.append(deer.foot_offset(0.12,phases[i]))
	if moved[0]==moved[1] or moved[2]==moved[3]: failures.append("deer four-leg phase")
	deer.free()
	var turtle=Source.new()
	turtle.configure("turtle",false)
	if turtle.duty()<0.7 or turtle.stride()<8.0: failures.append("turtle planted gait")
	turtle.free()
	var original=Image.load_from_file("res://assets/party-pixel/druid.png")
	var body=Image.load_from_file("res://assets/party-pixel/druid-body-v2.png")
	var staff=Image.load_from_file("res://assets/party-pixel/druid-staff-v2.png")
	for y in original.get_height():
		for x in original.get_width():
			var o=original.get_pixel(x,y)
			var a=body.get_pixel(x,y)
			var b=staff.get_pixel(x,y)
			if a.a>0 and b.a>0: failures.append("weapon layer overlap"); break
			var rebuilt=a if a.a>0 else b
			if not is_equal_approx(rebuilt.a,o.a) or (o.a>0 and not rebuilt.is_equal_approx(o)): failures.append("weapon reconstruction"); break
		if failures.has("weapon layer overlap") or failures.has("weapon reconstruction"): break
	var weapon=Weapon.new()
	if weapon.set_visual("missing") or weapon.texture()==null: failures.append("future weapon visual API")
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.owned.clear(); g.squad.clear(); g.materials=9999; g.mode="camp"
	var d=g.make_owned("wolf",3,growing)
	d.id=901; g.next_id=902
	var before=d.duplicate(true)
	var live=g.make_unit(d,Vector2.ZERO)
	live.hp=17
	g.units=[live]
	var expected=Manager.target_plan(d,8)
	if not g.train_to_level(d.id,8,before) or d.level!=8 or d.xp!=expected.after.xp: failures.append("bulk training apply")
	if live.hp!=17 or live.maxhp!=g.max_hp(d): failures.append("bulk training current HP preservation")
	var spent=expected.cost
	if g.train_to_level(d.id,8,before) or g.materials!=9999-spent: failures.append("stale or duplicate bulk apply")
	if failures.is_empty(): print("PASS eight improvements: contribution graph, scalable farewell, target training, rarity aura resource, four-leg deer/turtle gait, independent weapon layers and stronger actions")
	else: push_error(str(failures))
	g.queue_free()
	quit(0 if failures.is_empty() else 1)
