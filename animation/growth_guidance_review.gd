extends "res://main.gd"
# Synthetic production-screen fixture: no player file reads or writes.
@export var screen="goal"
func load_game(): pass
func persist_payload(_data): return not save_blocked
func _ready():
	var requested=OS.get_environment("GROVE_GROWTH_SCREEN")
	if requested in ["goal","materials","synthesis","completed","boss","closed","open"]: screen=requested
	super()
	set_process(false)
	populate(self,screen)
	show_screen(self,screen)

static func progress(g,count):
	g.campaign_progress={"version":1,"cleared":[]}
	for i in count:
		g.campaign_progress=g.Routes.completed(g.campaign_progress,g.Routes.coordinate(i/8+1,i%8+1))

static func populate(g,state="goal"):
	g.mode="camp"; g.in_combat=false; g.tutorial_done=true; g.unlocked=true
	g.owned.clear(); g.squad.clear(); g.units.clear(); g.next_id=1
	g.materials=0; g.loot_rng.seed=20261021
	progress(g,40 if state=="completed" else 39)
	for i in 3:
		var kind=["boar","fox","deer"][i]
		var data=g.Loot.roll(kind,40,g.loot_rng,3)
		if state in ["goal","boss","completed","closed","open"] and i==0:
			data=g.Loot.roll_special(data,kind,g.loot_rng)
			data.level=15; data.special.state="ready"; data.special.element="water"
			data.special.unique=g.Special.choices(kind).keys()[0]
		if state=="materials" and i==0: data.level=31; data.xp=0
		g.make_owned(kind,data.level,data)
		g.squad.append(g.owned[-1].id)

static func show_screen(g,state):
	match state:
		"closed","open":
			g.depart_route(g.Routes.coordinate(5,8))
			g.clear_overlay()
			g.player.pos=g.trail.points[-1]+Vector2(-200,20)
			for e in g.enemies:
				if not e.boss: e.hp=0
				else:
					e.active=true; e.intro=0.0; e.wind=0.0
					e.cycle_open=6.0 if state=="open" else 0.0
			for i in g.units.size(): g.units[i].pos=g.player.pos+Vector2(30-i*30,i*25-35)
			g.update_hud(); g.queue_redraw()
		"materials": g.preview_target_training(g.owned[0].id,40)
		"synthesis": g.show_synthesis()
		"boss": g.map_difficulty="normal"; g.map_theme=5; g.map_stage=8; g.open_stage_select()
		_: g.map_difficulty="normal"; g.map_theme=0; g.open_stage_select()
