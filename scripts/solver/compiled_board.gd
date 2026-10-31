extends RefCounted
## Indexed immutable dependencies. Removing a piece can never add a blocker.
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
var ids: Array = []
var arrows: Dictionary = {}
var prerequisites: Dictionary = {}
var adjacency: Dictionary = {}
var occupied: Dictionary = {}
func _init(level: Dictionary) -> void:
	occupied = Rules.occupancy(level)
	var keys: Dictionary = {}
	for arrow in level.arrows:
		var id = int(arrow.id)
		ids.append(id)
		arrows[id] = arrow
		adjacency[id] = []
		if int(arrow.get("key",-1))>=0: keys[int(arrow.key)] = id
	ids.sort()
	for id in ids:
		var dependencies: Array = []
		for cell in Rules.exit_cells(level,arrows[id]):
			var owner = int(occupied.get(Rules.cell_index(cell,int(level.size)),-1))
			if owner>=0 and owner!=id and not dependencies.has(owner): dependencies.append(owner)
		var lock = int(arrows[id].get("lock",-1))
		if keys.has(lock) and not dependencies.has(keys[lock]): dependencies.append(keys[lock])
		dependencies.sort()
		prerequisites[id] = dependencies
		for prerequisite in dependencies: adjacency[prerequisite].append(id)
func can_remove(removed: Array, id: int) -> bool:
	if not arrows.has(id) or Rules.removed_has(removed,id): return false
	for prerequisite in prerequisites[id]:
		if not Rules.removed_has(removed,int(prerequisite)): return false
	return true
func legal_moves(removed: Array) -> Array:
	var result: Array = []
	for id in ids:
		if can_remove(removed,id): result.append(id)
	return result
func analyze(removed: Array = []) -> Dictionary:
	var gone: Dictionary = {}
	for id in removed: gone[int(id)] = true
	var indegree: Dictionary = {}
	var depth: Dictionary = {}
	var queue: Array = []
	for id in ids:
		if gone.has(id): continue
		indegree[id] = 0
		depth[id] = 0
		for p in prerequisites[id]:
			if not gone.has(p): indegree[id] += 1
		if indegree[id]==0: queue.append(id)
	var order: Array = []
	var max_depth = 0
	var cursor = 0
	while cursor<queue.size():
		var id: int = queue[cursor]
		cursor += 1
		order.append(id)
		for child in adjacency[id]:
			if not indegree.has(child): continue
			depth[child] = maxi(int(depth[child]),int(depth[id])+1)
			max_depth = maxi(max_depth,int(depth[child]))
			indegree[child] -= 1
			if indegree[child]==0: queue.append(child)
	return {"adjacency":adjacency,"order":order,"cyclic":order.size()!=indegree.size(),"depth":max_depth}
