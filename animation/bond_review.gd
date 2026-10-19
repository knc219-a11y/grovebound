extends "res://animation/pixel_gameplay_preview.gd"
var bonded=false
var returned=false
func _ready():
	super()
	owned.clear()
	squad.clear()
	units.clear()
	tutorial_done=true
	start_stage(false)
	screenshot_mode=true
	enemies.clear()
	captures.clear()
	player.pos=Vector2(1100,740)
	var candidate=Loot.roll("boar",2,loot_rng,"rare")
	candidate.pos=player.pos+Vector2(76,30)
	captures.append(candidate)
	message="전의를 잃고 쉬는 야수에게 다가가 교감하세요."
	message_time=3
func _process(dt):
	combat_feedback.advance(dt)
	motion_actions.advance(player,dt)
	if clock>1.3 and not bonded:
		bonded=true
		interact()
	if clock>3.6 and not returned:
		returned=true
		resume_game()
	if returned and not units.is_empty():
		move_entity(units[0],player.pos+Vector2(-50,45),90,dt,10)
		boar_rig.advance(units[0],dt)
	super(dt)
