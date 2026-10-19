extends Node2D
const Actions=preload("res://animation/action_player.gd")
const Pixel=preload("res://animation/pixel_actor.gd")
const Boar=preload("res://animation/boar_pixel.gd")
const Weapon=preload("res://animation/weapon_visual.gd")
var actions
var weapon
var rigs={}
var actors={}
var idle={}
var clock=0.0
var last_beat=-1
var kinds=["druid","boar","wolf","marten","fox","deer","turtle"]
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	actions=Actions.new()
	weapon=Weapon.new()
	for kind in kinds:
		actors[kind]={"pos":Vector2.ZERO,"hp":100.0,"walk":true}
		if kind=="boar":
			rigs[kind]=Boar.new()
			idle[kind]=rigs[kind].portrait()
		elif kind=="druid":
			rigs[kind]=Pixel.new("res://animation/druid_walk_frames.json","res://animation/druid_run_frames.json")
			idle[kind]=load("res://assets/party-pixel/druid-body-v2.png")
		else:
			rigs[kind]=Pixel.new("res://animation/"+kind+"_walk_frames.json","res://animation/"+kind+"_trot_frames.json")
			idle[kind]=load("res://assets/party-pixel/"+kind+".png")
func _process(dt):
	clock+=dt
	var beat=floori((clock-2.0)/1.0)
	for kind in kinds:
		var actor=actors[kind]
		actions.advance(actor,dt)
		actor.walk=clock<2.0
		actor.pos.x+=30*dt if actor.walk else 0.0
		rigs[kind].advance(actor,dt)
		actor.channeling=kind=="druid" and clock>=5.0
		actor.channel_time=maxf(0,clock-5.0)
		if clock>=2.0 and beat!=last_beat:
			var key="attack"
			if kind=="fox": key="cast"
			elif kind=="deer": key="heal"
			elif kind=="turtle": key="guard" if beat%2==0 else "attack"
			elif kind=="druid": key="support" if clock<3.0 else "heal"
			actions.start(actor,kind,key)
	last_beat=beat
	queue_redraw()
func _draw():
	var font=ThemeDB.fallback_font
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	draw_string(font,Vector2(60,65),"GROVEBOUND / COMPLETE PARTY MOTION",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("e0d2b2"))
	draw_string(font,Vector2(60,108),"Walk first / event poses next / druid channels revive at 5 seconds",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("98a18a"))
	for i in kinds.size():
		var kind=kinds[i]
		var p=Vector2(180+(i%4)*355,390) if i<4 else Vector2(250+(i-4)*470,690)
		var h=72 if kind=="druid" else (48 if kind=="boar" else idle[kind].get_height())
		draw_line(p-Vector2(125,0),p+Vector2(125,0),Color("4c5c43"),2)
		if kind=="druid": weapon.draw(self,p,h*3,1,Color.WHITE,actors[kind])
		if not actions.draw(self,p,h*3,1,Color.WHITE,kind,actors[kind]):
			if kind=="boar": rigs[kind].draw(self,p,h*3,1,Color.WHITE,actors[kind])
			else: rigs[kind].draw(self,p,h*3,1,Color.WHITE,actors[kind],idle[kind])
		var chosen=actions.selection(kind,actors[kind])
		var label=chosen.get("key","walk" if clock<2.0 else "idle")
		draw_string(font,p+Vector2(-105,40),kind.to_upper()+" / "+label,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("e0d2b2"))
