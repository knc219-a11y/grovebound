extends Control
# Read-only cartography: landmarks are illustrations; route buttons own all input.
var theme_id=0
var points=[]
var cleared=[]
var locked=[]
var selected=-1
const PALETTES=[
	["25332e","35463a","52614a","41615b"],
	["253b32","365342","59734f","416b65"],
	["363a37","494c43","72705b","455953"],
	["2b3439","3c4848","697368","405757"],
	["44362f","594436","88684a","665140"],
	["2d3438","414a4b","737770","414f55"]]
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
func polygon(vertices,color):
	draw_colored_polygon(PackedVector2Array(vertices),color)
func line(vertices,color,width=2):
	draw_polyline(PackedVector2Array(vertices),color,width,false)
func plate(center,extent,color):
	var x=extent.x; var y=extent.y
	polygon([center+Vector2(-x,-y/2),center+Vector2(-x/2,-y),center+Vector2(x/2,-y),center+Vector2(x,-y/3),center+Vector2(x,y/2),center+Vector2(x/2,y),center+Vector2(-x/2,y),center+Vector2(-x,y/3)],color)
func tree(p,scale_value=1.0):
	draw_set_transform(p,0,Vector2.ONE*scale_value)
	draw_rect(Rect2(-3,0,6,14),Color("5e5541"))
	polygon([Vector2(-18,1),Vector2(-12,-9),Vector2(-15,-9),Vector2(0,-30),Vector2(15,-9),Vector2(12,-9),Vector2(18,1)],Color("263d32"))
	polygon([Vector2(-14,-3),Vector2(-8,-12),Vector2(0,-25),Vector2(4,-13),Vector2(11,-3)],Color("527053"))
	draw_set_transform(Vector2.ZERO)
func rocks(p):
	polygon([p+Vector2(-28,10),p+Vector2(-24,-9),p+Vector2(-5,-26),p+Vector2(23,-24),p+Vector2(37,-5),p+Vector2(32,18)],Color("343d3c"))
	polygon([p+Vector2(-24,-9),p+Vector2(-5,-26),p+Vector2(23,-24),p+Vector2(17,-8),p+Vector2(-8,0)],Color("73766b"))
	polygon([p+Vector2(-8,0),p+Vector2(17,-8),p+Vector2(32,18),p+Vector2(-8,12)],Color("565e56"))
	line([p+Vector2(-23,3),p+Vector2(-9,8),p+Vector2(17,1)],Color("8a8976"))
func grave(p):
	draw_rect(Rect2(p+Vector2(-11,8),Vector2(24,5)),Color("263536"))
	draw_rect(Rect2(p+Vector2(-7,-15),Vector2(14,25)),Color("697771"))
	draw_rect(Rect2(p+Vector2(-4,-19),Vector2(8,4)),Color("7c8980"))
	draw_rect(Rect2(p+Vector2(-2,-11),Vector2(3,14)),Color("3f5551"))
	draw_rect(Rect2(p+Vector2(-5,-7),Vector2(9,3)),Color("3f5551"))
func gate(p,castle=false):
	var stone=Color("85846d") if castle else Color("657b71")
	var shade=Color("45535a") if castle else Color("364e4b")
	draw_rect(Rect2(p+Vector2(-36,17),Vector2(72,9)),shade)
	for side in [-1,1]:
		var x=p.x+side*25-8
		draw_rect(Rect2(x,p.y-30,16,50),stone)
		draw_rect(Rect2(x+10,p.y-25,6,45),shade)
		for j in 3: draw_rect(Rect2(x,p.y-23+j*13,16,2),shade)
		if castle:
			for j in 3: draw_rect(Rect2(x-2+j*7,p.y-37,4,9),stone)
	draw_rect(Rect2(p+Vector2(-21,-28),Vector2(42,11)),stone)
	if castle:
		draw_rect(Rect2(p+Vector2(-14,-17),Vector2(28,37)),Color("243036"))
		for j in 4: draw_rect(Rect2(p+Vector2(-11+j*7,-15),Vector2(2,34)),shade)
		polygon([p+Vector2(-25,-60),p+Vector2(-25,-42),p+Vector2(-7,-48)],Color("96795c"))
		line([p+Vector2(-25,-61),p+Vector2(-25,-31)],stone)
	else:
		polygon([p+Vector2(-14,18),p+Vector2(-14,-12),p+Vector2(-6,-20),p+Vector2(6,-20),p+Vector2(14,-12),p+Vector2(14,18)],Color("243a38"))
