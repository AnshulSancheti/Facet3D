extends RefCounted
## Zero-thickness ink geometry, projected onto the sharp ceramic surface with a tiny ink-only seam offset.
const INNER = 1.49
const RADIUS = 0.0
const LIFT = 0.007
static func normal_at(point: Vector3) -> Vector3:
	return (point-point.clamp(Vector3.ONE*-INNER,Vector3.ONE*INNER)).normalized()
static func project(point: Vector3) -> Vector3:
	var center = point.clamp(Vector3.ONE*-INNER,Vector3.ONE*INNER)
	return center+normal_at(point)*(RADIUS+LIFT)
static func strip(a: Vector3, b: Vector3, half_width: float) -> ArrayMesh:
	var tangent = (b-a).normalized()
	# Subdivide before projecting: one long triangle would cut through a cube edge.
	var count = 1 if normal_at(a).is_equal_approx(normal_at(b)) else maxi(2,ceili(a.distance_to(b)/0.025))
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in count:
		var start = a.lerp(b,float(i)/count)
		var end = a.lerp(b,float(i+1)/count)
		var sa = tangent.cross(normal_at(start)).normalized()*half_width
		var sb = tangent.cross(normal_at(end)).normalized()*half_width
		if sa.length_squared()<0.000001: sa = Vector3.RIGHT*half_width
		if sb.length_squared()<0.000001: sb = sa
		var vertices = [project(start-sa),project(start+sa),project(end+sb),project(end-sb)]
		for index in [0,1,2,0,2,3]:
			surface.set_normal(normal_at(vertices[index]))
			surface.add_vertex(vertices[index])
	return surface.commit()
static func disc(center: Vector3, radius: float, hole: float = 0.0) -> ArrayMesh:
	var n = normal_at(center)
	var right = n.cross(Vector3.UP).normalized()
	if right.length_squared()<0.1: right = Vector3.RIGHT
	var up = right.cross(n).normalized()
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		var a = TAU*i/24.0
		var b = TAU*(i+1)/24.0
		var ra = right*cos(a)+up*sin(a)
		var rb = right*cos(b)+up*sin(b)
		for vertex in [center+ra*hole,center+ra*radius,center+rb*radius,center+ra*hole,center+rb*radius,center+rb*hole]:
			surface.set_normal(n)
			surface.add_vertex(project(vertex))
	return surface.commit()
static func polyline(raw: Array[Vector3], half_width: float) -> ArrayMesh:
	# Shared miter vertices join neighboring strokes without gaps at bends.
	var points: Array[Vector3] = [raw[0]]
	for i in range(raw.size()-1):
		var steps = 1 if normal_at(raw[i]).is_equal_approx(normal_at(raw[i+1])) else maxi(2,ceili(raw[i].distance_to(raw[i+1])/0.025))
		for j in range(1,steps+1): points.append(raw[i].lerp(raw[i+1],float(j)/steps))
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in points.size():
		var n = normal_at(points[i])
		var before = (points[i]-points[maxi(0,i-1)]).normalized() if i>0 else (points[1]-points[0]).normalized()
		var after = (points[mini(points.size()-1,i+1)]-points[i]).normalized() if i<points.size()-1 else before
		var sa = before.cross(n).normalized()
		var sb = after.cross(n).normalized()
		var miter = (sa+sb).normalized()
		var offset = miter*minf(half_width*2,half_width/maxf(0.5,miter.dot(sb)))
		left.append(project(points[i]-offset))
		right.append(project(points[i]+offset))
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		for vertex in [left[i],right[i],right[i+1],left[i],right[i+1],left[i+1]]:
			surface.set_normal(normal_at(vertex))
			surface.add_vertex(vertex)
	return surface.commit()
