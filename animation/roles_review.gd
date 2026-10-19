extends "res://animation/pixel_gameplay_preview.gd"
var view="flow"
var group=0
var cues={}
func setup_team(index):
	owned.clear()
	squad.clear()
	var kinds=["marten","turtle","deer","fox"] if index==0 else ["boar","wolf","deer","turtle"]
	var traits=["용맹함","단단함","다정함","강인함"] if index==0 else ["강인함","민첩함","다정함","단단함"]
	for i in 4:
		var d=make_owned(kinds[i],3,{"kind":kinds[i],"level":3,"xp":0,"trait":traits[i],"grade":"common","options":[]})
		squad.append(d.id)
	start_stage(false)
	player.pos=Vector2(1100,740)
	for i in 4:
		units[i].pos=player.pos+Vector2(80+i*35,20+i*20)
		units[i].hp*=0.65
	enemies.clear()
	for i in 4:
		spawn_enemy("boar",player.pos+Vector2(240+(i%2)*70,-30+(i/2)*95),8,i==0)
		enemies[-1].active=true
	in_combat=true
func _ready():
	super()
	setup_team(0 if view in ["flow","hud","detail"] else 1)
	if view=="detail":
		screenshot_mode=true
		in_combat=false
		show_loot_details(owned[-1].id,-1,false)
	elif view=="contribution":
		screenshot_mode=true
		for i in 4: use_companion_skill(i)
		damage_ally(units[3],100,enemies[0].pos)
		heal(units[3],30,units[2].pos,units[2])
		show_camp()
		report_contributions=true
		show_run_report()
	elif view=="hud": use_companion_skill(1)
func update_game(dt):
	if view=="flow" and clock>5.5 and group==0:
		group=1
		setup_team(1)
	super(dt)
	if mode!="stage": return
	for i in 4:
		var key=str(group)+"_"+str(i)
		var start=0.7+i*0.5+group*5.5
		if clock>=start and not cues.has(key):
			cues[key]=true
			use_companion_skill(i)