func landmark(id,p,scale_value=1.0):
	# Scaled landmarks are laid over a quiet central band, outside node text.
	if scale_value!=1.0:
		draw_set_transform(p,0,Vector2.ONE*scale_value)
		p=Vector2.ZERO
	match id:
		1:
			line([p+Vector2(-45,18),p+Vector2(-15,5),p+Vector2(9,12),p+Vector2(42,-2)],Color("294c46"),16)
			line([p+Vector2(-45,15),p+Vector2(-15,2),p+Vector2(9,9),p+Vector2(42,-5)],Color("649083"),3)
			for j in 5: draw_rect(Rect2(p+Vector2(-4+j*5,-4),Vector2(4,26)),Color("998366"))
			line([p+Vector2(-7,-3),p+Vector2(24,-3)],Color("d0b58a"))
		2:
			rocks(p)
			line([p+Vector2(-40,26),p+Vector2(44,8)],Color("958770"),3)
			line([p+Vector2(-40,34),p+Vector2(44,16)],Color("958770"),3)
			for j in 6: line([p+Vector2(-35+j*13,23-j*3),p+Vector2(-31+j*13,36-j*3)],Color("524a3c"),3)
			# Stone-laden mine cart, a readable silhouette rather than noisy texture.
			draw_rect(Rect2(p+Vector2(-20,13),Vector2(28,14)),Color("887456"))
			draw_rect(Rect2(p+Vector2(-22,10),Vector2(32,5)),Color("ad9670"))
			draw_rect(Rect2(p+Vector2(-17,26),Vector2(6,6)),Color("292f2d"))
			draw_rect(Rect2(p+Vector2(1,23),Vector2(6,6)),Color("292f2d"))
		3:
			gate(p)
			grave(p+Vector2(-56,12)); grave(p+Vector2(55,19))
		4:
			polygon([p+Vector2(-46,17),p+Vector2(-25,-14),p+Vector2(-8,-18),p+Vector2(6,15)],Color("775540"))
			polygon([p+Vector2(-25,-14),p+Vector2(-8,-18),p+Vector2(-2,-9),p+Vector2(-31,-3)],Color("a38157"))
			line([p+Vector2(13,-29),p+Vector2(4,-10),p+Vector2(20,6),p+Vector2(12,29),p+Vector2(33,40)],Color("2e2b27"),5)
			line([p+Vector2(20,6),p+Vector2(42,1),p+Vector2(51,13)],Color("2e2b27"),3)
			line([p+Vector2(39,-30),p+Vector2(39,0)],Color("8b7055"),4)
			polygon([p+Vector2(41,-29),p+Vector2(57,-24),p+Vector2(41,-15)],Color("a1654c"))
		5: gate(p,true)
	if scale_value!=1.0: draw_set_transform(Vector2.ZERO)
