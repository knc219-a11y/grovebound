extends Node2D
const Feedback=preload("res://animation/combat_feedback.gd")
var feedback=Feedback.new()
var clock=0.0
var beat=-1
var textures={}
var font: Font
var centers=[Vector2(125,155),Vector2(360,155),Vector2(595,155),Vector2(125,325),Vector2(360,325),Vector2(595,325)]
func _ready():
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for kind in ["wolf","fox","deer","marten","turtle","druid"]: textures[kind]=load("res://assets/party-pixel/"+kind+".png")
	var variation=FontVariation.new()
	variation.base_font=load("res://assets/Korean.ttf")
	variation.variation_opentype={"wght":600.0}
	font=variation
func _process(dt):
	clock+=dt
	feedback.advance(dt)
	var next=floori(clock/1.2)
	if next!=beat:
		feedback.emit("melee",centers[0]-Vector2(40,0),centers[0]+Vector2(40,0),14)
		feedback.emit("fox",centers[1]-Vector2(40,0),centers[1]+Vector2(40,0),21)
		feedback.emit("heal",centers[2]-Vector2(40,0),centers[2]+Vector2(40,0),35)
		feedback.emit("block",centers[3]-Vector2(40,0),centers[3],6)
		feedback.emit("buff",centers[4]-Vector2(40,0),centers[4]+Vector2(40,0))
		if next%3==2: feedback.emit("revive",centers[5]-Vector2(40,0),centers[5]+Vector2(40,0))
		beat=next
	queue_redraw()
func sprite(kind,p,tint=Color.WHITE):
	var texture=textures[kind]
	draw_texture_rect(texture,Rect2(p-Vector2(texture.get_width()/2.0,texture.get_height()),texture.get_size()),false,tint)
func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("202825"))
	var label_font=ThemeDB.fallback_font
	draw_string(label_font,Vector2(55,65),"GROVEBOUND / COMBAT FEEDBACK",HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("e0d2b2"))
	draw_set_transform(Vector2.ZERO,0,Vector2(2,2))
	for i in centers.size():
		var p=centers[i]
		draw_rect(Rect2(p-Vector2(110,85),Vector2(220,135)),Color("27312b"))
		draw_line(p+Vector2(-95,1),p+Vector2(95,1),Color("4c5c43"),1)
		draw_string(label_font,p+Vector2(-95,40),["MELEE","FOX SHOT","HEAL","SHIELD HIT","BUFF","REVIVE"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c9b69b"))
	sprite("wolf",centers[0]-Vector2(40,0))
	sprite("marten",centers[0]+Vector2(40,0))
	sprite("fox",centers[1]-Vector2(40,0))
	sprite("marten",centers[1]+Vector2(40,0))
	sprite("deer",centers[2]-Vector2(40,0))
	sprite("marten",centers[2]+Vector2(40,0))
	sprite("turtle",centers[3])
	sprite("druid",centers[4]-Vector2(40,0))
	sprite("wolf",centers[4]+Vector2(40,0))
	sprite("druid",centers[5]-Vector2(40,0))
	sprite("marten",centers[5]+Vector2(40,0),Color("858d79"))
	feedback.draw(self,Vector2.ZERO,font)
	feedback.draw_channel(self,centers[5]-Vector2(40,0),centers[5]+Vector2(40,0),fposmod(clock,3.0),Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
