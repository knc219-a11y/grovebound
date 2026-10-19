extends "res://animation/management_review.gd"
var page="inventory"
var moved=false
func _ready():
	super()
	discovered.clear()
	for d in owned:
		if not discovered.has(d.kind): discovered.append(d.kind)
	if page=="menu": open_game_menu()
	elif page=="collection": open_collection()
	elif page=="materials":
		inventory_category=1
		open_inventory()
	elif page=="dropdown":
		show_camp()
		dropdown.open()
	elif page=="camp": show_camp()
	else: open_inventory()
func _process(dt):
	if page=="flow" and clock>1.7 and not moved:
		moved=true
		open_collection()
	super(dt)
