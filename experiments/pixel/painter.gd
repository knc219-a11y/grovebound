extends Node2D
const Rig = preload("res://experiments/pixel/boar_pixel_rig.gd")
const COLORS = ["181619","272023","362b2b","443532","51413b","625149","746157","897569","9e8978","b29e88","c9b69b","e0d2b2","363b40","51575b","6e7779","e4e3d4"]
var rig
var actor = {"rig_phase":0.0,"rig_move":1.0}
func _ready():
	rig = Rig.new()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://experiments/pixel/palette.gdshader")
	var palette = PackedVector3Array()
	for value in COLORS:
		var c = Color(value)
		palette.append(Vector3(c.r,c.g,c.b))
	mat.set_shader_parameter("palette",palette)
	material = mat
func _draw():
	rig.draw(self,Vector2(48,62),48,1,Color.WHITE,actor)
