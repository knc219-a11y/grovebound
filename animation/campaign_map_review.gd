extends "res://animation/pixel_gameplay_preview.gd"
@export var view="world"
@export var theme=1
var review_time=0.0
func _ready():
	super()
	# No production save reads/writes: inherited preview hooks isolate all transactions.
	owned.clear(); squad.clear(); discovered.clear(); cleared_stages=[]; unlocked=false
	campaign_progress={"version":1,"cleared":[]}
	if theme>1:
		cleared_stages=range(1,mini(theme,4)); unlocked=true
		campaign_progress=Routes.migrated({"cleared_stages":cleared_stages})
	for previous in range(1,theme):
		for stage in range(1,9): campaign_progress=Routes.completed(campaign_progress,Routes.coordinate(previous,stage))
	for stage in range(1,4): campaign_progress=Routes.completed(campaign_progress,Routes.coordinate(theme,stage))
	for kind in ["boar","fox","deer","turtle"]:
		var level=3 if theme==1 else 8 if theme==2 else 12 if theme==3 else 18 if theme==4 else 24
		var d=make_owned(kind,level,{"kind":kind,"level":level,"xp":0,"star":1 if theme<4 else 2,"trait":"강인함","grade":"common","options":[]})
		squad.append(d.id)
	show_camp(); clear_overlay()
	if view in ["world","stages","locked"]:
		map_theme=theme if view=="stages" else 0
		map_stage=4; map_difficulty="depth" if view=="locked" else "normal"
		open_stage_select(); screenshot_mode=true
		return
	var stage=6 if view=="encounter" else 4 if view=="midboss" else 8
	for i in range(4,9): campaign_progress=Routes.completed(campaign_progress,Routes.coordinate(theme,i))
	depart_route(Routes.coordinate(theme,stage))
	if view=="encounter":
		player.pos=trail.points[0]+Vector2(-150,20)
		for i in units.size(): units[i].pos=player.pos+Vector2(30-i*30,i*25-35)
		return
	for e in enemies:
		if not e.boss: e.hp=0
	player.pos=trail.points[-1]+Vector2(-200,20)
	for i in units.size(): units[i].pos=player.pos+Vector2(30-i*30,i*25-35)
	trail.begin_boss_intro(self)
	if view in ["result","depth"]:
		for e in enemies: e.hp=0
		player.pos=trail.data.exit; in_combat=false
		finish_route(true); screenshot_mode=true
		if view=="depth":
			show_camp(); map_difficulty="depth"; map_theme=0; open_stage_select()
	message=""; message_time=0
func _process(dt):
	review_time+=dt
	if view in ["midboss","boss","encounter"]:
		if in_combat:
			if heal_cd<=0: cast_heal()
			if buff_cd<=0: cast_buff()
			if review_time>3.3:
				for i in active_units().size(): use_companion_skill(i)
		stick=Vector2.ZERO
		for e in enemies:
			if e.hp<=0 or e.wind<=0: continue
			if e.attack_kind=="cone" and EnemyPatterns.contains(e,player.pos):
				stick=e.cone_direction.orthogonal()
			elif e.attack_kind in ["slam","hex"] and player.pos.distance_to(e.aim)<e.tell_radius+30:
				stick=(player.pos-e.aim).normalized()
				if stick.length()<0.1: stick=Vector2.LEFT
			elif e.attack_kind=="stomp" and player.pos.distance_to(e.aim)<160: stick=(player.pos-e.aim).normalized()
			elif e.attack_kind=="charge":
				var near=Geometry2D.get_closest_point_to_segment(player.pos,e.origin,e.aim)
				if player.pos.distance_to(near)<85: stick=(e.aim-e.origin).normalized().orthogonal()
			for aim in e.get("extra_aims",[]):
				if player.pos.distance_to(aim)<e.get("extra_radius",90.0)+35:
					stick=(player.pos-aim).normalized()
					if stick.length()<0.1: stick=Vector2.LEFT
	super(dt)
