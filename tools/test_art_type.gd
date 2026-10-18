extends SceneTree
func _initialize():
	var failures=[]
	for name in ["Galmuri11","Galmuri11-Bold"]:
		var font=load("res://assets/fonts/"+name+".res")
		if not font is FontFile:
			failures.append(name+" load")
			continue
		for point in range(0xAC00,0xD7A4):
			if not font.has_char(point):
				failures.append(name+" Hangul syllable coverage")
				break
		for letter in "GROVEBOUND0123456789%+·[]":
			if not font.has_char(letter.unicode_at(0)): failures.append(name+" UI symbol "+letter)
		if font.get_string_size("동료 편성 · 회복 123",HORIZONTAL_ALIGNMENT_LEFT,-1,18).x<=0:
			failures.append(name+" shaping")
	var texture=load("res://assets/maps/greenwater-beginner-v3.webp")
	if texture==null or texture.get_size()!=Vector2(2900,1650): failures.append("background size")
	else:
		var image=texture.get_image()
		if image.is_invisible(): failures.append("opaque background")
	if failures.is_empty():
		print("ART TYPE PASS: packaged fonts, full Hangul syllables, UI symbols, text shaping, background dimensions/visibility")
		quit()
	else:
		push_error(str(failures))
		quit(1)
