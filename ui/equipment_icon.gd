extends RefCounted
# Catalog identity only: colors do not represent a new rarity system.
const KEYS=["twig_staff","oak_staff","grove_staff","woven_robe","bark_robe","guardian_robe","vitality_charm","stream_charm","wind_charm"]
const REGIONS=[Rect2(130,0,390,355),Rect2(610,0,390,355),Rect2(1030,0,390,355),Rect2(140,355,385,345),Rect2(590,355,410,345),Rect2(1030,355,390,345),Rect2(150,700,370,324),Rect2(610,700,390,324),Rect2(1030,700,390,324)]
static func texture(key):
	var index=KEYS.find(key)
	if index<0: return null
	var source=load("res://assets/equipment/equipment-atlas.png") as Texture2D
	if source==null: return null
	var atlas=AtlasTexture.new()
	atlas.atlas=source
	# Explicit source bounds retain staff tips and robe hems across uneven row gutters.
	atlas.region=REGIONS[index]
	atlas.filter_clip=true
	return atlas
static func add(parent,key,rect:Rect2):
	var picture=TextureRect.new()
	picture.name="EquipmentIcon_"+str(key)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture=texture(key)
	picture.position=rect.position; picture.size=rect.size
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture
