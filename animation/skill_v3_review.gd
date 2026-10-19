extends "res://animation/roles_review.gd"
# Six companion skill callbacks across two teams, plus actual druid Q/E calls.
func update_game(dt):
	super(dt)
	for cue in [[3.5,"druid_heal"],[4.5,"druid_buff"]]:
		if clock>=cue[0] and not cues.has(cue[1]):
			cues[cue[1]]=true
			if cue[1]=="druid_heal":
				units[0].hp=maxf(1,units[0].hp-40)
				cast_heal()
			else: cast_buff()
