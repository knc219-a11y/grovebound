extends "res://main.gd"
# Production UI in synthetic states. Never reads or writes the player's save.
@export var screen="inventory"
func load_game(): pass
func persist_payload(_data): return not save_blocked
func _ready():
	super()
	set_process(false)
	var requested=OS.get_environment("GROVE_EQUIPMENT_SCREEN")
	if not requested.is_empty(): screen=requested
	prepare(self,screen)
	present(self,screen)
static func prepare(g,state="inventory"):
	g.screenshot_mode=true; g.mode="camp"; g.in_combat=false
	g.tutorial_done=true; g.unlocked=true; g.save_blocked=false
	g.expedition.clear(); g.hero_pending.clear()
	g.owned.clear(); g.squad.clear(); g.units.clear(); g.enemies.clear(); g.captures.clear()
	g.hero=g.Hero.fresh(); g.hero.level=18; g.hero.gold=2500; g.hero.xp=430
	g.campaign_progress={"version":1,"cleared":[]}; g.cleared_stages=[1,2,3,4,5]
	for i in 40: g.campaign_progress=g.Routes.completed(g.campaign_progress,g.Routes.coordinate(i/8+1,i%8+1))
	for kind in ["boar","fox","deer","turtle"]:
		var d=g.make_owned(kind,20); g.squad.append(d.id)
	var count=0 if state=="empty" else 1 if state=="one" else 36
	for i in count:
		var item=g.Hero.add_item(g.hero,g.Hero.CATALOG.keys()[i%9])
		item.enhance=i%6
	if count>=9:
		g.hero.equipped={"weapon":2,"armor":5,"charm1":7,"charm2":8}
	g.sync_hero(); g.clear_overlay()
	if state in ["loot","pending","no_drop"]:
		g.expedition.begin(g.owned,g.materials,false)
		g.expedition.baseline.hero=g.hero.duplicate(true)
		var candidate=g.hero.duplicate(true)
		if state!="no_drop":
			g.Hero.add_item(candidate,"grove_staff")
			g.Hero.add_item(candidate,"wind_charm")
		g.expedition.close(g.owned,g.materials,3,32,"길목 복원",[])
		g.mode="result"
		if state=="pending": g.hero_pending=candidate; g.save_blocked=true
		else: g.hero=candidate
static func present(g,state):
	if state in ["loot","pending","no_drop"]: g.show_run_report()
	elif state=="shop": g.HeroUI.show_page(g,3)
	elif state.begins_with("map"):
		g.map_theme=int(state.trim_prefix("map")); g.map_stage=8; g.map_difficulty="normal"; g.open_stage_select()
	else: g.HeroUI.show_page(g,1,9)
