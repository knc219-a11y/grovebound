extends "res://animation/pixel_gameplay_preview.gd"
# Actual combat/town renderer with isolated save callbacks from PixelGameplayPreview.
var phase=0
func _ready():
	super()
	owned.clear(); squad.clear(); discovered.clear()
	var fixtures=[
		["deer","다정함","epic"],
		["turtle","단단함","rare"],
		["wolf","민첩함","epic"],
		["marten","용맹함","rare"]]
	for item in fixtures:
		var d=make_owned(item[0],4,{"kind":item[0],"level":4,"xp":0,"trait":item[1],"grade":item[2],"options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1050,760)
	enemies.clear()
	for i in units.size(): units[i].pos=player.pos+Vector2(-80+i*44,-35+i*28)
	for p in [Vector2(1390,680),Vector2(1445,750),Vector2(1390,820)]:
		spawn_enemy("boar",p,7)
		enemies[-1].hp=9999.0
		enemies[-1].maxhp=9999.0
		enemies[-1].active=true
	# Keep the normal stage completion rule satisfied without crowding the review view.
	spawn_enemy("boar",Vector2(2590,850),4,true)
	enemies[-1].hp=9999.0
	enemies[-1].maxhp=9999.0
	in_combat=true
	clear_overlay()
func update_game(dt):
	# The first seconds show real pathing/gaits, then skills and attack poses fire.
	if clock>2.4 and phase==0:
		phase=1
		for i in 4: use_companion_skill(i)
	if clock>4.8 and phase==1:
		phase=2
		for e in enemies: e.hp=maxf(e.hp,9999)
		heal_cd=0
		cast_heal()
	super(dt)
