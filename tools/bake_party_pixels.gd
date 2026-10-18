extends SceneTree
# Native Godot image pipeline. Sources are external imagegen originals.
const PALETTE = ["181619","272023","362b2b","443532","51413b","625149","746157","897569","9e8978","b29e88","c9b69b","e0d2b2","363b40","51575b","6e7779","e4e3d4","252e25","354333","4c5c43","718063","98a18a","55352d","754635","985d3f","ba8254","34423c","4a5b4e","6a7863","8f8067","ad9a75","b29a82","d3b79a"]
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass a source manifest JSON path")
		quit(1)
		return
	var records = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var manifest = {"palette": PALETTE, "sprites": []}
	DirAccess.make_dir_recursive_absolute("res://assets/party-pixel")
	for entry in records:
		var source = Image.load_from_file(entry.source)
		if source == null:
			quit(1)
			return
		source.convert(Image.FORMAT_RGBA8)
		# Remove low-opacity source halos before determining the tight bounds.
		for y in source.get_height():
			for x in source.get_width():
				if source.get_pixel(x,y).a < 0.5: source.set_pixel(x,y,Color.TRANSPARENT)
		var bounds = source.get_used_rect()
		var img = source.get_region(bounds)
		img.resize(maxi(1,roundi(float(bounds.size.x)*entry.height/bounds.size.y)),entry.height,Image.INTERPOLATE_NEAREST)
		for y in img.get_height():
			for x in img.get_width():
				var c = img.get_pixel(x,y)
				if c.a < 0.5: continue
				var best = Color(PALETTE[0])
				var distance = INF
				for hex in PALETTE:
					var candidate = Color(hex)
					var d = Vector3(c.r,c.g,c.b).distance_squared_to(Vector3(candidate.r,candidate.g,candidate.b))
					if d < distance:
						distance = d
						best = candidate
				img.set_pixel(x,y,best)
		var path = "res://assets/party-pixel/"+entry.kind+".png"
		if img.save_png(path) != OK:
			quit(1)
			return
		manifest.sprites.append({"kind":entry.kind,"texture":path,"width":img.get_width(),"height":img.get_height()})
		print(entry.kind, " ", img.get_size())
	var out = FileAccess.open("res://assets/party-pixel/manifest.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(manifest,"\t")+"\n")
	quit()
