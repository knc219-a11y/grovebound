extends "res://animation/druid_scale_review.gd"
var review_clock=0.0
var phase=0
func _ready():
	super()
	enemies[0].pos=player.pos-Vector2(150,0)
	player.face=1
	message="왼쪽 적 자동 공격 → 오른쪽 전환 → 이동 → 공격 중 마을 귀환"
	message_time=20
func _process(dt):
	review_clock+=dt
	if review_clock>1.7 and phase==0:
		phase=1
		enemies[0].pos=player.pos+Vector2(150,0)
	elif review_clock>3.0 and review_clock<3.6: stick=Vector2(-0.6,0)
	elif review_clock>=3.6 and phase==1:
		phase=2
		stick=Vector2.ZERO
	elif review_clock>4.1 and phase==2:
		phase=3
		hit_enemy(enemies[0],6,player.pos,player)
		show_camp()
		clear_overlay()
		message="공격 중 귀환 · 기본 지팡이와 대기 자세 복귀"
		message_time=10
	super(dt)
