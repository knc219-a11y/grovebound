extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Manager=preload("res://companion_management.gd")
const Save=preload("res://save_data.gd")
const Campaign=preload("res://campaign.gd")
const Synthesis=preload("res://synthesis_rules.gd")

func _init():
	var failures=[]
	for pair in [[1,20],[2,30],[3,40],[4,50],[5,60]]:
		var record={"kind":"boar","star":pair[0],"level":pair[1],"xp":17,"grade":Loot.grade_for_star(pair[0]),"options":[]}
		if Loot.max_level(record)!=pair[1] or not Loot.is_max_level(record): failures.append("star cap "+str(pair[0]))
		if Manager.project(record,999)!=record: failures.append("max-level XP blocked "+str(pair[0]))
	var near={"kind":"boar","star":1,"level":19,"xp":660,"grade":"common","options":[]}
	var capped=Manager.project(near,40)
	if capped.level!=20 or capped.xp!=0: failures.append("XP stops exactly at cap")
	var legacy={"version":1,"owned":[{"id":4,"kind":"boar","level":25,"xp":12,"trait":"강인함","grade":"common","options":[{"key":"power","value":8}],"favorite":true}],"squad":[4],"next_id":5,"discovered":["boar"]}
	var migrated=Save.normalize(legacy,["boar"])
	var old=migrated.owned[0]
	if old.star!=1 or old.level!=25 or old.xp!=12 or old.options.size()!=1 or not old.get("legacy_options",false) or not old.get("legacy_overcap",false): failures.append("lossless legacy over-cap migration")
	var one_max={"id":7,"kind":"boar","star":1,"grade":"common","level":20,"xp":0,"trait":"강인함","options":[],"favorite":true}
	var two_start=Manager.promotion_preview(one_max)
	if two_start.star!=2 or two_start.level!=1 or two_start.id!=7 or two_start.trait!="강인함" or not two_start.favorite: failures.append("1->2 identity-preserving preview")
	var two_max=two_start.duplicate(true)
	two_max.level=30
	var three_start=Manager.promotion_preview(two_max)
	if three_start.star!=3 or three_start.level!=1 or not Manager.promotion_preview(three_start).is_empty(): failures.append("2->3 and no direct 3->4 promotion")
	var game=load("res://main.gd").new()
	var two_recovery=two_start.duplicate(true)
	two_recovery.level=15
	var three_recovery=three_start.duplicate(true)
	three_recovery.level=20
	if game.max_hp(two_start)>=game.max_hp(one_max) or game.attack(two_start)>=game.attack(one_max): failures.append("promotion visibly resets raw combat stats")
	if game.max_hp(two_recovery)<=game.max_hp(one_max) or game.attack(two_recovery)<=game.attack(one_max): failures.append("2-star recovers before mid cap")
	if game.max_hp(three_start)>=game.max_hp(two_max) or game.attack(three_start)>=game.attack(two_max): failures.append("3-star starts below 2-star max")
	if game.max_hp(three_recovery)<=game.max_hp(two_max) or game.attack(three_recovery)<=game.attack(two_max): failures.append("3-star recovers near level 20")
	game.free()
	var rng=RandomNumberGenerator.new()
	rng.seed=20261020
	for stage_id in Campaign.STAGES:
		for i in 50:
			if Campaign.wild_star(stage_id,rng)!=1: failures.append("implemented early stage yielded above 1-star")
	if Synthesis.position_of("boar")!="frontline" or Synthesis.position_of("bat")!="striker" or Synthesis.position_of("deer")!="ranged_support": failures.append("position map")
	if Synthesis.existing_pool("species","wolf")!=["wolf"] or Synthesis.existing_pool("position","boar")!=["boar","turtle"]: failures.append("preservation pool")
	if not Synthesis.NEW_SPECIAL_SPECIES.is_empty(): failures.append("unapproved new special species must not be invented")
	if failures.is_empty(): print("SYNTHESIS PROGRESSION PASS: caps, XP stop, reset-and-recover promotion curve, identity preservation, legacy migration, early-stage stars, preservation pools, extensible special catalog")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
