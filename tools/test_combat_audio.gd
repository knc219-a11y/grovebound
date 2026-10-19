extends SceneTree
func _initialize():
	call_deferred("check")
func check():
	var audio=preload("res://animation/combat_audio.gd").new()
	root.add_child(audio)
	assert(audio.voices.size()==6)
	var fingerprints={}
	for kind in audio.PROFILES:
		var stream=audio.streams[kind]
		assert(stream.data.size()>3000 and stream.mix_rate==22050)
		assert(not fingerprints.has(hash(stream.data)))
		fingerprints[hash(stream.data)]=true
		assert(stream.data==audio.synthesize(kind).data)
	assert(audio.cue("hit_boar"))
	assert(not audio.cue("hit_boar"))
	assert(not audio.cue("impact_boar")) # Visual duplicate is silent.
	for kind in ["hit_wolf","hit_marten","hit_fox","hurt","block"]: assert(audio.cue(kind))
	assert(not audio.cue("melee"))
	assert(audio.cue("skill_fox")) # Skills replace a basic voice when full.
	assert(audio.voices.size()==6)
	audio.set_enabled(false)
	assert(not audio.cue("skill_deer"))
	for voice in audio.voices: assert(not voice.player.playing)
	var feedback=preload("res://animation/combat_feedback.gd").new()
	var emitted=[]
	feedback.sounded.connect(func(kind): emitted.append(kind))
	feedback.emit("melee",Vector2.ZERO,Vector2.ONE,1,{"audio_kind":"hit_wolf"})
	assert(emitted==["hit_wolf"])
	audio.free()
	await create_timer(0.1).timeout # Let the audio mixer release stopped playback references.
	print("COMBAT AUDIO PASS: deterministic distinct PCM, six voices, cooldown, priority, mute, actual feedback routing")
	quit()
