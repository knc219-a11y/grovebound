extends SceneTree
# Package upstream TTF bytes unchanged into compressed, exportable FontFile resources.
func _initialize():
	for name in ["Galmuri11","Galmuri11-Bold"]:
		var source="res://.tools/font-sources/"+name+".ttf"
		var font=FontFile.new()
		font.data=FileAccess.get_file_as_bytes(source)
		font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
		if not font.has_char(0xAC00) or not font.has_char(0xD7A3):
			push_error("Font source does not contain Korean syllables")
			quit(1)
			return
		var result=ResourceSaver.save(font,"res://assets/fonts/"+name+".res",ResourceSaver.FLAG_COMPRESS)
		if result!=OK:
			quit(1)
			return
		print("FONT BUILD PASS: ",name," ",font.get_font_name())
	quit()
