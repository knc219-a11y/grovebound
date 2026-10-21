extends SceneTree
const Loot=preload("res://companion_loot.gd")
const Special=preload("res://special_companions.gd")
const Evolution=preload("res://evolution_rules.gd")
const Save=preload("res://save_data.gd")
const Management=preload("res://companion_management.gd")
var errors=[]
var checks=0
func check(ok,message):
	checks+=1
	if not ok: errors.append(message)
func fixture(id,kind="boar",star=4,level=50):
	var d={"id":id,"kind":kind,"star":star,"grade":"special","level":level,"xp":0,"trait":"강인함","favorite":false,"options":[],"special":{"version":1,"state":"ready","element":"wind","unique":Special.choices(kind).keys()[0],"affixes":[]}}
	if star>=5: d.special.evolution={"version":1,"state":"ready","ability":Special.evolution_choices(kind).keys()[0]}
	return d
func _init():
	var source=fixture(1)
	var support=fixture(2,"fox")
	var records=[source,support]
	var before=records.duplicate(true)
	var plan=Evolution.preview(records,[1],1,2)
	check(plan.error.is_empty(),"valid exact materials")
	check(records==before,"preview preserves all inputs")
	var result=plan.result
	check(result.star==5 and result.level==1 and result.xp==0,"new five-star restarts at1")
	check(result.special.evolution.growth_version==2 and Special.evolution_pending(result),"new growth marker while choice pending")
	check(is_equal_approx(Special.growth(result)/Special.growth(source),1.10),"Lv1 starts110 percent of4star50")
	check(Loot.max_level(result)==60,"new five-star max remains60")
	var base=Special.growth(source)
	var previous=Special.growth(result)
	for level in range(2,61):
		var d=result.duplicate(true)
		d.level=level
		var power=Special.growth(d)
		check(power>previous and is_equal_approx((power-previous)/base,0.20/59.0),"linear growth at%d" % level)
		previous=power
	check(is_equal_approx(previous/base,1.30),"new Lv60 matches prior5star60")
	for level in range(50,61):
		var legacy=fixture(3,"boar",5,level)
		legacy.xp=17 if level<60 else 0
		var snapshot=legacy.duplicate(true)
		var old_power=base*(1.10+0.02*(level-50))
		check(is_equal_approx(Special.growth(legacy),old_power),"legacy strength preserved at%d" % level)
		Special.normalize(legacy)
		check(Special.equivalent(legacy,snapshot),"legacy normalize preserves level XP and absent marker at%d" % level)
		var normalized=Save.normalize(JSON.parse_string(JSON.stringify({"owned":[legacy],"squad":[3],"discovered":["boar"],"next_id":4})),["boar"])
		check(not normalized.repaired and Special.equivalent(normalized.owned[0],legacy),"legacy JSON unchanged at%d" % level)
	var ready=result.duplicate(true)
	ready.special.evolution.state="ready"
	ready.special.evolution.ability="vital"
	ready.xp=13
	var normalized=Save.normalize(JSON.parse_string(JSON.stringify({"owned":[ready],"squad":[1],"discovered":["boar"],"next_id":3})),["boar","fox"])
	check(not normalized.repaired and Special.equivalent(normalized.owned[0],ready),"new marker JSON roundtrip exact")
	check(normalized.owned[0].special.evolution.growth_version is int,"marker numeric normalization")
	check(Management.project(ready,21).xp==34 and Management.project(ready,22).level==2,"new XP begins at first-level threshold35")
	var maxed=Management.project(ready,999999)
	check(maxed.level==60 and maxed.xp==0,"new five-star growth stops at60")
	check(Evolution.material_error(maxed,[1],true,5).is_empty(),"new5star60 remains6star material")
	var other=fixture(4,"fox",5,60)
	var six=Evolution.preview([maxed,other],[1],1,4)
	check(six.error.is_empty() and six.result.star==6 and six.result.level==60,"six-star start unchanged")
	check(is_equal_approx(Special.growth(six.result)/Special.growth(maxed),1.10),"six-star immediate110 unchanged")
	for level in range(60,71):
		var legacy_six=fixture(5,"boar",6,level)
		var new_six=six.result.duplicate(true)
		new_six.level=level
		check(is_equal_approx(Special.growth(new_six),Special.growth(legacy_six)),"six-star curve independent of5star marker at%d" % level)
	for kind in Special.SKILLS:
		var wind=fixture(10,kind)
		check(is_equal_approx(Special.speed(wind),1.08),"wind keeps movement8 for"+kind)
		check(is_equal_approx(Special.attack_speed(wind),1.10),"wind attack10 for"+kind)
		check(is_equal_approx(Special.haste(wind),1.0),"wind removes skillCDR for"+kind)
		wind.special.element="water"
		check(is_equal_approx(Special.haste(wind),0.85) and is_equal_approx(Special.attack_speed(wind),1.0),"water skillCDR independent for"+kind)
	var combined=fixture(12,"fox",5,60)
	combined.special.unique="haste"
	combined.special.evolution.ability="haste"
	check(is_equal_approx(Special.haste(combined),0.88*0.90),"wind keeps independent chosen haste effects")
	if errors.is_empty(): print("FEEDBACK GROWTH PASS: %d checks; Lv1-60/legacy JSON/6star/wind" % checks)
	else: push_error(str(errors))
	quit(0 if errors.is_empty() else 1)
