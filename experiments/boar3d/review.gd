extends Node2D
const Model=preload("res://experiments/boar3d/boar_model.gd")
const PaintedRig=preload("res://animation/boar_rig.gd")
var viewport: SubViewport
var model
var painted
var sheet: Texture2D
var metadata
var font
var time=0.0
var actor={"walk":true,"hp":100.0,"rig_move":1.0,"rig_phase":0.0}

func _ready():
	painted=PaintedRig.new()
	metadata=JSON.parse_string(FileAccess.get_file_as_string("res://experiments/boar3d/frames.json"))
	sheet=load(metadata.texture)
	font=load("res://assets/Korean.ttf")
	viewport=SubViewport.new()
	viewport.size=Vector2i(512,384)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d=Viewport.MSAA_4X
	add_child(viewport)
	model=Model.new()
	viewport.add_child(model)

func _process(dt):
	time+=dt
	actor.rig_phase=fposmod(time/Model.CYCLE*TAU,TAU)
	model.set_pose(time)
	queue_redraw()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(50,70),"GROVEBOUND / 3D 애니메이션 → 2D 프레임 실험",HORIZONTAL_ALIGNMENT_LEFT,-1,31,Color("eaf0d5"))
	var titles=["기존 · 2D 원화 8장","실험 · 3D 실시간","실험 · 3D 출력 16장"]
	for i in range(3):
		var p=Vector2(240+i*480,530)
		draw_rect(Rect2(p+Vector2(-220,-390),Vector2(440,510)),Color("243c33"))
		draw_string(font,p+Vector2(-195,-335),titles[i],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("eaf0d5"))
		draw_set_transform(p,0,Vector2(1,0.18))
		draw_circle(Vector2.ZERO,118,Color(0,0,0,0.13))
		draw_set_transform(Vector2.ZERO)
		if i==0:
			painted.draw(self,p,210,1,Color.WHITE,actor)
		else:
			var crop=Rect2(metadata.crop[0],metadata.crop[1],metadata.crop[2],metadata.crop[3])
			var scale_image=210.0/crop.size.y
			var ground=Vector2(metadata.ground[0],metadata.ground[1])
			if i==1:
				var image_ground=crop.position+ground
				draw_texture_rect(viewport.get_texture(),Rect2(p-image_ground*scale_image,Vector2(512,384)*scale_image),false)
			else:
				var index=int(fposmod(time/Model.CYCLE,1.0)*metadata.count)%int(metadata.count)
				var cell_origin=Vector2(index%4*512,int(index/4)*384)
				draw_texture_rect_region(sheet,Rect2(p-ground*scale_image,crop.size*scale_image),Rect2(cell_origin+crop.position,crop.size))
		draw_string(font,p+Vector2(-190,80),"같은 주기 · 0.8초 / 보행 비교",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("bfcdb4"))
	draw_string(font,Vector2(50,735),"3D 외형은 움직임 검토용 기본 모델입니다. 최종 그림체를 재현한 버전은 아닙니다.",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d6dfbf"))
