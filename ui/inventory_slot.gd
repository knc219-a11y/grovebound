extends Button
const UI=preload("res://ui/grove_ui.gd")
const Loot=preload("res://companion_loot.gd")
var record={}
var portrait:Texture2D
var caption=""
var resource_count=-1
var selected=false
func _draw():
	var font=get_theme_font("font")
	var color=Loot.color(record) if resource_count<0 else UI.GREEN
	if selected: draw_style_box(UI.frame(Color(0,0,0,0),color,2),Rect2(1,1,size.x-2,size.y-2))
	UI.medallion(self,Vector2(size.x/2,49),26,color)
	if resource_count>=0:
		draw_string(font,Vector2(10,20),"성장 재료",HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
		UI.leaf(self,Vector2(size.x/2,49),12,UI.GREEN)
		draw_string(font,Vector2(10,95),"×"+str(resource_count),HORIZONTAL_ALIGNMENT_LEFT,-1,19,UI.PAPER)
	elif portrait!=null:
		var ratio=minf(73.0/portrait.get_width(),41.0/portrait.get_height())
		var extent=portrait.get_size()*ratio
		draw_texture_rect(portrait,Rect2(Vector2(size.x/2,49)-extent/2,extent),false)
		draw_string(font,Vector2(10,20),Loot.title(record),HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
		draw_string(font,Vector2(10,96),caption+" Lv."+str(record.level),HORIZONTAL_ALIGNMENT_LEFT,size.x-15,14,UI.PAPER)
		if record.get("favorite",false): UI.leaf(self,Vector2(size.x-13,13),4,UI.GREEN)
