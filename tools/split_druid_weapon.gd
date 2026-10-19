extends SceneTree
# Extract the existing staff without redrawing its approved pixels/palette.
# The palm stays in the body; the weapon is rigid and separately mounted.
func _initialize():
	var original=Image.load_from_file("res://assets/party-pixel/druid.png")
	original.convert(Image.FORMAT_RGBA8)
	var body=original.duplicate()
	var weapon=Image.create(original.get_width(),original.get_height(),false,Image.FORMAT_RGBA8)
	for y in original.get_height():
		for x in original.get_width():
			var threshold=31 if y<30 else 32 if y<40 else 29 if y<55 else 27
			var palm=y>=34 and y<=39 and x<=34
			if x>=threshold and not palm:
				weapon.set_pixel(x,y,original.get_pixel(x,y))
				body.set_pixel(x,y,Color.TRANSPARENT)
	assert(body.save_png("res://assets/party-pixel/druid-body-v2.png")==OK)
	assert(weapon.save_png("res://assets/party-pixel/druid-staff-v2.png")==OK)
	# Disjoint layers reproduce every original pixel exactly.
	for y in original.get_height():
		for x in original.get_width():
			var a=body.get_pixel(x,y)
			var b=weapon.get_pixel(x,y)
			assert(a.a==0 or b.a==0)
			var rebuilt=a if a.a>0 else b
			var source=original.get_pixel(x,y)
			assert(is_equal_approx(rebuilt.a,source.a))
			# Transparent PNG pixels may retain hidden RGB values after decoding.
			if source.a>0: assert(rebuilt.is_equal_approx(source))
	print("PASS weapon split: exact disjoint reconstruction; original preserved")
	quit()
