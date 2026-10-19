extends Node2D
# Production renderer at 3x for inspection only. Does not change the game camera.
var action=preload("res://animation/boss_action.gd").new()
var rig=preload("res://animation/boar_rig.gd").new()
var font=preload("res://assets/fonts/Galmuri11-Bold.res")
var clock=0.0
var actors=[{},{}] # Retain meshes until deferred Canvas rendering has consumed them.
func _ready(): texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(dt):
	clock+=dt
	queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("263c31"))
	draw_string(font,Vector2(100,100),"우두머리 전용 동작 · 제작 검토 3배",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("e7ddbc"))
	for index in 2:
		var t=fmod(clock,2.5)
		var kind="stomp" if index==0 else "charge"
		var wind=1.15 if index==0 else 1.25
		var actor=actors[index]
		actor.merge({"hp":1,"boss":true,"attack_kind":kind,"pos":Vector2.ZERO,"wind":maxf(0,wind-t),"dash":0.0,"boss_recovery":0.0,"rig_phase":t/0.24*TAU,"walk":false},true)
		if t>=wind:
			if index==0: actor.boss_recovery=maxf(0,0.38-(t-wind))
			elif t<wind+0.48: actor.dash=wind+0.48-t
			else: actor.boss_recovery=maxf(0,0.32-(t-wind-0.48))
		var p=Vector2(410+index*600,560)
		draw_line(p-Vector2(240,0),p+Vector2(240,0),Color("70836b"),2)
		if not action.draw(self,p,144,1,Color.WHITE,actor): rig.draw(self,p,144,1,Color.WHITE,actor)
		draw_string(font,p+Vector2(-200,70),"발구르기 · 앞다리 들기" if index==0 else "돌진 · 낮추기/두 보폭/제동",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e7ddbc"))
