extends Node2D
const Rig = preload("res://animation/boar_rig.gd")
var rig
var actor={"pos":Vector2.ZERO,"hp":100.0,"walk":false}
var elapsed=0.0
var font
var face=1.0

func _ready():
	rig=Rig.new()
	font=load("res://assets/Korean.ttf")

func _process(dt):
	elapsed+=dt
	actor.walk=(elapsed>0.7 and elapsed<3.5) or (elapsed>4.3 and elapsed<7.3)
	face=-1.0 if elapsed>4.3 else 1.0
	if actor.walk: actor.pos.x+=110.0*dt*face
	rig.advance(actor,dt)
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(55,70),"GROVEBOUND / 확정 원화 기반 작은 보폭",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("eaf0d5"))
	for i in range(2):
		var p=Vector2(360+i*720,555)
		draw_rect(Rect2(p+Vector2(-330,-420),Vector2(660,520)),Color("243c33"))
		draw_string(font,p+Vector2(-275,-365),"확정된 정지 자세" if i==0 else ("이동 · 왼쪽" if face<0 else "이동 · 오른쪽") if actor.walk else "대기 · 발걸음 정리",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("eaf0d5"))
		draw_line(p+Vector2(-270,0),p+Vector2(270,0),Color("708976"),2,true)
		rig.draw(self,p,260,1 if i==0 else face,Color.WHITE,{} if i==0 else actor)
	draw_string(font,Vector2(55,745),"같은 원화 / 다리 뿌리 고정 / 지지 구간과 발 들기 / 정지 전환",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d6dfbf"))
