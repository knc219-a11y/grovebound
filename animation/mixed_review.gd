extends "res://animation/campaign_review.gd"
@export var output="res://docs/mixed-selector.png"
func _ready():
	super()
	if view=="mixed":
		start_stage(false,region)
		player.pos=Vector2(930,820) if region==1 else Vector2(2130,820)
		for i in units.size(): units[i].pos=player.pos+Vector2(-55-i*22,45)
		screenshot_mode=true
		message=""; message_time=0
	capture.call_deferred()
func capture():
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image=get_viewport().get_texture().get_image()
	assert(image.save_png(output)==OK)
	print("MIXED REVIEW SAVED: "+output)
	get_tree().quit()
