extends Node2D
const Before = preload("res://animation/boar_rig_before.gd")
const After = preload("res://animation/boar_rig.gd")
var rigs=[]
var actors=[]
var font
var elapsed=0.0

func _ready():
	var atlas=load("res://assets/boar-parts.png")
	rigs=[Before.new(atlas),After.new(atlas)]
	font=load("res://assets/Korean.ttf")
	for i in range(2): actors.append({"pos":Vector2.ZERO,"hp":100.0,"walk":false})

func _process(dt):
	elapsed+=dt
	for i in range(2):
		actors[i].walk=elapsed>0.6 and elapsed<4.8
		if actors[i].walk: actors[i].pos.x+=110.0*dt
		rigs[i].advance(actors[i],dt)
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(60,80),"GROVEBOUND / 멧돼지 이음새 개선 비교",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("eaf0d5"))
	for i in range(2):
		var p=Vector2(360+i*720,570)
		draw_rect(Rect2(p+Vector2(-330,-420),Vector2(660,545)),Color("243c33"))
		draw_string(font,p+Vector2(-275,-365),"수정 전 · 분리 부위 회전" if i==0 else "수정 후 · 연결 원화 + 메시 변형",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("eaf0d5"))
		draw_set_transform(p,0,Vector2(1,0.2))
		draw_circle(Vector2.ZERO,140,Color(0,0,0,0.18))
		draw_set_transform(Vector2.ZERO)
		rigs[i].draw(self,p,240,1,Color.WHITE,actors[i])
	draw_string(font,Vector2(75,760),"동일한 이동 속도 · 대기 → 걷기 → 정지 / 게임 실행 화면",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("bfcdb4"))
