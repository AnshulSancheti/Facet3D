extends RefCounted
## Face-edge snake rules. Only the head's straight lane is new occupied space.
const RULESET = "face_edge_snake_v2"
const Topology = preload("res://scripts/geometry/cube_topology.gd")
static func removed_has(removed: Array, id: int) -> bool:
	return removed.has(id) or removed.has(float(id))
static func arrow_by_id(level: Dictionary, id: int) -> Dictionary:
	for arrow in level.get("arrows",[]):
		if int(arrow.id)==id: return arrow
	return {}
static func cell_index(cell: Array, size: int) -> int:
	return int(cell[0])*size*size+int(cell[1])*size+int(cell[2])
static func occupancy(level: Dictionary, removed: Array = []) -> Dictionary:
	var occupied: Dictionary = {}
	for arrow in level.get("arrows",[]):
		if removed_has(removed,int(arrow.id)): continue
		for cell in arrow.cells: occupied[cell_index(cell,int(level.size))] = int(arrow.id)
	return occupied
static func exit_cells(level: Dictionary, arrow: Dictionary) -> Array:
	var result: Array = []
	if arrow.get("cells",[]).is_empty(): return result
	var head: Array = arrow.cells.back()
	var direction = int(arrow.get("head_direction",-1))
	if direction<0 or direction>3: return result
	var row = int(head[1])+[0,1,0,-1][direction]
	var col = int(head[2])+[1,0,-1,0][direction]
	while row>=0 and row<int(level.size) and col>=0 and col<int(level.size):
		result.append([int(head[0]),row,col])
		row += [0,1,0,-1][direction]
		col += [1,0,-1,0][direction]
	return result
static func is_locked(level: Dictionary, removed: Array, arrow: Dictionary) -> bool:
	var lock_id = int(arrow.get("lock",-1))
	if lock_id<0: return false
	for other in level.arrows:
		if int(other.get("key",-1))==lock_id and removed_has(removed,int(other.id)): return false
	return true
static func blockers(level: Dictionary, removed: Array, id: int, occupied: Dictionary = {}) -> Array:
	var result: Array = []
	var arrow = arrow_by_id(level,id)
	if arrow.is_empty(): return result
	if occupied.is_empty(): occupied = occupancy(level,removed)
	for cell in exit_cells(level,arrow):
		var owner = int(occupied.get(cell_index(cell,int(level.size)),-1))
		if owner>=0 and owner!=id and not result.has(owner): result.append(owner)
	result.sort()
	return result
static func can_remove(level: Dictionary, removed: Array, id: int, occupied: Dictionary = {}) -> bool:
	var arrow = arrow_by_id(level,id)
	return not arrow.is_empty() and not removed_has(removed,id) and not is_locked(level,removed,arrow) and trajectory_valid(level,arrow) and blockers(level,removed,id,occupied).is_empty()
static func legal_moves(level: Dictionary, removed: Array = []) -> Array:
	var occupied = occupancy(level,removed)
	var result: Array = []
	for arrow in level.get("arrows",[]):
		if can_remove(level,removed,int(arrow.id),occupied): result.append(int(arrow.id))
	result.sort()
	return result
static func apply_move(level: Dictionary, removed: Array, id: int) -> Dictionary:
	if not can_remove(level,removed,id): return {"valid":false,"removed":removed.duplicate()}
	var next = removed.duplicate()
	next.append(id)
	return {"valid":true,"removed":next}
static func trajectory_valid(level: Dictionary, arrow: Dictionary) -> bool:
	var cells: Array = arrow.get("cells",[])
	var size = int(level.get("size",0))
	var raw_direction = arrow.get("head_direction",-1)
	if not (raw_direction is int or raw_direction is float) or not is_finite(float(raw_direction)) or float(raw_direction)!=float(int(raw_direction)): return false
	var direction = int(raw_direction)
	if cells.is_empty() or cells.size()>15 or size<3 or direction<0 or direction>3: return false
	var seen: Dictionary = {}
	for i in cells.size():
		if not Topology.valid(cells[i],size): return false
		var index = cell_index(cells[i],size)
		if seen.has(index): return false
		seen[index] = true
		if i>0 and not Topology.adjacent(cells[i-1],cells[i],size): return false
	for cell in exit_cells(level,arrow):
		if seen.has(cell_index(cell,size)): return false
	return true
static func validate(level: Dictionary) -> Array:
	var errors: Array = []
	var size = int(level.get("size",0))
	if size<3 or size>25 or level.get("ruleset","")!=RULESET or int(level.get("schema_version",0))!=2:
		return ["Unsupported board schema/ruleset/size"]
	if not level.get("arrows") is Array or level.arrows.is_empty() or level.arrows.size()>768: return ["Invalid arrow count"]
	var occupied: Dictionary = {}
	var ids: Dictionary = {}
	var keys: Dictionary = {}
	for arrow in level.arrows:
		if not arrow is Dictionary or not arrow.has_all(["id","cells","head_direction"]) or not arrow.cells is Array:
			errors.append("Malformed arrow")
			continue
		if arrow.has("route"): errors.append("Legacy escape tracks are forbidden")
		var id = int(arrow.id)
		if float(arrow.id)!=float(id) or id<0 or ids.has(id): errors.append("Invalid/duplicate id")
		ids[id] = true
		if not trajectory_valid(level,arrow): errors.append("Invalid body/head/self-exit %d" % id)
		if int(arrow.get("key",-1))>=0:
			if keys.has(int(arrow.key)): errors.append("Duplicate key")
			keys[int(arrow.key)] = id
		for cell in arrow.cells:
			if not Topology.valid(cell,size): continue
			var index = cell_index(cell,size)
			if occupied.has(index): errors.append("Overlapping bodies")
			occupied[index] = id
	for arrow in level.arrows:
		if not arrow is Dictionary: continue
		var lock = int(arrow.get("lock",-1))
		if lock>=0 and (not keys.has(lock) or int(keys[lock])==int(arrow.id)): errors.append("Missing/self lock key")
	return errors
static func replay_solution(level: Dictionary, solution: Array, initially_removed: Array = []) -> bool:
	# Independent occupancy simulation; does not use the compiled dependency graph.
	if not validate(level).is_empty(): return false
	var removed = initially_removed.duplicate()
	var occupied = occupancy(level,removed)
	for id_value in solution:
		var id = int(id_value)
		if not can_remove(level,removed,id,occupied): return false
		removed.append(id)
		for cell in arrow_by_id(level,id).cells: occupied.erase(cell_index(cell,int(level.size)))
	return removed.size()==level.arrows.size()
