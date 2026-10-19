extends SceneTree
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
const Pose=preload("res://animation/druid_pose.gd")
func _initialize(): call_deferred("check")
func check():
	var g=Preview.new()
	root.add_child(g)
	g.set_process(false)
	g.owned.clear(); g.squad.clear()
	for kind in ["boar","turtle"]: g.squad.append(g.make_owned(kind,3).id)
	g.start_stage(false)
	g.player.pos=Vector2(1100,740)
	for i in 2: g.units[i].pos=g.player.pos+Vector2(30+i*20,10)
	g.enemies.clear(); g.spawn_enemy("boar",Vector2(2590,850),4,true)
	var failures=[]
	g.units[0].hp=g.units[0].maxhp-60
	var hp=g.units[0].hp
	g.cast_heal()
	if not is_equal_approx(g.units[0].hp-hp,55) or g.heal_cd!=8: failures.append("heal amount/cooldown")
	if not g.motion_actions.selection("druid",g.player).get("druid_art",false) or Pose.active_key(g.player)!="heal": failures.append("heal body and weapon selection")
	var hand=Pose.mount(g.player)
	g.player.walk=true
	if not g.motion_actions.selection("druid",g.player).is_empty() or Pose.mount(g.player)!=Vector2(8,-36): failures.append("walking keeps weapon with gait")
	g.player.walk=false
	g.motion_actions.advance(g.player,0.45)
	if Pose.mount(g.player)!=Vector2(8,-36): failures.append("recovery weapon returns to idle grip")
	g.motion_actions.advance(g.player,1)
	g.cast_buff()
	if g.buff_cd!=14 or Pose.active_key(g.player)!="support" or Pose.mount(g.player)==hand: failures.append("buff pose/cooldown/own grip")
	g.units[1].hp=0
	g.units[1].pos=g.player.pos+Vector2(40,0)
	g.holding_revive=true
	g.update_game(0.05)
	if Pose.active_key(g.player)!="revive" or not g.motion_actions.selection("druid",g.player).get("druid_art",false): failures.append("actual revive channel pose")
	var staff_tip=Pose.mount(g.player)+Vector2(-6,34).rotated(g.weapon_visual.angle_for(g.player))
	if staff_tip.y>1: failures.append("kneeling staff penetrates the ground")
	g.holding_revive=false
	g.update_game(0.05)
	if Pose.active_key(g.player)=="revive" or g.units[1].hp>0: failures.append("revive interruption")
	g.holding_revive=true
	for i in 61: g.update_game(0.05)
	if not is_equal_approx(g.units[1].hp,g.units[1].maxhp*0.3) or g.player.get("channeling",false): failures.append("3s revive completion and exit")
	if g.motion_actions.druid_support==null: failures.append("body sheet missing")
	else:
		var image=g.motion_actions.druid_support.get_image()
		for row in 3:
			for frame in 6:
				var box=image.get_region(Rect2i(frame*112,row*104,112,104)).get_used_rect()
				if box.position.x<=0 or box.position.y<=0 or box.end.x>=112 or box.end.y>=104 or box.size.y>72: failures.append("body clipping/scale")
	if failures.is_empty(): print("DRUID SUPPORT PASS: body/weapon routing, moving/recovery grip, Q55/8s, E14s, actual 3s/30% revive, interrupt, native72px bounds")
	else: push_error(str(failures))
	g.free()
	quit(0 if failures.is_empty() else 1)
