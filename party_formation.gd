extends RefCounted
# Gathering anchors only: target selection, reach and combat movement stay independent.
const KEYS=["front","rear","surround"]
static func normalize(value): return value if value in KEYS else "surround"
static func priority(kind): return 0 if kind=="turtle" else 1 if kind=="boar" else 2
static func offset(formation,index,forward):
	var direction=forward.normalized() if forward.length()>0.01 else Vector2.RIGHT
	var lateral=Vector2(-direction.y,direction.x)
	var rank=clampi(index,0,3)
	if formation=="front": return direction*(175-(rank/2)*65)+lateral*(-45+(rank%2)*90)
	if formation=="rear": return -direction*(100+(rank/2)*60)+lateral*(-45+(rank%2)*90)
	return direction*([110.0,0.0,-110.0,0.0][rank])+lateral*([0.0,95.0,0.0,-95.0][rank])
