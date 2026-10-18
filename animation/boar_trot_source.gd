extends "res://experiments/pixel/boar_pixel_rig.gd"
# Build-time only: keep the approved skin, with diagonally paired fast steps.
const TROT_STRIDE = 90.0
const TROT_DUTY = 0.42
func _init():
	super()
	body_bob=0.7
	# Keep the longer contact reach inside the forelegs' existing bone lengths.
	legs[1].root.y+=2.0
	legs[3].root.y+=2.0
	for i in 4: legs[i].beat=[0.0,0.5,0.5,0.0][i]
func foot_path(phase: float, beat: float):
	var t=fposmod(phase/TAU+beat,1.0)
	var half=TROT_STRIDE*TROT_DUTY/2.0
	if t<TROT_DUTY: return Vector2(half-TROT_STRIDE*t,0)
	var s=(t-TROT_DUTY)/(1.0-TROT_DUTY)
	return Vector2(lerpf(-half,half,smoothstep(0,1,s)),-9.0*sin(PI*s))
