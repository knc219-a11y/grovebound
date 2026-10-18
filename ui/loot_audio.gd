extends RefCounted
# Short synthesized chimes, with no external audio dependency.
static func stream(grade):
	var rate=22050
	var notes=[523.25] if grade=="common" else ([659.25,783.99] if grade=="rare" else [659.25,830.61,987.77])
	var duration=0.18+notes.size()*0.09
	var samples=PackedByteArray()
	samples.resize(int(rate*duration)*2)
	for i in int(rate*duration):
		var t=float(i)/rate
		var value=0.0
		for j in notes.size():
			var age=t-j*0.075
			if age>=0: value+=sin(age*TAU*notes[j])*exp(-age*16)*minf(1,age*250)
		samples.encode_s16(i*2,int(clampf(value*0.22,-1,1)*32767))
	var result=AudioStreamWAV.new()
	result.format=AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate=rate
	result.data=samples
	return result
