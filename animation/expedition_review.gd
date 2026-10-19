extends "res://animation/pixel_gameplay_preview.gd"
var view="flow"
var phase=0
func _ready():
	super()
	expedition.clear()
	owned.clear()
	squad.clear()
	discovered.clear()
	materials=0
	tutorial_done=false
	unlocked=false
	show_camp()
	player.pos=Vector2(750,490)
	town_position=player.pos
	screenshot_mode=true
	if view=="recap":
		var d=make_owned("boar",1)
		squad=[d.id]
		tutorial_done=true
		start_stage(false)
		for i in 4: hit_enemy(enemies[i],10000,player.pos)
		var c=Loot.roll("fox",2,loot_rng,"rare")
		c.pos=player.pos
		captures=[c]
		interact()
		finish(true)
func _process(dt):
	if view=="flow":
		if clock>1.2 and phase==0:
			phase=1
			tutorial_species="boar"
			start_stage(true)
			hit_enemy(enemies[0],10000,player.pos)
			player.pos=captures[0].pos+Vector2(-65,0)
		elif clock>2.4 and phase==1:
			phase=2
			interact()
		elif clock>4.2 and phase==2:
			phase=3
			start_practice()
			hit_enemy(enemies[-1],10000,player.pos)
		elif clock>6.4 and phase==3:
			phase=4
			resume_game()
			open_roster()
		elif clock>8 and phase==4:
			phase=5
			resume_game()
	combat_feedback.advance(dt)
	motion_actions.advance(player,dt)
	super(dt)
