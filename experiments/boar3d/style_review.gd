extends Node2D
var reference: Texture2D
var before: Texture2D
var after: Texture2D
var old_data
var new_data
var font
var time=0.0

func _ready():
	reference=load("res://assets/boar-stance-proposal.png")
	old_data=JSON.parse_string(FileAccess.get_file_as_string("res://experiments/boar3d/frames_blockout.json"))
	new_data=JSON.parse_string(FileAccess.get_file_as_string("res://experiments/boar3d/frames.json"))
	before=load(old_data.texture)
	after=load(new_data.texture)
	font=load("res://assets/Korean.ttf")

func _process(dt):
	time+=dt
	queue_redraw()

func draw_frame(texture,data,p,height):
	var index=int(fposmod(time/data.cycle_seconds,1.0)*data.count)%int(data.count)
	var crop=Rect2(data.crop[0],data.crop[1],data.crop[2],data.crop[3])
	var scale_image=height/crop.size.y
	var ground=Vector2(data.ground[0],data.ground[1])
	var cell=Vector2(index%4*512,int(index/4)*384)
	draw_texture_rect_region(texture,Rect2(p-ground*scale_image,crop.size*scale_image),Rect2(cell+crop.position,crop.size))

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(50,70),"GROVEBOUND / 원화 기준 3D 외형 보정",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("eaf0d5"))
	var titles=["기준 · 확정 원화","이전 · 도형 조합","수정 · 연결 표면과 곡선"]
	for i in range(3):
		var p=Vector2(240+i*480,530)
		draw_rect(Rect2(p+Vector2(-220,-390),Vector2(440,510)),Color("243c33"))
		draw_string(font,p+Vector2(-195,-335),titles[i],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("eaf0d5"))
		draw_set_transform(p,0,Vector2(1,0.18))
		draw_circle(Vector2.ZERO,118,Color(0,0,0,0.13))
		draw_set_transform(Vector2.ZERO)
		if i==0:
			var width=220.0*1450.0/877.0
			draw_texture_rect_region(reference,Rect2(p+Vector2(-width/2,-220),Vector2(width,220)),Rect2(55,90,1450,877))
		elif i==1: draw_frame(before,old_data,p,220)
		else: draw_frame(after,new_data,p,220)
	draw_string(font,Vector2(50,735),"몸통·목·다리를 하나의 표면으로 연결 / 귀·엄니 곡선 / 같은 보행을 16장으로 출력",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d6dfbf"))
