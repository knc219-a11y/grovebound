extends Node2D
const Player=preload("res://animation/pixel_actor.gd")
var rigs={}
var actors={}
var idle={}
var clock=0.0
var speed=30.0
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["wolf","fox"]:
		rigs[kind]=Player.new("res://animation/"+kind+"_walk_frames.json","res://animation/"+kind+"_trot_frames.json")
		actors[kind]={"pos":Vector2.ZERO,"hp":100.0,"walk":true}
		idle[kind]=load("res://assets/party-pixel/"+kind+".png")
func _process(dt):
	clock+=dt
	speed=30.0 if clock<2.0 else (130.0 if clock<4.0 or clock>=5.0 else 0.0)
	for kind in actors:
		var actor=actors[kind]
		actor.walk=speed>0
		actor.pos.x+=speed*dt
		actor.swing=0.15 if clock>=5.2 and clock<5.6 else 0.0
		rigs[kind].advance(actor,dt)
	queue_redraw()
func _draw():
	var font=ThemeDB.fallback_font
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	draw_string(font,Vector2(70,75),"GROVEBOUND / WOLF + FOX",HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color("e0d2b2"))
	draw_string(font,Vector2(70,118),"Walk > diagonal trot > stop > resume / attack holds stance",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("98a18a"))
	for i in range(2):
		var kind="wolf" if i==0 else "fox"
		for j in range(2):
			var p=Vector2(390+j*670,375+i*285)
			draw_line(p-Vector2(235,0),p+Vector2(235,0),Color("4c5c43"),2)
			rigs[kind].draw(self,p,(48 if i==0 else 40)*4,1 if j==0 else -1,Color.WHITE,actors[kind],idle[kind])
			draw_string(font,p+Vector2(-160,45),kind.to_upper()+" / "+("RIGHT" if j==0 else "LEFT")+" / 4x",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("e0d2b2"))
	draw_string(font,Vector2(75,775),"Native sprites / "+str(int(speed))+" px/s / shared frame player",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("98a18a"))
