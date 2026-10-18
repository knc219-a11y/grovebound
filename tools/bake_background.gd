extends SceneTree
# Native image pipeline: nearest sampling plus a constrained earth/stone palette.
const PALETTE=["121615","181d1b","1e2421","252b27","2c322d","343a34","3c423b","454a42","20201c","292922","333229","3d3b30","474435","514d3c","5a5543","655f4b","181c1f","202529","293034","343b3e","41484a","4d5353","5c6160","6b6e6a","1b221a","222c20","2b3525","35412c","414c34","4f593e","60674c","73795c","261e19","32271f","3e3025","4b392b","594432","66513a","735d45","826b50","342820","443226","57402e","6b5137","816440","99774b","b58b50","cca35f","5a3620","754523","965b29","b87830","d49c43","e6bf6a","f1d38f","fae3b2","171915","1e211b","292d23","34382d","414337","4e5143","5b5d4d","6a6a59"]
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass source PNG path")
		quit(1)
		return
	var image=Image.load_from_file(args[0])
	if image==null:
		quit(1)
		return
	image.convert(Image.FORMAT_RGB8)
	image.resize(1450,825,Image.INTERPOLATE_NEAREST)
	var palette=[]
	for hex in PALETTE: palette.append(Color(hex))
	var cache={}
	for y in image.get_height():
		for x in image.get_width():
			var c=image.get_pixel(x,y)
			var key=(c.r8>>3)*1024+(c.g8>>3)*32+(c.b8>>3)
			if not cache.has(key):
				var sample=Vector3(((c.r8>>3)*8+4)/255.0,((c.g8>>3)*8+4)/255.0,((c.b8>>3)*8+4)/255.0)
				var nearest=palette[0]
				var distance=INF
				for candidate in palette:
					var delta=sample-Vector3(candidate.r,candidate.g,candidate.b)
					var d=delta.x*delta.x+delta.y*delta.y*1.4+delta.z*delta.z
					if d<distance:
						distance=d
						nearest=candidate
				cache[key]=nearest
			image.set_pixel(x,y,cache[key])
	var out="res://assets/pixel-ruins-background-v2.png"
	if image.save_png(out)!=OK:
		quit(1)
		return
	print("BACKGROUND BAKE PASS: ",image.get_size()," / 64-color earth palette / nearest grid")
	quit()
