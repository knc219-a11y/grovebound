extends "res://main.gd"
# Synthetic production UI fixture. Never reads or writes the user's save.
@export var screen="full"
func load_game(): pass
func persist_payload(_data): return not save_blocked
func _ready():
	var requested=OS.get_environment("GROVE_ROSTER_SCREEN")
	if requested in ["full","empty","filtered","field","partial","selected"]: screen=requested
	super()
	set_process(false)
	populate(self)
	if screen=="empty":
		owned.clear()
		squad.clear()
	elif screen=="filtered": roster_kind_filter="bat"
	elif screen=="selected": roster_selected_id=owned[8].id
	elif screen=="field":
		mode="stage"
		units.clear()
		for id in squad: units.append(make_unit(find_owned(id),Vector2(500,500)))
	elif screen=="partial": squad=squad.slice(0,2)
	open_roster()

static func populate(g):
	g.mode="camp"
	g.in_combat=false
	g.owned.clear()
	g.squad.clear()
	g.next_id=1
	g.discovered.clear()
	g.loot_rng.seed=20261021
	g.tutorial_done=true
	g.unlocked=true
	g.materials=369
	g.cleared_stages=[1,2,3]
	g.campaign_progress=g.Routes.normalize({"cleared_stages":[1,2,3]})
	var kinds=["boar","marten","fox","turtle","deer","wolf","bat"]
	for i in 30:
		var kind=kinds[i%kinds.size()]
		var star=i%6+1
		var level=mini(7+i,g.Loot.max_level({"star":mini(star,3)}))
		var data=g.Loot.roll(kind,level,g.loot_rng,mini(star,3))
		if star>=4:
			data=g.Loot.roll_special(data,kind,g.loot_rng)
			data.star=star
			data.level=15 if star==4 else (50 if star==5 else 60)
			data.special.state="ready"
			data.special.element=["water","earth","wind","fire"][i%4]
			data.special.unique=g.Special.choices(kind).keys()[0]
			if star>=5: data.special.evolution={"version":1,"state":"ready","ability":g.Special.evolution_choices(kind).keys()[0],"enhanced":star==6}
		data.favorite=i%5==0
		g.make_owned(kind,data.level,data)
		if i<6: g.squad.append(g.owned[-1].id)



