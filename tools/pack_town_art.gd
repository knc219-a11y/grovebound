extends SceneTree
# Asset packing only: keep generated colors/alpha; crop transparent cell margins,
# nearest resize to the actual game footprint and verify lossless WebP roundtrip.
func save_verified(image,path):
	if image.save_webp(path,false)!=OK:
		push_error("Cannot save "+path)
		quit(1)
	var decoded=Image.load_from_file(path)
	decoded.convert(image.get_format())
	assert(decoded.get_data()==image.get_data(),"Lossless pixel/alpha roundtrip")
func _initialize():
	var args=OS.get_cmdline_user_args()
	if args.size()!=3:
		push_error("Pass ground, 3-cell cottages, 3-cell props PNG paths")
		quit(1)
		return
	var image=Image.load_from_file(args[0])
	image.convert(Image.FORMAT_RGB8)
	image.resize(1800,1100,Image.INTERPOLATE_NEAREST)
	save_verified(image,"res://assets/town/leafshade-ground-v1.webp")
	for sheet in 2:
		image=Image.load_from_file(args[sheet+1])
		image.convert(Image.FORMAT_RGBA8)
		assert(not image.is_invisible())
		save_verified(image,"res://assets/town/"+("cottages-source-v1.webp" if sheet==0 else "props-source-v1.webp"))
		for i in 3:
			var x=roundi(image.get_width()*i/3.0)
			var end=roundi(image.get_width()*(i+1)/3.0)
			var cell=image.get_region(Rect2i(x,0,end-x,image.get_height()))
			var used=cell.get_used_rect()
			assert(used.size.x>0 and used.size.y>0)
			cell=cell.get_region(used)
			var width=272 if sheet==0 else [80,52,70][i]
			cell.resize(width,roundi(width*used.size.y/float(used.size.x)),Image.INTERPOLATE_NEAREST)
			var path="res://assets/town/"+("cottage-" if sheet==0 else "prop-")+str(i)+"-v1.webp"
			save_verified(cell,path)
			print("PACK ",path," ",cell.get_size()," transparent corners ",cell.get_pixel(0,0).a)
	print("PASS town assets: nearest packing, lossless colors and alpha")
	quit()
