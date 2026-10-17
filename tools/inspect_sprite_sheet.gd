extends SceneTree
# Read-only image analysis. Writes source rectangles, never edits painted pixels.
func _initialize():
	var options={"source":"res://assets/boar-walk-sheet.png","out":"res://animation/boar_walk_frames.json","columns":"4","rows":"2","layout":"grid"}
	for arg in OS.get_cmdline_user_args():
		var pair=arg.trim_prefix("--").split("=",true,1)
		if pair.size()==2: options[pair[0]]=pair[1]
	var image=Image.load_from_file(options.source)
	if image==null or image.is_empty(): fail("Cannot read source"); return
	var columns=int(options.columns)
	var rows=int(options.rows)
	if columns<=0 or rows<=0: fail("Invalid grid"); return
	if options.layout=="components":
		inspect_components(image,options,columns,rows)
		return
	var frames=[]
	var shortest=100000
	var tallest=0
	for row in range(rows):
		for column in range(columns):
			var cell=Rect2i(column*image.get_width()/columns,row*image.get_height()/rows,image.get_width()/columns,image.get_height()/rows)
			var left=cell.end.x
			var top=cell.end.y
			var right=-1
			var bottom=-1
			for y in range(cell.position.y,cell.end.y):
				for x in range(cell.position.x,cell.end.x):
					if image.get_pixel(x,y).a>=0.5:
						left=mini(left,x); right=maxi(right,x)
						top=mini(top,y); bottom=maxi(bottom,y)
			if right<left: fail("Empty cell %d" % frames.size()); return
			if left<=cell.position.x or right>=cell.end.x-1 or top<=cell.position.y or bottom>=cell.end.y-1:
				fail("Sprite touches a grid edge in cell %d; inspect layout before using" % frames.size()); return
			var width=right-left+1
			var height=bottom-top+1
			frames.append({"region":[left,top,width,height],"pivot":[width/2.0,height]})
			shortest=mini(shortest,height); tallest=maxi(tallest,height)
	if float(tallest)/shortest>1.20: fail("Frame height variation exceeds 20%; revise sheet or grid"); return
	var result={"texture":options.source,"columns":columns,"rows":rows,"normalized_height":100,"frames":frames,"alignment":"opaque alpha bounds; bottom-center; uniform displayed height"}
	var file=FileAccess.open(options.out,FileAccess.WRITE)
	if file==null: fail("Cannot write metadata"); return
	file.store_string(JSON.stringify(result,"\t")+"\n")
	print("ATLAS PASS: %d frames; heights %d..%d; metadata %s" % [frames.size(),shortest,tallest,options.out])
	quit(0)

func fail(message):
	push_error(message)
	quit(1)

func inspect_components(image,options,columns,rows):
	image.convert(Image.FORMAT_RGBA8)
	var pixels=image.get_data()
	var width=image.get_width()
	var height=image.get_height()
	var mask=PackedByteArray()
	mask.resize(width*height)
	for i in range(mask.size()): mask[i]=1 if pixels[i*4+3]>=128 else 0
	var regions=[]
	var directions=[-1,1,-width,width]
	for seed in range(mask.size()):
		if mask[seed]==0: continue
		mask[seed]=0
		var queue=PackedInt32Array([seed])
		var cursor=0
		var left=width
		var top=height
		var right=0
		var bottom=0
		while cursor<queue.size():
			var pixel=queue[cursor]
			cursor+=1
			var x=pixel%width
			var y=int(pixel/width)
			left=mini(left,x); right=maxi(right,x); top=mini(top,y); bottom=maxi(bottom,y)
			for direction in directions:
				if direction==-1 and x==0: continue
				if direction==1 and x==width-1: continue
				var neighbor=pixel+direction
				if neighbor>=0 and neighbor<mask.size() and mask[neighbor]==1:
					mask[neighbor]=0
					queue.append(neighbor)
		if queue.size()>1000:
			if left==0 or right==width-1 or top==0 or bottom==height-1:
				fail("Sprite touches image border"); return
			regions.append(Rect2i(left,top,right-left+1,bottom-top+1))
	if regions.size()!=columns*rows:
		fail("Expected %d complete sprites, found %d; review overlapping or detached artwork" % [columns*rows,regions.size()]); return
	regions.sort_custom(func(a,b):
		var row_a=int(a.get_center().y*rows/height)
		var row_b=int(b.get_center().y*rows/height)
		return a.position.x<b.position.x if row_a==row_b else row_a<row_b)
	var frames=[]
	var shortest=height
	var tallest=0
	for region in regions:
		frames.append({"region":[region.position.x,region.position.y,region.size.x,region.size.y],"pivot":[region.size.x/2.0,region.size.y]})
		shortest=mini(shortest,region.size.y); tallest=maxi(tallest,region.size.y)
	if float(tallest)/shortest>1.20: fail("Frame height variation exceeds 20%"); return
	var result={"texture":options.source,"columns":columns,"rows":rows,"normalized_height":100,"frames":frames,"alignment":"connected opaque silhouettes; bottom-center; uniform displayed height"}
	var file=FileAccess.open(options.out,FileAccess.WRITE)
	if file==null: fail("Cannot write metadata"); return
	file.store_string(JSON.stringify(result,"\t")+"\n")
	print("ATLAS PASS: %d connected frames; heights %d..%d; metadata %s" % [frames.size(),shortest,tallest,options.out])
	quit(0)
