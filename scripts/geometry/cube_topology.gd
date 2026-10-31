extends RefCounted
## Cube surface chart. The same chart drives the rules, meshes and picking.
## Row increases down each face; E,S,W,N are 0,1,2,3.
const NORMALS = [Vector3(0,0,1), Vector3(0,0,-1), Vector3(-1,0,0), Vector3(1,0,0), Vector3(0,1,0), Vector3(0,-1,0)]
const RIGHTS = [Vector3(1,0,0), Vector3(-1,0,0), Vector3(0,0,1), Vector3(0,0,-1), Vector3(1,0,0), Vector3(1,0,0)]
const DOWNS = [Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,0,1), Vector3(0,0,-1)]

static func normal(face: int) -> Vector3:
	return NORMALS[face]

static func valid(cell: Array, size: int) -> bool:
	if cell.size() != 3: return false
	for coordinate in cell:
		if not (coordinate is int or coordinate is float): return false
		if not is_finite(float(coordinate)) or float(coordinate)!=float(int(coordinate)): return false
	return int(cell[0]) >= 0 and int(cell[0]) < 6 and int(cell[1]) >= 0 and int(cell[1]) < size and int(cell[2]) >= 0 and int(cell[2]) < size

static func key(cell: Array) -> String:
	return "%d:%d:%d" % [cell[0],cell[1],cell[2]]

static func same_cell(a: Array, b: Array) -> bool:
	# Godot JSON numbers decode as floats; Array equality is type-sensitive.
	return a.size()==3 and b.size()==3 and int(a[0])==int(b[0]) and int(a[1])==int(b[1]) and int(a[2])==int(b[2])

static func world_position(cell: Array, size: int, half_extent: float = 1.5, lift: float = 0.055) -> Vector3:
	var face := int(cell[0])
	var u := (float(cell[2]) + 0.5) * 2.0 / size - 1.0
	var v := (float(cell[1]) + 0.5) * 2.0 / size - 1.0
	return NORMALS[face] * (half_extent + lift) + (RIGHTS[face]*u + DOWNS[face]*v) * half_extent

static func direction_vector(face: int, direction: int) -> Vector3:
	match direction:
		0: return RIGHTS[face]
		1: return DOWNS[face]
		2: return -RIGHTS[face]
		_: return -DOWNS[face]

static func step(cell: Array, direction: int, size: int) -> Dictionary:
	if not valid(cell,size) or direction < 0 or direction > 3:
		return {}
	var face := int(cell[0])
	var row: int = int(cell[1]) + int([0,1,0,-1][direction])
	var col: int = int(cell[2]) + int([1,0,-1,0][direction])
	if row >= 0 and row < size and col >= 0 and col < size:
		return {"cell":[face,row,col], "direction":direction}
	# Fold the tangent 90 degrees. The adjacent normal is the outgoing tangent.
	var next_face: int = NORMALS.find(direction_vector(face,direction))
	var p := world_position(cell,size,1.0,0.0)
	var edge_p := p + direction_vector(face,direction) / float(size)
	var next_u: float = edge_p.dot(RIGHTS[next_face])
	var next_v: float = edge_p.dot(DOWNS[next_face])
	var next_col := clampi(int(floor((next_u+1.0)*size/2.0)),0,size-1)
	var next_row := clampi(int(floor((next_v+1.0)*size/2.0)),0,size-1)
	var tangent: Vector3 = -NORMALS[face]
	var next_direction := 0
	for d in 4:
		if direction_vector(next_face,d).is_equal_approx(tangent):
			next_direction = d
	return {"cell":[next_face,next_row,next_col], "direction":next_direction}

static func adjacent(a: Array, b: Array, size: int) -> bool:
	for direction in 4:
		if same_cell(step(a,direction,size).get("cell",[]),b):
			return true
	return false

static func path_samples(cells: Array, size: int, half_extent: float = 1.5, lift: float = 0.055) -> PackedVector3Array:
	var result := PackedVector3Array()
	for i in cells.size():
		var p := world_position(cells[i],size,half_extent,lift)
		if i > 0 and int(cells[i-1][0]) != int(cells[i][0]):
			# A rounded quarter-circle seam stays outside the board instead of cutting it.
			var a := world_position(cells[i-1],size,half_extent,lift)
			var na := normal(int(cells[i-1][0]))
			var nb := normal(int(cells[i][0]))
			var edge := a + nb * (half_extent - a.dot(nb))
			edge -= na * lift
			for j in range(1,5):
				var t := float(j)/5.0
				var n := (na*(1.0-t)+nb*t).normalized()
				result.append(edge + n*lift)
		result.append(p)
	return result
