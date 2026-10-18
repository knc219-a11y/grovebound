extends Node2D
const Player = preload("res://animation/pixel_actor.gd")
var rig
var idle=preload("res://assets/party-pixel/druid.png")
var clock=0.0
var actor={"pos":Vector2.ZERO,"hp":180.0,"walk":true}
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	rig=Player.new("res://animation/druid_walk_frames.json")
func _process(dt):
	clock+=dt
	actor.walk=clock<2.4 or clock>=3.2
	actor.hp=0 if clock>=4.5 and clock<5.2 else 180
	actor.pos.x+=30.0*dt if actor.walk and actor.hp>0 else 0.0
	rig.advance(actor,dt)
	queue_redraw()
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	var font=ThemeDB.fallback_font
	draw_string(font,Vector2(80,90),"GROVEBOUND / DRUID WALK STUDY",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("e0d2b2"))
	draw_string(font,Vector2(80,135),"Walk > stop > resume > down > recover / real runtime frame player",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("98a18a"))
	for i in range(2):
		var p=Vector2(390+i*630,530)
		draw_line(p-Vector2(220,0),p+Vector2(220,0),Color("4c5c43"),2)
		rig.draw(self,p,288,1 if i==0 else -1,Color.WHITE,actor,idle)
		draw_string(font,p+Vector2(-100,50),"RIGHT / 4x" if i==0 else "LEFT / 4x",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("e0d2b2"))
	# Native scale travels in world units, for a speed/proportion check.
	var p=Vector2(150+actor.pos.x,710)
	draw_line(Vector2(80,710),Vector2(1300,710),Color("4c5c43"),1)
	rig.draw(self,p,72,1,Color.WHITE,actor,idle)
	draw_string(font,Vector2(800,750),"Native 1x / 30 px per second",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("98a18a"))
