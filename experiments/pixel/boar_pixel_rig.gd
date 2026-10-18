extends "res://animation/boar_cutout.gd"
func _init(_legacy=null):
	super(_legacy)
	body_bob = 0.0
	atlas = load("res://assets/boar-pixel-parts-v1.png")
	body = atlas
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/pixel/parts.json"))
	var rects = []
	for frame in data.frames:
		var r = frame.region
		rects.append(Rect2(r[0],r[1],r[2],r[3]))
	body_region = rects[0]
	regions = [rects[1],rects[2]]
	legs[0].root.x = -28
	legs[0].foot.x = -25
	legs[2].root.x = -45
	legs[2].foot.x = -49
	rebuild_uvs()
