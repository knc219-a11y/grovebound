extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Save=preload("res://save_data.gd")
const Preview=preload("res://animation/full_gameplay_preview.gd")
const Sound=preload("res://ui/loot_audio.gd")
func _initialize(): call_deferred("check_loot")
func check_loot():
	var failures=[]
	var random=RandomNumberGenerator.new()
	random.seed=20261019
	for star in [1,2,3]:
		var grade=Loot.grade_for_star(star)
		for kind in ["boar","wolf","marten","fox","deer","turtle"]:
			for i in 100:
				var record=Loot.roll(kind,3,random,star)
				if record.star!=star or record.grade!=grade or not record.options.is_empty() or record.has("ivs"): failures.append("wild star/no low-star affix/no IV")
		var stream=Sound.stream(grade)
		if stream.data.is_empty() or stream.get_length()<0.2 or stream.get_length()>0.6: failures.append("grade chime is valid PCM")
	var legacy={"id":8,"kind":"boar","level":7,"xp":22,"trait":"단단함"}
	var migrated=Save.normalize({"owned":[legacy],"squad":[8],"next_id":9},["boar"])
	if migrated.owned[0].star!=1 or migrated.owned[0].trait!="단단함" or migrated.owned[0].level!=7 or not migrated.owned[0].options.is_empty(): failures.append("legacy companion retained without reroll")
	var corrupt={"kind":"deer","grade":"epic","options":[{"key":"power","value":7},{"key":"healing","value":999},{"key":"healing","value":12},{"key":"bad","value":1}]}
	Loot.normalize(corrupt)
	if corrupt.options!=[{"key":"healing","value":16}]: failures.append("invalid duplicate role affixes sanitized")
	var game=Preview.new()
	game.preview_events=false
	root.add_child(game)
	game.set_process(false)
	game.loot_rng.seed=42
	game.clear_overlay()
	game.enemies.clear()
	game.spawn_enemy("boar",game.player.pos,3,false,true)
	game.hit_enemy(game.enemies[0],10000,Vector2.ZERO)
	var candidate=game.captures[0].duplicate(true)
	var snapshot=JSON.stringify(candidate)
	game.in_combat=false
	game.interact()
	var acquired=game.owned[-1]
	if acquired.grade!=candidate.grade or acquired.trait!=candidate.trait or acquired.options!=candidate.options: failures.append("capture transfers exact rolled companion")
	if snapshot!=JSON.stringify(candidate): failures.append("candidate data unchanged")
	var saved=Save.normalize(JSON.parse_string(JSON.stringify({"owned":[acquired],"squad":[acquired.id],"next_id":game.next_id,"discovered":[acquired.kind]})),game.STATS.keys())
	if saved.owned[0].options!=acquired.options or saved.repaired: failures.append("loot persists without reroll through JSON")
	game.show_loot_details(acquired.id,-1,false)
	if not game.overlay.visible: failures.append("loot detail opens safely")
	var options_before=acquired.options.duplicate(true)
	game.open_roster()
	game.clear_overlay()
	game.in_combat=true
	game.show_loot_details(acquired.id,-1,false)
	if game.overlay.visible: failures.append("combat acquisition does not open blocking modal")
	game.in_combat=false
	if acquired.options!=options_before: failures.append("roster does not reroll")
	# Explicit affixes must alter actual stats/damage/healing/cooldown, not just text.
	var d={"id":999,"kind":"boar","level":1,"xp":0,"trait":"시험","grade":"epic","options":[{"key":"vitality","value":10},{"key":"power","value":8},{"key":"armor","value":5}]}
	if absf(game.max_hp(d)-143)>0.001 or absf(game.attack(d)-15.12)>0.001: failures.append("explicit hp/attack affixes")
	var unit=game.make_unit(d,game.player.pos)
	var hp=unit.hp
	game.damage_ally(unit,20,Vector2.ZERO)
	if absf(hp-unit.hp-19)>0.001: failures.append("armor applies to damage")
	d.options=[{"key":"skill_haste","value":10},{"key":"stun_hunter","value":20}]
	game.units=[game.make_unit(d,game.player.pos)]
	game.enemies.clear()
	game.spawn_enemy("boar",game.player.pos+Vector2(60,0),1,true)
	game.clear_overlay()
	game.mode="stage"
	game.revive_target=-1
	game.use_companion_skill(0)
	if absf(game.units[0].skill-9)>0.001: failures.append("haste applies to actual cooldown")
	var enemy=game.enemies[0]
	enemy.stun=1
	hp=enemy.hp
	game.hit_enemy(enemy,10,game.units[0].pos,game.units[0])
	if absf(hp-enemy.hp-12)>0.001: failures.append("conditional stun damage applies")
	var deer=game.make_unit({"id":1000,"kind":"deer","level":1,"trait":"시험","options":[{"key":"healing","value":10}]},game.player.pos)
	game.units[0].hp=1
	game.heal(game.units[0],10,deer.pos,deer)
	if absf(game.units[0].hp-12)>0.001: failures.append("healing affix applies")
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty(): print("COMPANION LOOT PASS: explicit wild stars, no new low-star affixes, immutable acquisition/JSON, legacy migration, real affix effects, details, chimes")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
