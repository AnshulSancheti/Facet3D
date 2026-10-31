extends Node3D
const Ink = preload("res://scripts/presentation/flat_ink.gd")
const Topology = preload("res://scripts/geometry/cube_topology.gd")
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
var pieces: Dictionary = {}
var materials: Dictionary = {}
var cell_owner: Dictionary = {}
var level: Dictionary
var active_tweens: Array[Tween] = []
var build_version = 0
func material(color: Color, luminous: bool = true) -> StandardMaterial3D:
	var key = color.to_html()+str(luminous)
	if materials.has(key): return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.62
	m.metallic = 0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if luminous:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0
	materials[key] = m
	return m
func mesh_at(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.position = pos
	return node
func arrow_color(arrow: Dictionary, removed: Array) -> Color:
	if Rules.is_locked(level,removed,arrow): return Color("c8cbed")
	if int(arrow.get("key",-1))>=0: return Color("f2d4a2")
	return Color("b5f1e1")
func build(definition: Dictionary, removed: Array) -> void:
	build_version += 1
	for tween in active_tweens:
		if tween.is_valid(): tween.kill()
	active_tweens.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	pieces.clear()
	cell_owner.clear()
	level = definition
	var sculpture = MeshInstance3D.new()
	sculpture.name = "CeramicSculpture"
	sculpture.mesh = preload("res://scripts/presentation/ceramic_sculpture.gd").create_mesh()
	var ceramic = material(Color("737b9e"),false).duplicate() as StandardMaterial3D
	ceramic.vertex_color_use_as_albedo = true
	sculpture.material_override = ceramic
	add_child(sculpture)
	var body = StaticBody3D.new()
	body.name = "CubeSelection"
	body.set_meta("cube_surface",true)
	add_child(body)
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3.ONE*2.97
	collision.shape = box
	body.add_child(collision)
	for arrow in level.arrows:
		if not Rules.removed_has(removed,int(arrow.id)): add_arrow(arrow,removed)
func body_points(arrow: Dictionary) -> Array[Vector3]:
	# Round bends inside their own logical cell; seams use the shared topology.
	var result: Array[Vector3] = []
	var cells: Array = arrow.cells
	var step = 3.0/int(level.size)
	for i in cells.size():
		var center = Topology.world_position(cells[i],int(level.size))
		if i>0 and int(cells[i-1][0])!=int(cells[i][0]):
			var seam = Topology.path_samples([cells[i-1],cells[i]],int(level.size))
			for j in range(1,seam.size()-1): result.append(seam[j])
		if i>0 and i<cells.size()-1 and int(cells[i-1][0])==int(cells[i][0]) and int(cells[i][0])==int(cells[i+1][0]):
			var before = (Topology.world_position(cells[i-1],int(level.size))-center).normalized()
			var after = (Topology.world_position(cells[i+1],int(level.size))-center).normalized()
			if before.dot(after)>-0.99:
				var a = center+before*step*0.22
				var b = center+after*step*0.22
				for j in 5:
					var t = float(j)/4.0
					result.append(a*(1-t)*(1-t)+center*2*t*(1-t)+b*t*t)
				continue
		if i==cells.size()-1 and i>0 and int(cells[i-1][0])==int(cells[i][0]):
			var before = (Topology.world_position(cells[i-1],int(level.size))-center).normalized()
			var forward = Topology.direction_vector(int(cells[i][0]),int(arrow.head_direction))
			if absf(before.dot(forward))<0.1:
				var a = center+before*step*0.30
				var b = center+forward*step*0.25
				for j in 5:
					var t = float(j)/4.0
					result.append(a*(1-t)*(1-t)+center*2*t*(1-t)+b*t*t)
				continue
		result.append(center)
	return result
func append_strip(surface: SurfaceTool, a: Vector3, b: Vector3, width: float) -> void:
	if a.distance_squared_to(b)>0.000001: surface.append_from(Ink.strip(a,b,width),0,Transform3D.IDENTITY)
func add_arrow(arrow: Dictionary, removed: Array) -> void:
	var id = int(arrow.id)
	var root = Node3D.new()
	root.name = "Arrow_%d" % id
	add_child(root)
	pieces[id] = root
	for cell in arrow.cells: cell_owner[Rules.cell_index(cell,int(level.size))] = id
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step = 3.0/int(level.size)
	var width = step*0.095
	var points = body_points(arrow)
	var head = Topology.world_position(arrow.cells.back(),int(level.size))
	var face = int(arrow.cells.back()[0])
	var forward = Topology.direction_vector(face,int(arrow.head_direction))
	if points.back().distance_to(head)>step*0.1: head = points.back()
	var normal = Topology.normal(face)
	var side = forward.cross(normal).normalized()
	if points.size()==1: points.push_front(head-forward*step*0.35)
	points.append(head+forward*step*0.14)
	surface.append_from(Ink.polyline(points,width),0,Transform3D.IDENTITY)
	var chevron: Array[Vector3] = [head-forward*step*0.19+side*step*0.165,head+forward*step*0.14,head-forward*step*0.19-side*step*0.165]
	surface.append_from(Ink.polyline(chevron,width*0.70),0,Transform3D.IDENTITY)
	surface.append_from(Ink.disc(points[0],width),0,Transform3D.IDENTITY)
	var special = int(arrow.get("key",-1))>=0 or int(arrow.get("lock",-1))>=0
	if special: append_badge(surface,arrow,step)
	var color = arrow_color(arrow,removed)
	mesh_at(root,surface.commit(),Vector3.ZERO,color).name = "Ink"
	if special:
		var cell: Array = arrow.cells.front()
		var badge_face = int(cell[0])
		var label = Label3D.new()
		label.text = str(int(arrow.key)) if int(arrow.get("key",-1))>=0 else str(int(arrow.lock))
		label.font_size = 28
		label.pixel_size = step*0.009
		label.outline_size = 1
		label.modulate = color
		label.no_depth_test = false
		label.basis = Basis(Topology.RIGHTS[badge_face],-Topology.DOWNS[badge_face],Topology.normal(badge_face))
		root.add_child(label)
		label.position = Ink.project(Topology.world_position(cell,int(level.size))+Topology.RIGHTS[badge_face]*step*0.34+Topology.DOWNS[badge_face]*step*0.28)+Topology.normal(badge_face)*0.002
func append_badge(surface: SurfaceTool, arrow: Dictionary, step: float) -> void:
	var cell: Array = arrow.cells.front()
	var face = int(cell[0])
	var right: Vector3 = Topology.RIGHTS[face]
	var down: Vector3 = Topology.DOWNS[face]
	var center = Topology.world_position(cell,int(level.size))+right*step*0.28-down*step*0.18
	if int(arrow.get("key",-1))>=0:
		surface.append_from(Ink.disc(center,step*0.09,step*0.06),0,Transform3D.IDENTITY)
		append_strip(surface,center+down*step*0.07,center+down*step*0.28,step*0.025)
		append_strip(surface,center+down*step*0.23,center+down*step*0.23+right*step*0.09,step*0.025)
	else:
		var points = [Vector2(-0.09,0),Vector2(-0.09,0.18),Vector2(0.09,0.18),Vector2(0.09,0),Vector2(-0.09,0)]
		for i in range(points.size()-1): append_strip(surface,center+(right*points[i].x+down*points[i].y)*step,center+(right*points[i+1].x+down*points[i+1].y)*step,step*0.025)
		for i in 8:
			var a = PI+PI*i/8.0
			var b = PI+PI*(i+1)/8.0
			append_strip(surface,center+(right*cos(a)*0.06+down*sin(a)*0.1)*step,center+(right*cos(b)*0.06+down*sin(b)*0.1)*step,step*0.025)
func sync_state(removed: Array) -> void:
	for arrow in level.arrows:
		var id = int(arrow.id)
		if not pieces.has(id): continue
		var color = arrow_color(arrow,removed)
		pieces[id].get_node("Ink").material_override = material(color)
		for child in pieces[id].get_children():
			if child is Label3D: child.modulate = color
func restore_arrow(id: int, removed: Array) -> void:
	add_arrow(Rules.arrow_by_id(level,id),removed)
	sync_state(removed)
func select_cell(local_position: Vector3, local_normal: Vector3) -> int:
	var face = 0
	var best = -INF
	for i in 6:
		var score = Topology.normal(i).dot(local_normal)
		if score>best: best = score; face = i
	var size = int(level.size)
	var col = clampi(floori((local_position.dot(Topology.RIGHTS[face])/1.5+1)*size*0.5),0,size-1)
	var row = clampi(floori((local_position.dot(Topology.DOWNS[face])/1.5+1)*size*0.5),0,size-1)
	return int(cell_owner.get(Rules.cell_index([face,row,col],size),-1))
func samples(arrow: Dictionary) -> Array[Vector3]:
	var raw = body_points(arrow)
	var points: Array[Vector3] = [Ink.project(raw[0])]
	for i in range(raw.size()-1):
		var steps = maxi(1,ceili(raw[i].distance_to(raw[i+1])/0.025))
		for j in range(1,steps+1): points.append(Ink.project(raw[i].lerp(raw[i+1],float(j)/steps)))
	var head: Array = arrow.cells.back()
	var forward = Topology.direction_vector(int(head[0]),int(arrow.head_direction))
	# Leave tangentially from this face; never fold onto the next face.
	var distance_to_edge = 1.5-Topology.world_position(head,int(level.size)).dot(forward)
	points.append(points.back()+forward*(distance_to_edge+4.0))
	return points
func at_distance(points: Array[Vector3],distance: float) -> Vector3:
	for i in range(points.size()-1):
		var length = points[i].distance_to(points[i+1])
		if distance<=length: return points[i].lerp(points[i+1],clampf(distance/maxf(length,0.00001),0,1))
		distance -= length
	return points.back()
func draw_moving(root: Node3D,points: Array[Vector3],distance: float,length: float,color: Color) -> void:
	var count = maxi(2,ceili(length/0.035))
	if not root.has_meta("moving_segments"):
		for child in root.get_children():
			root.remove_child(child)
			child.queue_free()
		var nodes: Array = []
		var quad = QuadMesh.new()
		quad.size = Vector2.ONE
		for i in count: nodes.append(mesh_at(root,quad,Vector3.ZERO,color))
		root.set_meta("moving_segments",nodes)
	var nodes: Array = root.get_meta("moving_segments")
	for i in count:
		var a = at_distance(points,distance+length*float(i)/count)
		var b = at_distance(points,distance+length*float(i+1)/count)
		var node: MeshInstance3D = nodes[i]
		node.position = (a+b)*0.5
		node.visible = a.distance_to(b)>0.001
		if not node.visible: continue
		var along = (b-a).normalized()
		var side = along.cross(Ink.normal_at(node.position)).normalized()
		if side.length_squared()<0.1:
			side = along.cross(Vector3.UP).normalized()
			if side.length_squared()<0.1: side = Vector3.RIGHT
		node.basis = Basis(side,along,side.cross(along).normalized())
		node.scale = Vector3(3.0/int(level.size)*0.19,a.distance_to(b)+0.003,1)
func highlight(id: int, reduced: bool = false) -> void:
	if not pieces.has(id): return
	var mesh: MeshInstance3D = pieces[id].get_node("Ink")
	var glow = mesh.material_override.duplicate() as StandardMaterial3D
	mesh.material_override = glow
	if reduced: glow.emission_energy_multiplier = 0.65; return
	var tween = create_tween().bind_node(pieces[id]).set_loops(2)
	active_tweens.append(tween)
	tween.tween_property(glow,"emission_energy_multiplier",0.8,0.4)
	tween.tween_property(glow,"emission_energy_multiplier",0.0,0.6)
func remove_arrow(id: int, reduced: bool) -> void:
	if not pieces.has(id): return
	var token = build_version
	var root: Node3D = pieces[id]
	var arrow = Rules.arrow_by_id(level,id)
	var points = samples(arrow)
	var length = 0.0
	var body = body_points(arrow)
	for i in range(body.size()-1): length += Ink.project(body[i]).distance_to(Ink.project(body[i+1]))
	length = maxf(length,3.0/int(level.size)*0.4)
	var total = 0.0
	for i in range(points.size()-1): total += points[i].distance_to(points[i+1])
	var duration = 0.10 if reduced else clampf((total-length)*0.13,0.5,1.3)
	var tween = create_tween().bind_node(root)
	active_tweens.append(tween)
	if not reduced:
		var color = arrow_color(arrow,[])
		tween.tween_method(func(value): draw_moving(root,points,value,length,color),0.0,maxf(0,total-length),duration)
	tween.tween_method(func(value):
		for mesh in root.find_children("*","MeshInstance3D",true,false): mesh.transparency = value,0.0,1.0,0.10)
	# A killed tween does not emit finished. Timer completion makes restart safe.
	await get_tree().create_timer(duration+0.11).timeout
	if token!=build_version or not is_instance_valid(root): return
	for cell in arrow.cells: cell_owner.erase(Rules.cell_index(cell,int(level.size)))
	pieces.erase(id)
	remove_child(root)
	root.queue_free()
