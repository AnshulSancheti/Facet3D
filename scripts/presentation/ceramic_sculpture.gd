extends RefCounted
## Sharp face normals and a fine inset rim make the six faces easy to read.
static var cached_mesh: ArrayMesh
static func create_mesh() -> ArrayMesh:
	if cached_mesh != null: return cached_mesh
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var extent = 1.49
	var ticks = [-extent,-extent+0.014,extent-0.014,extent]
	var topology = preload("res://scripts/geometry/cube_topology.gd")
	var face_values = [0.87,0.78,0.81,0.87,0.93,0.74]
	for face in 6:
		for row in 3:
			for col in 3:
				var rim = row!=1 or col!=1
				var tint = Color(0.98,0.99,1.0) if rim else Color.WHITE*float(face_values[face])
				tint.a = 1.0
				var corners = [Vector2(ticks[col],ticks[row]),Vector2(ticks[col+1],ticks[row]),Vector2(ticks[col+1],ticks[row+1]),Vector2(ticks[col],ticks[row+1])]
				for index in [0,2,1,0,3,2]:
					var point: Vector2 = corners[index]
					var p: Vector3 = topology.NORMALS[face]*extent+topology.RIGHTS[face]*point.x+topology.DOWNS[face]*point.y
					surface.set_normal(topology.NORMALS[face])
					surface.set_color(tint)
					surface.add_vertex(p)
	cached_mesh = surface.commit()
	return cached_mesh
