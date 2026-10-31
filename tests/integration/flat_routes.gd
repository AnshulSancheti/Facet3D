extends SceneTree
const Ink = preload("res://scripts/presentation/flat_ink.gd")
const Topology = preload("res://scripts/geometry/cube_topology.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	# Every face marking has zero thickness along its normal.
	for face in 6:
		var a = Topology.world_position([face,1,1],4)
		var b = Topology.world_position([face,1,2],4)
		var bent: Array[Vector3] = [a,b,b+Topology.direction_vector(face,1)*0.3]
		for mesh in [Ink.strip(a,b,0.022),Ink.polyline(bent,0.022),Ink.disc(a,0.04),Ink.disc(a,0.055,0.035)]:
			var vertices = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				if absf(vertex.dot(Topology.normal(face))-1.497)>0.0001:
					printerr("FLAT_ROUTE_FAIL: surface marking has thickness")
					quit(1)
					return
	# Neighboring ribbon sections share the exact same miter vertices.
	var joined: Array[Vector3] = [Vector3(-0.5,0,1.555),Vector3(0,0,1.555),Vector3(0,0.5,1.555)]
	var join_vertices = Ink.polyline(joined,0.04).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert(join_vertices[5].is_equal_approx(join_vertices[6]) and join_vertices[2].is_equal_approx(join_vertices[7]),"Continuous bends have no disconnected quads")
	# All corner ink is projected to the bevel's offset surface.
	var cells = [[0,1,3],[3,1,0]]
	var seam = Topology.path_samples(cells,4)
	for i in range(seam.size()-1):
		var mesh = Ink.strip(seam[i],seam[i+1],0.022)
		for vertex in mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var center = vertex.clamp(Vector3.ONE*-Ink.INNER,Vector3.ONE*Ink.INNER)
			if absf(vertex.distance_to(center)-(Ink.RADIUS+Ink.LIFT))>0.0001:
				printerr("FLAT_ROUTE_FAIL: corner ink leaves surface")
				quit(1)
				return
	var view = preload("res://scripts/gameplay/puzzle_view.gd").new()
	root.add_child(view)
	var level = JSON.parse_string(FileAccess.get_file_as_string("res://resources/levels/campaign.json")).levels[64]
	view.build(level,[])
	for mesh in view.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is ArrayMesh:
			printerr("FLAT_ROUTE_FAIL: static route contains volumetric primitive")
			quit(1)
			return
	var arrow: Dictionary = level.arrows[0]
	view.draw_moving(view.pieces[int(arrow.id)],view.samples(arrow),0.12,0.5,Color("b5f1e1"))
	for mesh in view.pieces[int(arrow.id)].find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh is QuadMesh:
			printerr("FLAT_ROUTE_FAIL: removal contains volumetric primitive")
			quit(1)
			return
	view.queue_free()
	await process_frame
	print("FLAT_ROUTES_PASS: six face planes, surface-conforming corners, no volumetric static or moving arrow geometry")
	quit()
