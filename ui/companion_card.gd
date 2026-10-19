extends Button
const Loot=preload("res://companion_loot.gd")
var rarity="common"
const UI=preload("res://ui/grove_ui.gd")
var portrait: Texture2D
var companion_name="빈자리"
var role="교감으로 합류"
var hp=0.0
var max_hp=1.0
var cooldown=0.0
var cooldown_duration=10.0
var slot=1
var occupied=false
func configure(texture,caption,job,health,maximum,wait,quality="common",wait_total=10.0):
	cooldown_duration=maxf(0.01,wait_total)
	rarity=quality
	portrait=texture
	companion_name=caption
	role=job
	hp=health
	max_hp=maxf(1,maximum)
	cooldown=wait
	occupied=texture!=null
	queue_redraw()
func _draw():
	var font=get_theme_font("font")
	var width=size.x
	var accent=Loot.COLORS.get(rarity,Loot.COLORS.common)
	if occupied:
		draw_line(Vector2(10,3),Vector2(width-10,3),accent,2,false)
		UI.medallion(self,Vector2(width/2,53),23,accent)
	var color=UI.PAPER if hp>0 or not occupied else Color("b6937b")
	draw_colored_polygon(PackedVector2Array([Vector2(8,9),Vector2(24,9),Vector2(29,17),Vector2(24,25),Vector2(8,25),Vector2(4,17)]),UI.INK)
	draw_string(font,Vector2(13,22),str(slot),HORIZONTAL_ALIGNMENT_LEFT,-1,14,UI.BRONZE)
	draw_string(font,Vector2(34,23),companion_name,HORIZONTAL_ALIGNMENT_LEFT,width-40,17,color)
	if occupied:
		var ratio=minf(78.0/portrait.get_width(),34.0/portrait.get_height())
		var extent=Vector2(portrait.get_size())*ratio
		draw_texture_rect(portrait,Rect2(Vector2(width/2,53)-extent/2,extent),false,Color.WHITE if hp>0 else Color("727b6b"))
		if cooldown>0:
			draw_circle(Vector2(width/2,53),21,Color(0.06,0.08,0.07,0.65))
			draw_arc(Vector2(width/2,53),23,-PI/2,-PI/2+TAU*clampf(cooldown/cooldown_duration,0,1),24,accent,2,false)
			draw_string(font,Vector2(width/2-9,61),str(ceili(cooldown)),HORIZONTAL_ALIGNMENT_LEFT,-1,24,UI.PAPER)
		var bar=Rect2(10,77,width-20,7)
		draw_rect(bar,UI.INK)
		bar.size.x*=clampf(hp/max_hp,0,1)
		draw_rect(bar,UI.GREEN if hp/max_hp>0.3 else Color("c48a6c"))
		var state="쓰러짐" if hp<=0 else ("대기" if cooldown>0 else "준비")
		draw_string(font,Vector2(10,102),role+" · "+state,HORIZONTAL_ALIGNMENT_LEFT,-1,13,UI.MUTED)
		draw_string(font,Vector2(width-42,102),str(roundi(hp/max_hp*100))+"%",HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
	else:
		draw_string(font,Vector2(16,62),"+",HORIZONTAL_ALIGNMENT_LEFT,-1,27,UI.BRONZE)
		draw_string(font,Vector2(10,101),role,HORIZONTAL_ALIGNMENT_LEFT,-1,13,UI.MUTED)
