extends Node
# Original deterministic PCM sound design; no external recordings or save changes.
const RATE=22050
const MAX_VOICES=6
const PROFILES={
	"hit_bat":[510.0,0.10,0.72],"skill_bat":[730.0,0.28,0.55],
	"hit_boar":[95.0,0.13,0.65],"hit_wolf":[240.0,0.12,0.8],
	"hit_marten":[390.0,0.08,0.85],"hit_fox":[740.0,0.16,0.2],
	"hit_deer":[440.0,0.10,0.25],"hit_turtle":[130.0,0.13,0.45],
	"melee":[150.0,0.12,0.6],"hurt":[115.0,0.12,0.65],"block":[260.0,0.16,0.3],
	"skill_boar":[75.0,0.38,0.65],"skill_wolf":[300.0,0.32,0.75],
	"skill_marten":[470.0,0.30,0.7],"skill_fox":[620.0,0.45,0.45],
	"skill_deer":[660.0,0.48,0.04],"skill_turtle":[185.0,0.42,0.16],
	"skill_druid_heal":[780.0,0.46,0.02],"skill_druid_buff":[520.0,0.48,0.03],
	"skill_druid_revive":[880.0,0.65,0.02],"stomp":[65.0,0.38,0.7]
}
var streams={}
var voices=[]
var cooldowns={}
var enabled=true
var skill_window=0.0
func _ready():
	for kind in PROFILES: streams[kind]=synthesize(kind)
	for i in MAX_VOICES:
		var voice=AudioStreamPlayer.new()
		add_child(voice)
		voices.append({"player":voice,"left":0.0,"skill":false})
func _process(dt):
	skill_window=maxf(0,skill_window-dt)
	for kind in cooldowns: cooldowns[kind]=maxf(0,cooldowns[kind]-dt)
	for voice in voices: voice.left=maxf(0,voice.left-dt)
func set_enabled(value):
	enabled=value
	if not enabled:
		for voice in voices:
			voice.player.stop()
			voice.player.stream=null
			voice.left=0.0
func cue(kind):
	if not enabled or not streams.has(kind) or cooldowns.get(kind,0.0)>0: return false
	var skill=kind.begins_with("skill_") or kind=="stomp"
	var slot=-1
	for i in voices.size():
		if voices[i].left<=0: slot=i; break
	if slot<0 and skill:
		for i in voices.size():
			if not voices[i].skill: slot=i; break
	if slot<0: return false
	if skill:
		skill_window=0.18
		for voice in voices:
			if not voice.skill and voice.left>0: voice.player.volume_db=-29
	var voice=voices[slot]
	voice.player.stop()
	voice.player.stream=streams[kind]
	voice.player.volume_db=-18 if skill else (-29 if skill_window>0 else -24)
	voice.player.play()
	voice.left=PROFILES[kind][1]
	voice.skill=skill
	cooldowns[kind]=0.12 if skill else 0.065
	return true
static func synthesize(kind):
	var profile=PROFILES[kind]
	var samples=PackedByteArray()
	var count=int(RATE*profile[1])
	samples.resize(count*2)
	var rng=RandomNumberGenerator.new()
	rng.seed=kind.hash()
	var skill=kind.begins_with("skill_")
	var phase=0.0
	for i in count:
		var t=float(i)/RATE
		var p=t/profile[1]
		phase+=TAU*profile[0]*(1.4-0.65*p)/RATE
		var tone=sin(phase)+0.3*sin(phase*2.01)
		if skill: tone+=0.25*sin(phase*1.5)
		var noise=rng.randf_range(-1,1)
		var envelope=minf(1,t/0.006)*pow(1-p,2)
		var pulse=0.7+0.3*cos(t*TAU*14) if kind=="skill_marten" else 1.0
		var value=((1-profile[2])*tone+profile[2]*noise)*envelope*pulse*0.55
		samples.encode_s16(i*2,int(clampf(value,-0.95,0.95)*32767))
	var result=AudioStreamWAV.new()
	result.format=AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate=RATE
	result.data=samples
	return result
