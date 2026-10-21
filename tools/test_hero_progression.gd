extends SceneTree
const H=preload("res://hero_progression.gd")
const Main=preload("res://main.gd")
const Preview=preload("res://animation/pixel_gameplay_preview.gd")
var checks=0
func check(value,caption):
	checks+=1
	if not value: push_error("HERO: "+caption); quit(1)
func press_named(node,caption):
	for child in node.get_children():
		if child is Button and child.text==caption:
			child.pressed.emit()
			return true
		if press_named(child,caption): return true
	return false
func _initialize(): call_deferred("run")
func run():
	var p=H.fresh()
	check(H.valid(p),"fresh valid")
	check(H.stats(p).hp==180 and H.stats(p).attack==6 and H.skill(p,"heal").amount==55 and H.skill(p,"buff").power==0.6,"approved starting performance")
	check(not H.plan(p,"buy","twig_staff").error.is_empty(),"no free purchase")
	var next=H.reward(p,1,true)
	check(next.gold==35 and next.xp==16 and next.items.size()==1 and p.gold==0,"boss grants fixed reward without editing baseline")
	check(H.reward(p,1,true)==next,"retry never rerolls reward")
	check(H.valid(JSON.parse_string(JSON.stringify(next))),"RNG and inventory JSON round trip")
	for i in 1000: next=H.reward(next,30)
	check(next.level==30 and next.xp==0 and H.valid(next),"level cap and rewards remain valid")
	var g=Main.new()
	g.save_path="res://.qa-data/hero-progression.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa-data"))
	DirAccess.remove_absolute(g.save_path)
	root.add_child(g); g.set_process(false); g.clear_overlay(); g.hero.gold=10000; g.hero.level=18; g.sync_hero()
	var companion=g.make_owned("boar",1)
	g.squad=[companion.id]
	var companions=g.owned.duplicate(true)
	var baseline=g.hero.duplicate(true)
	g.save_path="res://.qa-data/no-such-folder/hero.json"
	check(not g.commit_hero_action("buy","twig_staff",baseline) and g.hero==baseline,"failed write does not charge or grant")
	g.save_path="res://.qa-data/hero-progression.json"
	check(g.commit_hero_action("buy","twig_staff",baseline),"real purchase commits")
	check(not g.commit_hero_action("buy","twig_staff",baseline) and g.hero.items.size()==1,"stale/double click cannot charge again")
	var id=g.hero.items[0].id
	check(g.commit_hero_action("equip",{"id":id,"slot":"weapon"},g.hero.duplicate(true)),"equip")
	check(H.stats(g.hero).attack>H.base_stats(g.hero).attack,"gear stats apply")
	check(not g.commit_hero_action("sell",id,g.hero.duplicate(true)),"equipped item protected from sale")
	check(g.commit_hero_action("enhance",id,g.hero.duplicate(true)) and H.find(g.hero,id).enhance==1,"enhancement")
	check(not g.commit_hero_action("equip",{"id":id,"slot":"armor"},g.hero.duplicate(true)),"wrong slot rejected")
	for key in ["vitality_charm","stream_charm"]: check(g.commit_hero_action("buy",key,g.hero.duplicate(true)),"charm purchase")
	check(g.commit_hero_action("equip",{"id":2,"slot":"charm1"},g.hero.duplicate(true)),"first charm")
	check(g.commit_hero_action("equip",{"id":3,"slot":"charm2"},g.hero.duplicate(true)),"second charm")
	check(g.hero.equipped.charm1!=g.hero.equipped.charm2 and H.stats(g.hero).haste>0,"two distinct charm instances and haste")
	for key in H.SKILLS: check(g.commit_hero_action("skill",key,g.hero.duplicate(true)),"skill growth "+key)
	check(g.owned==companions,"hero economy preserves companions and options")
	var saved=g.save_payload().duplicate(true)
	g.hero=H.fresh(); g.load_game()
	check(g.Special.equivalent(g.hero,saved.hero) and g.Special.equivalent(g.owned,saved.owned) and g.squad==saved.squad,"real file reload preserves all progression")
	g.open_hero(); check(g.menu_page=="hero" and g.overlay.visible,"status page")
	for page in [1,2,3]: g.open_hero(page); check(g.menu_page=="hero","hero page "+str(page))
	var gold=g.hero.gold
	g.open_hero(3)
	check(press_named(g.overlay,"구매 120 G"),"shop purchase button opens confirmation")
	check(g.hero.gold==gold,"confirmation preview does not spend")
	check(press_named(g.overlay,"확인") and g.hero.gold==gold-120,"UI confirmation commits purchase")
	var spare=g.hero.items[-1].id
	check(g.commit_hero_action("sell",spare,g.hero.duplicate(true)) and g.hero.gold==gold-90 and H.find(g.hero,spare).is_empty(),"sale pays fixed quarter value and removes item")
	check(g.commit_hero_action("unequip","weapon",g.hero.duplicate(true)) and g.hero.equipped.weapon==0,"unequip")
	check(g.commit_hero_action("equip",{"id":id,"slot":"weapon"},g.hero.duplicate(true)),"reequip preserves enhancement")
	# Real combat uses skills and defenses; no tutorial or swarm rewards.
	g.start_stage(false); g.clear_overlay()
	check(not g.commit_hero_action("buy","twig_staff",g.hero.duplicate(true)),"field purchase blocked")
	g.units[0].pos=g.player.pos; g.units[0].hp=1
	g.cast_heal(); check(g.units[0].hp>56 and g.heal_cd<8,"rank/support/haste heal in combat")
	g.cast_buff(); check(g.units[0].buff_power>0.6 and g.units[0].buff>7,"grown buff in combat")
	check(g.cast_barrier() and g.player.special_barrier>0 and g.units[0].special_barrier>0,"barrier shields nearby allies")
	var hp=g.player.hp
	g.damage_ally(g.player,10,g.player.pos)
	check(g.player.hp==hp,"barrier absorbs real damage")
	var enemy=g.enemies[0]
	g.player.pos=enemy.pos
	# Directly use an engageable first-pack target, then retry saving with a broken directory.
	g.trail.update(g,0)
	g.save_path="res://.qa-data/no-such-folder/hero.json"
	var before=g.hero.duplicate(true)
	g.hit_enemy(enemy,100000,g.player.pos,g.player)
	check(not g.hero_pending.is_empty() and g.hero==before,"failed reward save keeps published profile unchanged")
	var pending=g.hero_pending.duplicate(true)
	g.hit_enemy(enemy,100000,g.player.pos,g.player)
	check(g.hero_pending==pending,"dead enemy cannot reward twice")
	g.save_path="res://.qa-data/hero-progression.json"
	check(g.save_game() and g.Special.equivalent(g.hero,pending) and g.hero_pending.is_empty(),"retry publishes exact pending reward")
	# Migration takes a byte-for-byte backup and preserves companion identities.
	var old=g.save_payload(); old.erase("hero")
	var f=FileAccess.open(g.save_path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var original=FileAccess.get_file_as_bytes(g.save_path)
	g.load_game()
	check(g.Special.equivalent(g.hero,H.fresh()) and not g.save_backup_path.is_empty() and FileAccess.get_file_as_bytes(g.save_backup_path)==original,"legacy migration backed up")
	check(g.Special.equivalent(g.owned,old.owned) and g.squad==old.squad,"migration preserves companion data")
	var bad=g.save_payload(); bad.hero.version=99
	f=FileAccess.open(g.save_path,FileAccess.WRITE); f.store_string(JSON.stringify(bad)); f.close()
	original=FileAccess.get_file_as_bytes(g.save_path)
	g.load_game()
	check(g.save_blocked and not g.save_game() and FileAccess.get_file_as_bytes(g.save_path)==original,"future hero format preserved without overwrite")
	for mutation in ["duplicate","invalid_slot","negative_gold"]:
		var broken=next.duplicate(true)
		if mutation=="duplicate": broken.items.append(broken.items[0].duplicate(true))
		elif mutation=="invalid_slot": broken.equipped.weapon=999999
		else: broken.gold=-1
		check(not H.valid(broken),"malformed hero rejected: "+mutation)
	g.free()
	print("HERO PROGRESSION PASS: ",checks," checks")
	quit()
