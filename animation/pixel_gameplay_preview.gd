extends "res://main.gd"
# Uses the real combat loop; keep preview runs isolated from player save data.
func _ready():
	super()
	demo_scene()
func load_game():
	pass
func save_game():
	return super()
func persist_payload(_data):
	# Transactional actions bypass save_game; previews must isolate those as well.
	return not save_blocked
