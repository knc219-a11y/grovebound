extends "res://animation/special_review.gd"
# No player files are read or written, including transaction calls during battle setup.
func persist_payload(_data): return true
func _ready():
	if screen=="battle":
		super()
		return
	# Skip special_review's three-material fixture; run the real two-material transaction.
	screenshot_mode=true
	load_game()
	# main builds fonts/textures/HUD while overridden load/save keep this isolated.
	super()
	owned.clear()
	squad.clear()
	mode="camp"
	for kind in ["boar","fox","deer"]:
		var d=Loot.roll_special(Loot.roll(kind,40,loot_rng,3),kind,loot_rng)
		d.level=50
		d.special.state="ready"
		d.special.element="water"
		d.special.unique=Special.choices(kind).keys()[1]
		make_owned(kind,50,d)
	owned[0].favorite=true
	owned[0].legacy_options=true
	owned[0].options=[{"key":"power","value":8}]
	squad=[owned[0].id]
	var main_id=owned[0].id
	var support_id=owned[1].id
	if screen=="materials": EvolutionUI.show_page(self,main_id)
	elif screen=="confirm": EvolutionUI.show_confirmation(self,main_id,support_id)
	else:
		var plan=Evolution.preview(owned,squad,main_id,support_id)
		commit_evolution(main_id,support_id,plan.materials)
		if screen=="choice": EvolutionUI.show_choice(self,main_id,"barrier")
		if screen=="detail": commit_evolution_choice(main_id,"barrier",find_owned(main_id).duplicate(true))
func setup_battle(phase):
	super(phase)
	for u in units:
		u.data.star=5
		u.data.level=50
		var ability={"boar":"barrier","turtle":"guard","marten":"basic","wolf":"execute","bat":"skill","fox":"reach","deer":"potency"}[u.data.kind]
		u.data.special.evolution={"version":1,"state":"ready","ability":ability}
		u.maxhp=max_hp(u.data)
		u.hp=u.maxhp*0.6
	message="5성 진화 · 기존 강화 스킬과 진화 능력 · 격리 QA"
