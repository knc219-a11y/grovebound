extends Node2D
const Actions=preload("res://animation/action_player.gd")
const Weapon=preload("res://animation/weapon_visual.gd")
var actions=Actions.new()
var weapon=Weapon.new()
var actors=[]
var clock=0.0
var beat=-1
var font:Font
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=load("res://assets/fonts/Galmuri11-Bold.res")
	for i in 3: actors.append({"hp":100.0,"face":1.0,"walk":false,"channeling":i==2,"channel_time":0.0})
func _process(dt):
	clock+=dt
	var next=floori(clock/1.3)
	for i in 3:
		actions.advance(actors[i],dt)
		actors[i].channel_time=clock
		if next!=beat: actions.start(actors[i],"druid",["heal","support","revive"][i])
	beat=next
	queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	draw_string(font,Vector2(80,95),"드루이드 지원 원화 · 제작 판독용 3배",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("e0d5bb"))
	for i in 3:
		var p=Vector2(280+i*440,620)
		if not weapon.in_front(actors[i]): weapon.draw(self,p,216,1,Color.WHITE,actors[i])
		if not actions.draw(self,p,216,1,Color.WHITE,"druid",actors[i]):
			draw_set_transform(p,0,Vector2(3,3))
			draw_texture(load("res://assets/party-pixel/druid-body-v2.png"),Vector2(-24,-72))
			draw_set_transform(Vector2.ZERO)
		if weapon.in_front(actors[i]): weapon.draw(self,p,216,1,Color.WHITE,actors[i])
		draw_string(font,p+Vector2(-60,65),["회복","강화","소생 집중"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("e0d5bb"))
