extends "res://main.gd"
var review_time=0.0
var phase=0
func load_game(): pass
func save_game(): pass
func _ready():
	super()
	player.pos=Vector2(700,540)
	town_position=player.pos
	tutorial_done=true
	var d=make_owned("boar",2)
	squad=[d.id]
func _process(dt):
	review_time+=dt
	if review_time<2: stick=Vector2(-0.65,0)
	elif review_time<3 and phase==0:
		phase=1
		open_roster()
	elif review_time>4 and phase==1:
		phase=2
		resume_game()
	elif review_time>4 and review_time<8: stick=Vector2(1,0)
	elif review_time>=8 and phase==2:
		phase=3
		start_stage(false)
	elif review_time>=10 and phase==3:
		phase=4
		show_camp()
	else: stick=Vector2.ZERO
	super(dt)