func geography():
	var palette=PALETTES[clampi(theme_id,0,5)]
	var land=Color(palette[1]); var light=Color(palette[2]); var water=Color(palette[3])
	if theme_id==0:
		# Five connected silhouettes tell the world route without inventing paths.
		for i in points.size():
			var p=points[i]
			plate(p+Vector2(0,-15),Vector2(65,74),Color(PALETTES[i+1][1]))
			landmark(i+1,p+Vector2(0,-53),0.65)
		line([Vector2(6,148),Vector2(95,136),Vector2(146,166),Vector2(252,152),Vector2(320,179),Vector2(405,165),Vector2(530,186),Vector2(650,160)],water,10)
		line([Vector2(6,146),Vector2(95,134),Vector2(146,164),Vector2(252,150),Vector2(320,177),Vector2(405,163),Vector2(530,184),Vector2(650,158)],Color("5c7563"),2)
	else:
		plate(Vector2(335,171),Vector2(305,52),land)
		# Keep all landmarks in the space between the two rows of route buttons.
		match theme_id:
			1:
				line([Vector2(0,169),Vector2(100,156),Vector2(194,183),Vector2(290,160),Vector2(400,183),Vector2(520,154),Vector2(660,177)],water,25)
				line([Vector2(0,164),Vector2(100,151),Vector2(194,178),Vector2(290,155),Vector2(400,178),Vector2(520,149),Vector2(660,172)],Color("759688"),3)
				landmark(1,Vector2(320,166))
				for p in [Vector2(126,32),Vector2(310,35),Vector2(642,210)]: tree(p,0.8)
			2:
				for p in [Vector2(110,166),Vector2(270,177),Vector2(470,166)]: landmark(2,p,0.85)
				line([Vector2(14,180),Vector2(185,180),Vector2(334,153),Vector2(628,153)],light,2)
			3:
				landmark(3,Vector2(333,175))
				for p in [Vector2(110,170),Vector2(168,184),Vector2(485,167),Vector2(555,174)]: grave(p)
				line([Vector2(28,182),Vector2(225,164),Vector2(333,181),Vector2(485,184),Vector2(630,163)],water,3)
			4:
				for p in [Vector2(130,164),Vector2(333,170),Vector2(540,165)]: landmark(4,p,0.8)
				for j in 5: line([Vector2(30+j*132,310),Vector2(72+j*132,306)],light,2)
			5:
				# Battlements and a central gate distinguish the final theme.
				draw_rect(Rect2(36,151,588,38),land)
				for j in 29:
					draw_rect(Rect2(38+j*20,144,11,9),light)
					draw_rect(Rect2(42+j*20,174,8,6),Color("323d42"))
				line([Vector2(36,163),Vector2(624,163)],light,2)
				landmark(5,Vector2(333,179))
	# Sparse contour marks stay well away from labels and the selectable route.
	for i in 5:
		var x=42+i*126
		draw_rect(Rect2(x,18,40,2),light.darkened(0.25))
		draw_rect(Rect2(x+10,22,24,2),land)
func _draw():
	var palette=PALETTES[clampi(theme_id,0,5)]
	draw_rect(Rect2(Vector2.ZERO,size),Color(palette[0]))
	draw_rect(Rect2(2,2,size.x-4,size.y-4),Color(palette[2]).darkened(0.35),false,2)
	geography()
	for i in maxi(0,points.size()-1):
		var delta=points[i+1]-points[i]
		var steps=maxi(1,int(delta.length()/13))
		for j in range(2,steps-1):
			var p=points[i].lerp(points[i+1],float(j)/steps)
			draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(6,4)),Color("c1ad7e") if i in cleared else Color("73816b"))
	for i in points.size():
		var p=points[i]
		var radius=36 if theme_id==0 else 29
		# Opaque backing protects text from the illustrated geography.
		draw_rect(Rect2(p-Vector2(40,29),Vector2(80,58)),Color(palette[0]))
		var color=Color("b8cf9a") if i in cleared else Color("6c7970") if i in locked else Color("c0b68a")
		draw_arc(p,radius,0,TAU,8,color,2,false)
		if i==selected:
			for side in [-1,1]:
				for vertical in [-1,1]:
					var corner=p+Vector2(side*43,vertical*32)
					line([corner-Vector2(side*10,0),corner,corner-Vector2(0,vertical*8)],Color("ead39b"),3)
		if i in cleared:
			line([p+Vector2(27,-28),p+Vector2(32,-23),p+Vector2(41,-34)],Color("c3daa3"),3)
		elif i in locked:
			draw_rect(Rect2(p+Vector2(31,-32),Vector2(12,10)),Color("889084"))
			draw_arc(p+Vector2(37,-32),5,PI,TAU,4,Color("889084"),2,false)
		if theme_id>0 and i in [3,7]:
			var crown=p+Vector2(0,-42)
			polygon([crown+Vector2(-10,6),crown+Vector2(-12,-4),crown+Vector2(-4,0),crown+Vector2(0,-9),crown+Vector2(4,0),crown+Vector2(12,-4),crown+Vector2(10,6)],Color("bf9971") if i==3 else Color("d9bd7b"))
	# Compass is decorative and never intercepts route input.
	line([Vector2(625,28),Vector2(625,56)],Color("aaa586"))
	line([Vector2(613,42),Vector2(637,42)],Color("aaa586"))
	polygon([Vector2(625,19),Vector2(620,31),Vector2(630,31)],Color("d2c493"))
