extends RefCounted
# Cosmetic silhouettes and pulses; repeated slashes never apply extra damage.
const TITLES={"boar":"관통 돌진","wolf":"추격 타격","marten":"집중 타격","fox":"야성 폭발","turtle":"도발 · 방어","deer":"숲의 회복","bat":"급강하 타격","druid_heal":"숲의 손길","druid_buff":"야성 강화","druid_revive":"인연의 소생"}
const COLORS={"boar":"e8b166","wolf":"9dd7ed","marten":"edbbd0","fox":"f1a35e","turtle":"91dce0","deer":"aee58f","druid_heal":"aee58f","druid_buff":"ecd17e","druid_revive":"c9eab2"}
static func shard(g,p,d,length,width,c):
	var side=d.orthogonal()*width
	g.draw_colored_polygon(PackedVector2Array([(p-d*length*0.4).round(),(p+side).round(),(p+d*length).round(),(p-side).round()]),c)
static func ring(g,p,r,c):
	g.draw_set_transform(p.round(),0,Vector2(1,0.42))
	g.draw_arc(Vector2.ZERO,r,0,TAU,32,c,3,false)
	g.draw_set_transform(Vector2.ZERO)
static func draw(g,event,cam,font):
	var kind=event.kind.trim_prefix("skill_")
	var t=clampf(event.age/event.duration,0,1)
	var fade=1-smoothstep(0.55,1.0,t)
	var c=Color(COLORS.get(kind,"e8d7b5")); c.a=fade
	var white=Color("fff3d6"); white.a=fade
	var source=event.a-cam
	var ground=event.b-cam
	var p=ground-Vector2(0,25)
	var direction=(event.b-event.a).normalized()
	if direction.length()<0.01: direction=Vector2.RIGHT
	var side=direction.orthogonal()
	var burst=1-pow(1-t,3)
	# Skill names are attached to the caster; normal attacks never show this banner.
	var title=TITLES.get(kind,"")
	if not title.is_empty():
		var pos=(source+Vector2(-font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x/2,-86-t*9)).round()
		g.draw_rect(Rect2(pos+Vector2(-7,-18),Vector2(font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+14,25)),Color(0.06,0.1,0.08,0.8*fade))
		g.draw_string(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,17,c)
	match kind:
		"boar":
			if t<0.48:
				for i in 5:
					var a=source-Vector2(0,24)+side*(i-2)*5
					g.draw_line(a.round(),(p+side*(i-2)*3).round(),Color(c,fade*(1-t/0.48)),3 if i%2==0 else 2,false)
			ring(g,ground,20+burst*45,c)
			for i in 9:
				var d=Vector2.RIGHT.rotated(i*TAU/9)
				shard(g,p+d*(12+burst*26),d,9*(1-t)+2,3,c)
			if t<0.22: shard(g,p,direction,30,12,white)
		"wolf","marten","bat":
			var count=3 if kind=="wolf" else 4
			for i in count:
				var local=clampf((t-i*0.075)/0.55,0,1)
				if t<i*0.075 or local>=1: continue
				var slash=Color(c,fade*(1-local))
				var center=p+side*(i-(count-1)/2.0)*8
				var angle=direction.angle()+(-0.7 if i%2==0 else 0.7)
				g.draw_arc(center,18+local*25,angle-1.35,angle+0.9,14,slash,5 if kind=="wolf" else 3,false)
				shard(g,center,Vector2.RIGHT.rotated(angle),22*(1-local)+5,3,white)
			ring(g,ground,17+burst*24,Color(c,fade*0.5))
		"fox":
			ring(g,ground,22+burst*(event.radius-22),c)
			g.draw_arc(p,15+burst*33,0,TAU,32,Color(c,fade*0.65),3,false)
			for i in 12:
				var d=Vector2.RIGHT.rotated(i*TAU/12+t*0.25)
				shard(g,p+d*(10+burst*48),d,12*(1-t)+2,4,c)
			if t<0.25:
				var core=Color(white,1-t/0.25)
				g.draw_circle(p,13*(1-t/0.25),core)
		"turtle":
			ring(g,ground,26+burst*44,c)
			var center=source-Vector2(0,35)
			var r=30+sin(t*PI)*5
			var pts=PackedVector2Array([center+Vector2(-r,-r*0.75),center+Vector2(0,-r),center+Vector2(r,-r*0.75),center+Vector2(r,r*0.25),center+Vector2(0,r),center+Vector2(-r,r*0.25),center+Vector2(-r,-r*0.75)])
			g.draw_colored_polygon(pts,Color(c,fade*0.13))
			g.draw_polyline(pts,c,3,false)
			g.draw_line(center-Vector2(0,17),center+Vector2(0,18),white,3,false)
			g.draw_line(center-Vector2(13,0),center+Vector2(13,0),white,3,false)
		"deer","druid_heal","druid_revive":
			ring(g,ground,22+burst*48,c)
			ring(g,ground,13+burst*28,Color(c,fade*0.65))
			for i in 9:
				var q=p+Vector2(sin(i*2.4+t*3)*32,25-t*65-(i%3)*12)
				shard(g,q,Vector2(0.6,-0.8),6,3,c)
			for i in 3:
				var q=p+Vector2((i-1)*23,-t*36)
				g.draw_line(q-Vector2(0,6),q+Vector2(0,6),white,3,false)
				g.draw_line(q-Vector2(5,0),q+Vector2(5,0),white,3,false)
		"druid_buff":
			ring(g,ground,23+burst*40,c)
			for i in 3:
				var q=p+Vector2(0,12-i*15-t*25)
				g.draw_polyline(PackedVector2Array([q+Vector2(-17,8),q,q+Vector2(17,8)]),c,4,false)
