extends Node2D
const Rig = preload("res://animation/boar_rig.gd")
var rig
var actors=[]
var elapsed=0.0
var font
const LABELS=["대기 · 호흡", "이동 · 거리 기반 보행", "공격 · 머리와 몸의 힘", "공격 준비 → 돌진", "피격 · 짧은 반응", "쓰러짐 → 소생"]

func _ready():
	rig=Rig.new(load("res://assets/boar-parts.png"))
	font=load("res://assets/Korean.ttf")
	for i in range(6): actors.append({"pos":Vector2.ZERO,"hp":100.0,"walk":false})

func _process(dt):
	elapsed+=dt
	for i in range(6):
		var a=actors[i]
		a.walk=i==1 or (i==3 and fmod(elapsed,3.2)>1.3)
		if a.walk: a.pos.x+=dt*110.0
		a["swing"]=maxf(0,0.22-fmod(elapsed,1.3)) if i==2 else 0.0
		a["wind"]=1.0 if i==3 and fmod(elapsed,3.2)<=1.3 else 0.0
		a["dash"]=1.0 if i==3 and a.walk else 0.0
		a.hp=0.0 if i==5 and fmod(elapsed,4.0)>1.0 and fmod(elapsed,4.0)<3.0 else 100.0
		rig.advance(a,dt)
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(55,65),"GROVEBOUND  /  멧돼지 관절 애니메이션",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("eaf0d5"))
	for i in range(6):
		var p=Vector2(255+(i%3)*465,365+int(i/3)*335)
		draw_rect(Rect2(p+Vector2(-215,-255),Vector2(430,300)),Color("243c33"))
		draw_string(font,p+Vector2(-185,-210),LABELS[i],HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("e1e6c4"))
		draw_set_transform(p,0,Vector2(1,0.22))
		draw_circle(Vector2.ZERO,100,Color(0,0,0,0.18))
		draw_set_transform(Vector2.ZERO)
		var flash=i==4 and fmod(elapsed,1.6)<0.15
		var offset=Vector2(-5,0) if flash else Vector2.ZERO
		rig.draw(self,p+offset,160,1,Color(1.5,1.2,1.1) if flash else Color.WHITE,actors[i])
