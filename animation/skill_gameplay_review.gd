extends "res://animation/full_gameplay_preview.gd"
# Real skill calls and combat timings; inherited preview isolates user saves.
func update_game(dt):
	super(dt)
	for cue in [[0.4,3,"fox_skill"],[1.0,0,"marten_skill"],[8.8,0,"boar_skill"],[9.6,1,"wolf_skill"]]:
		if clock>=cue[0] and not cues.has(cue[2]):
			cues[cue[2]]=true
			use_companion_skill(cue[1])
