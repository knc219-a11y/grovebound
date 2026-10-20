extends Node2D
const Attack=preload("res://animation/druid_attack.gd")
var actions=preload("res://animation/action_player.gd").new()
var weapon=preload("res://animation/weapon_visual.gd").new()
var idle=preload("res://assets/party-pixel/druid-body-v2.png")
var font=preload("res://assets/fonts/Galmuri11-Bold.res")
var actor={"hp":100,"face":1,"walk":false,"action_key":"attack","action_duration":Attack.DURATION,"action_remaining":Attack.DURATION}
var resting={"hp":100,"face":1,"walk":false}
var clock=0.0
func _ready(): texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(dt):
	clock+=dt
	actor.action_remaining=maxf(0,Attack.DURATION-fmod(clock,0.85))
	queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	draw_string(font,Vector2(100,100),"주인공 연속 공격 · 제작 검토 3배",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("e0d5bb"))
	for i in 2:
		var a=resting if i==0 else actor
		var p=Vector2(420+i*600,570)
		draw_line(p-Vector2(150,0),p+Vector2(150,0),Color("4d6551"),2)
		if not weapon.in_front(a): weapon.draw(self,p,216,1,Color.WHITE,a)
		if i==0 or not actions.draw(self,p,216,1,Color.WHITE,"druid",a):
			draw_set_transform(p,0,Vector2(3,3))
			draw_texture(idle,Vector2(-24,-72))
			draw_set_transform(Vector2.ZERO)
		if weapon.in_front(a): weapon.draw(self,p,216,1,Color.WHITE,a)
		var label="기존 대기 · 몸체60px" if i==0 else "대기" if not Attack.active(a) else ["대기","준비","준비","발동","회수","회수","회수","대기"][Attack.frame(a)]
		draw_string(font,p+Vector2(-120,70),label,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e0d5bb"))
