extends Node2D
const Player = preload("res://animation/pixel_actor.gd")
var before
var after
var idle=preload("res://assets/party-pixel/druid.png")
var old_actor={"pos":Vector2.ZERO,"hp":180.0,"walk":true}
var new_actor={"pos":Vector2.ZERO,"hp":180.0,"walk":true}
var clock=0.0
var speed=210.0
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	before=Player.new("res://animation/druid_walk_frames.json")
	after=Player.new("res://animation/druid_walk_frames.json","res://animation/druid_run_frames.json")
func _process(dt):
	clock+=dt
	var t=fposmod(clock,6.0)
	speed=210.0 if t<2.5 or t>=4.0 else (30.0 if t<3.3 else 0.0)
	for actor in [old_actor,new_actor]:
		actor.walk=speed>0
		actor.pos.x+=speed*dt
	before.advance(old_actor,dt)
	after.advance(new_actor,dt)
	queue_redraw()
func _draw():
	var font=ThemeDB.fallback_font
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	draw_string(font,Vector2(70,80),"DRUID / WALK TO RUN",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("e0d2b2"))
	draw_string(font,Vector2(70,125),"210 px/s > 30 px/s > stop > 210 px/s / same gameplay speed",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("98a18a"))
	for i in range(2):
		var p=Vector2(360+i*680,510)
		draw_line(p-Vector2(240,0),p+Vector2(240,0),Color("4c5c43"),2)
		if i==0: before.draw(self,p,288,1,Color.WHITE,old_actor,idle)
		else: after.draw(self,p,288,1,Color.WHITE,new_actor,idle)
		draw_string(font,p+Vector2(-170,55),"BEFORE / walk only" if i==0 else "AFTER / speed selects gait",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e0d2b2"))
	var p=Vector2(100+fposmod(new_actor.pos.x,1100),720)
	draw_line(Vector2(70,720),Vector2(1340,720),Color("4c5c43"),1)
	after.draw(self,p,72,1,Color.WHITE,new_actor,idle)
	draw_string(font,Vector2(820,770),"Native 1x / "+str(int(speed))+" px/s",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("98a18a"))
