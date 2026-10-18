extends SceneTree
# Keep the redrawn source's colors/edges; no palette flattening or half-size bake.
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Pass redrawn source PNG path")
		quit(1)
		return
	var image=Image.load_from_file(args[0])
	if image==null:
		quit(1)
		return
	image.convert(Image.FORMAT_RGB8)
	var source_size=image.get_size()
	image.resize(2900,1650,Image.INTERPOLATE_NEAREST)
	var path=args[1] if args.size()>1 else "res://assets/pixel-ruins-background-v3.webp"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if image.save_webp(path,false)!=OK:
		quit(1)
		return
	var decoded=Image.load_from_file(path)
	decoded.convert(Image.FORMAT_RGB8)
	if decoded.get_data()!=image.get_data():
		push_error("Lossless background verification failed")
		quit(1)
		return
	print("BACKGROUND PACK PASS: source ",source_size," -> world grid ",image.get_size()," / lossless pixels verified / no new detail invented by resampling")
	quit()
