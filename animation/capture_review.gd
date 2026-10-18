extends "res://animation/pixel_gameplay_preview.gd"
# Uses real runtime drawing, with no player save access.
func _ready():
	super()
	start_stage(false)
	screenshot_mode=true
	player.pos=Vector2(1100,740)
	units.clear()
	enemies.clear()
	captures.clear()
	var kinds=["boar","wolf","marten","fox","deer","turtle"]
	for i in kinds.size():
		captures.append({"kind":kinds[i],"pos":Vector2(1160+(i%3)*140,780+(i/3)*135),"level":1})
