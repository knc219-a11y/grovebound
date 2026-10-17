extends "res://animation/boar_rig_v3.gd"
# Walk uses painted poses. Idle/action feedback retain the approved connected skin.
var walk_texture: Texture2D
var walk_frames=[]

func _init(legacy_atlas=null):
	super(legacy_atlas)
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://animation/boar_walk_frames.json"))
	walk_texture=load(data.texture)
	for frame in data.frames:
		var r=frame.region
		walk_frames.append(Rect2(r[0],r[1],r[2],r[3]))

func frame_for_phase(phase: float):
	return posmod(floori(phase/TAU*walk_frames.size()),walk_frames.size())

func draw(canvas: Node2D,position: Vector2,height: float,face: float,tint: Color,actor):
	var walking=actor.get("rig_move",0.0)>0.25 and actor.get("walk",false)
	var acting=actor.get("swing",0.0)>0 or actor.get("wind",0.0)>0
	if not walking or acting or actor.get("hp",1.0)<=0:
		super.draw(canvas,position,height,face,tint,actor)
		return
	var index=frame_for_phase(actor.get("rig_phase",0.0))
	var region=walk_frames[index]
	# Shared ground anchor and height suppress whitespace/scale jitter.
	var width=height*1.6534
	canvas.draw_set_transform(position,0,Vector2(face,1))
	canvas.draw_texture_rect_region(walk_texture,Rect2(-width/2.0,-height,width,height),region,tint)
	canvas.draw_set_transform(Vector2.ZERO)
