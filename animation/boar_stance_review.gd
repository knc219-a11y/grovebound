extends Node2D
# Static art review only. The proposal is intentionally not wired into gameplay.
const CurrentRig = preload("res://animation/boar_rig_v2.gd")
var current
var proposal: Texture2D
var proposal_region=Rect2(0,0,1,1)
var font
var frames=0

func _ready():
	current=CurrentRig.new(load("res://assets/boar-parts.png"))
	proposal=load("res://assets/boar-stance-proposal.png")
	proposal_region=Rect2(55,90,1450,877) # Solid silhouette, excluding faint alpha padding.
	font=load("res://assets/Korean.ttf")
	queue_redraw()

func _process(_dt):
	frames+=1
	if frames==3 and "--save-stance-review" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/boar-stance-review.png")
		get_tree().quit()

func _draw():
	draw_rect(Rect2(0,0,1440,810),Color("182a27"))
	draw_string(font,Vector2(55,70),"GROVEBOUND / 멧돼지 기본 자세 검토",HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("eaf0d5"))
	for i in range(2):
		var p=Vector2(360+i*720,575)
		draw_rect(Rect2(p+Vector2(-330,-430),Vector2(660,550)),Color("243c33"))
		draw_string(font,p+Vector2(-280,-375),"현재 · 분리된 다리 조립" if i==0 else "수정안 · 몸통에서 이어지는 네 다리",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("eaf0d5"))
		draw_line(p+Vector2(-255,0),p+Vector2(255,0),Color("708976"),2,true)
		if i==0:
			current.draw(self,p,260,1,Color.WHITE,{})
		else:
			var height=260.0
			var width=height*proposal_region.size.x/proposal_region.size.y
			draw_texture_rect_region(proposal,Rect2(p+Vector2(-width/2.0,-height),Vector2(width,height)),proposal_region)
		draw_string(font,p+Vector2(-270,70),"정지 자세 / 같은 바닥 높이 / 움직임 미적용",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("bfcdb4"))
	draw_string(font,Vector2(55,760),"검토: 어깨 아래 앞다리 · 엉덩이와 이어진 뒷다리 · 짧은 다리와 발 접지",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("d6dfbf"))
