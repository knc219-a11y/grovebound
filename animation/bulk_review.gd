extends "res://animation/pixel_gameplay_preview.gd"
var view="flow"
var phase=0
func _ready():
	super()
	expedition.clear()
	show_camp()
	owned.clear()
	squad.clear()
	discovered.clear()
	materials=10
	for kind in ["boar","turtle","fox","deer","marten","wolf","boar"]:
		make_owned(kind,2)
	squad=[owned[0].id,owned[1].id]
	owned[2].favorite=true
	open_roster()
	if view in ["selection","confirmation"]:
		show_bulk_release(true)
		toggle_bulk_release(owned[3].id,true)
		toggle_bulk_release(owned[4].id,true)
		if view=="confirmation": confirm_bulk_release()
	if view=="dropdown":
		resume_game()
		dropdown.open()
func _process(dt):
	if view=="flow":
		if clock>1 and phase==0:
			phase=1
			show_bulk_release(true)
			toggle_bulk_release(owned[3].id,true)
			toggle_bulk_release(owned[4].id,true)
		elif clock>2.8 and phase==1:
			phase=2
			confirm_bulk_release()
		elif clock>4.6 and phase==2:
			phase=3
			commit_bulk_release(bulk_selection.duplicate())
	super(dt)
