extends "res://animation/pixel_gameplay_preview.gd"
@export var page=0
@export var combat=false
var elapsed=0.0
func _ready():
	super()
	owned.clear(); squad.clear(); enemies.clear(); captures.clear()
	hero=Hero.fresh(); hero.level=18; hero.gold=2500; hero.xp=430
	for key in Hero.SKILLS: hero.skills[key]=3 if key!="barrier" else 1
	for pair in [["oak_staff","weapon"],["bark_robe","armor"],["vitality_charm","charm1"],["stream_charm","charm2"]]:
		var item=Hero.add_item(hero,pair[0]); item.enhance=2; hero.equipped[pair[1]]=item.id
	Hero.add_item(hero,"grove_staff"); Hero.add_item(hero,"wind_charm")
	sync_hero(); tutorial_done=true
	for kind in ["boar","fox","deer","turtle"]:
		var d=make_owned(kind,20); squad.append(d.id)
	show_camp(); clear_overlay()
	if combat:
		start_stage(false)
		for e in enemies:
			e.hp=0
		spawn_enemy("boar",Vector2(900,800),8,true)
		var e=enemies[-1]
		e.hp=10000; e.maxhp=10000; enemies=[e]
		player.pos=Vector2(740,800)
		for i in units.size(): units[i].pos=Vector2(760+i*25,800+i*18); units[i].hp*=0.6
		clear_overlay(); cast_barrier(); cast_buff(); cast_heal()
	else:
		open_hero(page)
		if page==1: HeroUI.show_page(self,1,5)
		screenshot_mode=true
func _process(dt):
	if combat:
		elapsed+=dt
		if elapsed>2 and elapsed<2.1: cast_heal()
	super(dt)
