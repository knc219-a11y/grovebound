extends SceneTree
const SaveData = preload("res://save_data.gd")
func _initialize():
	var failures = []
	var fixture = {"version":1,"owned":[{"id":1,"kind":"boar","level":3,"xp":42,"trait":"용맹함"},{"id":2,"kind":"fox","level":2,"xp":9,"trait":"민첩함"}],"squad":[1,99999,2],"materials":17,"tutorial_done":true,"unlocked":true,"next_id":1}
	var decoded = JSON.parse_string(JSON.stringify(fixture))
	var normalized = SaveData.normalize(decoded,["boar","fox"])
	if not normalized.repaired or normalized.squad!=[1,2]: failures.append("dangling party reference")
	if normalized.owned.size()!=2 or normalized.owned[0].xp!=42 or normalized.owned[0].trait!="용맹함": failures.append("creature progress preserved")
	if normalized.next_id<3: failures.append("new creature IDs")
	var valid = decoded.duplicate(true)
	valid.squad=[1.0,2.0]
	var migrated=SaveData.normalize(valid,["boar","fox"])
	if migrated.owned[0].grade!="common" or not migrated.owned[0].options.is_empty(): failures.append("legacy loot migration keeps strength")
	if SaveData.normalize(migrated,["boar","fox"]).repaired: failures.append("migration is idempotent with JSON numeric IDs")
	var legacy = {"owned":[{"id":"7","kind":"boar"},{"id":7,"kind":"fox"}],"squad":["7","7",-5,99]}
	var repaired = SaveData.normalize(legacy,["boar","fox"])
	if repaired.owned.size()!=2 or repaired.owned[0].id==repaired.owned[1].id or repaired.squad.size()!=1: failures.append("legacy or duplicate IDs")
	var world = load("res://main.gd").new()
	var test_path = "user://save-repair-regression-"+str(Time.get_ticks_usec())+".json"
	world.save_path = test_path
	var original = JSON.stringify(fixture)
	var file = FileAccess.open(test_path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	world.load_game()
	if world.squad!=[1,2] or world.materials!=17 or not world.tutorial_done or not world.unlocked: failures.append("loaded progress")
	if world.save_backup_path.is_empty() or FileAccess.get_file_as_string(world.save_backup_path)!=original: failures.append("exact original backup")
	if not world.make_unit({},Vector2.ZERO).is_empty(): failures.append("invalid unit rejected")
	for id in world.squad:
		var unit = world.make_unit(world.find_owned(id),Vector2.ZERO)
		if unit.is_empty() or unit.hp<=0 or not unit.data.has("kind"): failures.append("repaired unit")
	world.save_game()
	world.load_game()
	if world.squad!=[1,2] or world.owned.size()!=2: failures.append("repaired save roundtrip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	if not world.save_backup_path.is_empty(): DirAccess.remove_absolute(ProjectSettings.globalize_path(world.save_backup_path))
	world.free()
	if failures.is_empty(): print("SAVE REPAIR PASS: orphan IDs, JSON/legacy IDs, duplicates, progress retention, exact backup, unit validation, save roundtrip")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
