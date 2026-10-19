extends Control
# Independent scales per metric prevent damage from hiding healing/mitigation.
var values={}
var maximums={}
func _draw():
	var font=get_theme_font("font")
	var keys=["damage","healing","mitigation"]
	var names=["피해","회복","경감"]
	var colors=[Color("d79b79"),Color("a5cb8c"),Color("83b9cb")]
	for i in 3:
		var y=17
		var x=i*306
		var amount=float(values.get(keys[i],0))
		var ratio=amount/maxf(1,float(maximums.get(keys[i],0)))
		draw_string(font,Vector2(x,y),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,colors[i])
		draw_rect(Rect2(x+48,y-10,164,8),Color("17211c"))
		draw_rect(Rect2(x+48,y-10,164*clampf(ratio,0,1),8),colors[i])
		draw_string(font,Vector2(x+222,y),str(roundi(amount)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e0d5bb"))
