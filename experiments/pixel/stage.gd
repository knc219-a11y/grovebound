extends Node2D
var background = preload("res://assets/pixel-ruins-background-v1.png")
var sheet: Texture2D
var idle: Texture2D
var elapsed = 0.0
var phase = 0.0
var travel = 0.0
var face = 1.0
var moving = false
func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sheet = load("res://assets/boar-pixel-walk.png")
	idle = load("res://assets/boar-pixel-idle.png")
func _process(dt):
	elapsed += dt
	moving = elapsed>0.6
	face = 1.0 if elapsed<2.4 else -1.0
	if moving:
		var distance = 14.4/0.85*dt
		travel += distance*face
		phase = fposmod(phase+distance/14.4,1.0)
	queue_redraw()
func sprite(canvas: Node2D, p: Vector2, scale_value: float, facing: float, walking: bool, tint: Color=Color.WHITE):
	canvas.draw_set_transform(p.round(),0,Vector2(facing,1)*scale_value)
	if walking:
		var index = int(phase*8)%8
		canvas.draw_texture_rect_region(sheet,Rect2(-48,-62,96,72),Rect2(index%4*96,int(index/4)*72,96,72),tint)
	else:
		canvas.draw_texture_rect(idle,Rect2(-48,-62,96,72),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)
func shadow(p: Vector2):
	draw_rect(Rect2(p+Vector2(-18,-2),Vector2(36,4)),Color(0.03,0.03,0.04,0.45))
func _draw():
	draw_texture_rect(background,Rect2(0,0,720,405),false)
	var p = Vector2(345+travel,250).round()
	shadow(p)
	sprite(self,p,1,face,moving)
	shadow(Vector2(550,225))
	sprite(self,Vector2(550,225),1,-1,false,Color(0.82,0.78,0.75,1))
