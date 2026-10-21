extends "res://animation/campaign_map_review.gd"
@export var review_menu=false
@export var review_map=false
func _ready():
	theme=5; view="boss"
	super()
	for d in owned:
		d.star=3; d.level=24; d.grade="epic"
	var d=owned[0]
	d.star=4; d.level=15; d.grade="special"
	d.special={"version":1,"state":"ready","element":"earth","unique":"guard","affixes":[{"key":"skill_haste","value":8},{"key":"power","value":6}]}
	for i in units.size(): units[i]=make_unit(owned[i],units[i].pos)
	if review_menu or review_map:
		tutorial_done=true
		show_camp()
		for t in range(1,6):
			for s in range(1,9): campaign_progress=Routes.completed(campaign_progress,Routes.coordinate(t,s))
		make_owned("bat",20)
		if review_map:
			map_theme=4; map_stage=1; open_stage_select()
		else: open_game_menu()
		screenshot_mode=true
