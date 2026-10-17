extends Node2D
const MeshRig = preload("res://animation/boar_rig_v3.gd")
const FrameRig = preload("res://animation/boar_rig.gd")
var rigs=[]
var actors=[]
var elapsed=0.0
var font
var face=1.0

func _ready():
	rigs=[MeshRig.new(),FrameRig.new()]
	font=load("res://assets/Korean.ttf")
	for i in range(2): actors.append({"pos":Vector2.ZERO,"hp":100.0,"walk":false})

func _process(dt):
	elapsed+=dt
	face=-1.0 if elapsed>4.3 else 1.0
	for i in range(2):
		actors[i].walk=(elapsed>0.7 and elapsed<3.5) or (elapsed>4.3 and elapsed<7.3)
		if actors[i].walk: actors[i].pos.x+=110.0*dt*face
		rigs[i].advance(actors[i],dt)
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(55,70),"GROVEBOUND / 걷기 프레임 원화 비교",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("eaf0d5"))
	for i in range(2):
		var p=Vector2(360+i*720,555)
		draw_rect(Rect2(p+Vector2(-330,-420),Vector2(660,520)),Color("243c33"))
		draw_string(font,p+Vector2(-275,-365),"기존 · 한 장의 그림을 변형" if i==0 else "신규 · 걷기 원화 8프레임",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("eaf0d5"))
		draw_line(p+Vector2(-270,0),p+Vector2(270,0),Color("708976"),2,true)
		rigs[i].draw(self,p,260,face,Color.WHITE,actors[i])
	draw_string(font,Vector2(55,745),"같은 이동 거리와 속도 / 대기 → 오른쪽 걷기 → 정지 → 왼쪽 걷기",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d6dfbf"))
