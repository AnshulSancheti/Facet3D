extends RefCounted
## Deterministic reverse packing, followed by proof-preserving tail growth.
const VERSION = "facet-edge-2.1.0"
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
const Topology = preload("res://scripts/geometry/cube_topology.gd")
const Compiled = preload("res://scripts/solver/compiled_board.gd")
const TIER_NAMES = ["Beginner","Easy","Medium","Hard","Expert"]
static var _tables: Dictionary = {}
var _rng = 1
func _random(limit: int) -> int:
	_rng = (_rng*16807)%2147483647
	return int(_rng%maxi(limit,1))
static func table(size: int) -> Dictionary:
	if _tables.has(size): return _tables[size]
	var cells: Array = []
	var neighbors: Array = []
	var lanes: Array = []
	for face in 6:
		for row in size:
			for col in size: cells.append([face,row,col])
	for cell in cells:
		var adjacent: Array = []
		var rays: Array = []
		for d in 4:
			adjacent.append(Rules.cell_index(Topology.step(cell,d,size).cell,size))
			rays.append(Rules.exit_cells({"size":size},{"cells":[cell],"head_direction":d}).map(func(c): return Rules.cell_index(c,size)))
		neighbors.append(adjacent)
		lanes.append(rays)
	var result = {"cells":cells,"neighbors":neighbors,"lanes":lanes}
	_tables[size] = result
	return result
func generate_config(config: Dictionary) -> Dictionary:
	return generate(int(config.get("seed",1)),int(config.get("difficulty",0)),int(config.get("level_number",0)),config)
func generate(seed_value: int, tier: int = 0, number: int = 1, options: Dictionary = {}) -> Dictionary:
	tier = clampi(tier,0,4)
	var tutorial = number>=1 and number<=5
	var size = int(options.get("board_size",5 if tutorial else [9,13,17,21,25][tier]))
	var max_length = int(options.get("max_length",6 if tutorial else [7,10,12,15,15][tier]))
	var max_attempts = int(options.get("max_attempts",16))
	if size<3 or size>25 or max_length<2 or max_length>15 or max_attempts<1 or max_attempts>32:
		return {"error":"Configuration outside supported bounds","generator_version":VERSION,"seed":seed_value}
	var data = table(size)
	var low = float(options.get("min_density",[0.55,0.65,0.75,0.80,0.78][tier]))
	var high = float(options.get("max_density",[0.65,0.75,0.82,0.87,0.83][tier]))
	if low<=0 or high<low or high>0.95: return {"error":"Invalid density bounds"}
	var started = Time.get_ticks_usec()
	for attempt in max_attempts:
		_rng = posmod(seed_value+attempt*104729,2147483646)+1
		var target = floori(data.cells.size()*(low+minf(0.02,(high-low)*0.4)+float(_random(1000))/1000.0*maxf(0,high-low-0.02)))
		var cap = floori(data.cells.size()*high)
		var occupied = PackedInt32Array()
		occupied.resize(data.cells.size())
		occupied.fill(-1)
		var bodies: Array = []
		var directions: Array = []
		var wraps = 0
		var covered = 0
		var candidates = 0
		var required_count = [1,6,8,8,10][number-1] if tutorial else 768
		if number==1:
			bodies = [[Rules.cell_index([0,2,3],size),Rules.cell_index([0,2,2],size),Rules.cell_index([0,2,1],size)]]
			directions = [0]
			for cell in bodies[0]: occupied[cell] = 0
			covered = 3
		if number==3:
			var footprints = [[[0,3,3],[0,3,2],[0,3,1]],[[0,1,4],[0,2,4],[0,3,4]],[[0,0,2],[0,0,3],[0,0,4]]]
			bodies = []
			directions = [0,3,2]
			for footprint in footprints:
				var indices: Array = []
				for cell in footprint:
					var index = Rules.cell_index(cell,size)
					indices.append(index)
					occupied[index] = bodies.size()
				bodies.append(indices)
			covered = 9
		while bodies.size()<required_count and candidates<maxi(40000,size*size*240) and (tutorial or covered<target):
			candidates += 1
			var head = _random(data.cells.size())
			var direction = _random(4)
			if occupied[head]>=0: continue
			var forbidden: Dictionary = {}
			var clear = true
			for cell in data.lanes[head][direction]:
				forbidden[cell] = true
				if occupied[cell]>=0: clear = false; break
			if not clear: continue
			var roll = _random(100)
			var target_length = 2+_random(2) if roll<20 else (4+_random(maxi(1,mini(9,max_length)-3)) if roll<50 or max_length<10 else 10+_random(max_length-9))
			target_length = mini(target_length,max_length)
			var first: int = data.neighbors[head][(direction+2)%4]
			if occupied[first]>=0 or forbidden.has(first): continue
			var body: Array = [head,first] # Head first during construction.
			var seen: Dictionary = {head:true,first:true}
			var seams = int(data.cells[head][0]!=data.cells[first][0])
			var current = first
			while body.size()<target_length:
				var choices: Array = []
				for next in data.neighbors[current]:
					if occupied[next]>=0 or seen.has(next) or forbidden.has(next) or seams+int(data.cells[current][0]!=data.cells[next][0])>2: continue
					var weight = 1
					for neighbor in data.neighbors[next]:
						if occupied[neighbor]>=0 or seen.has(neighbor): weight += 2
					for repeat in weight: choices.append(next)
				if choices.is_empty(): break
				var next: int = choices[_random(choices.size())]
				seams += int(data.cells[current][0]!=data.cells[next][0])
				body.append(next)
				seen[next] = true
				current = next
			if body.size()!=target_length: continue
			if seams>0 and (tutorial or wraps>=maxi(2,floori((bodies.size()+1)*0.18))): continue
			if not tutorial and covered+body.size()>cap: continue
			for cell in body: occupied[cell] = bodies.size()
			bodies.append(body)
			directions.append(direction)
			covered += body.size()
			wraps += int(seams>0)
		if tutorial and bodies.size()!=required_count: continue
		# A new tail cell may only block earlier inserted arrows. Descending
		# insertion order remains a constructive solution after every extension.
		if not tutorial:
			var lane_max = PackedInt32Array()
			lane_max.resize(data.cells.size())
			lane_max.fill(-1)
			for id in bodies.size():
				for cell in data.lanes[bodies[id][0]][directions[id]]: lane_max[cell] = maxi(lane_max[cell],id)
			for sweep in 15:
				var progress = false
				for id in range(bodies.size()-1,-1,-1):
					var body: Array = bodies[id]
					if body.size()>=max_length or covered>=target: continue
					var seams = 0
					for i in range(1,body.size()): seams += int(data.cells[body[i-1]][0]!=data.cells[body[i]][0])
					var choices: Array = []
					for next in data.neighbors[body.back()]:
						var crossing = int(data.cells[body.back()][0]!=data.cells[next][0])
						if occupied[next]>=0 or lane_max[next]>=id or data.lanes[body[0]][directions[id]].has(next) or seams+crossing>2: continue
						if crossing>0 and seams==0 and wraps+1>floori(bodies.size()*0.2): continue
						choices.append(next)
					if choices.is_empty(): continue
					var next: int = choices[_random(choices.size())]
					if seams==0 and data.cells[body.back()][0]!=data.cells[next][0]: wraps += 1
					body.append(next)
					occupied[next] = id
					covered += 1
					progress = true
				if not progress: break
			if covered<target or bodies.size()>768: continue
		var arrows: Array = []
		var face_coverage = [0,0,0,0,0,0]
		var bent = 0
		var long_count = 0
		var short_count = 0
		var lengths: Dictionary = {}
		for id in bodies.size():
			var cells: Array = []
			for index in bodies[id]:
				cells.push_front(data.cells[index].duplicate())
				face_coverage[int(data.cells[index][0])] += 1
			var arrow = {"id":id,"cells":cells,"head_direction":directions[id],"key":-1,"lock":-1}
			arrows.append(arrow)
			if bend_count(arrow,size)>0: bent += 1
			if cells.size()>=10: long_count += 1
			if cells.size()<=3: short_count += 1
			lengths[str(cells.size())] = int(lengths.get(str(cells.size()),0))+1
		var min_face = float(face_coverage.min())/(size*size)
		if not tutorial and (min_face<low-0.1 or float(bent)/arrows.size()<0.60 or float(wraps)/arrows.size()<(0.05 if size>=17 else 0.10) or float(wraps)/arrows.size()>0.20): continue
		# Long arrows are a measured target, not replaced with tiny filler pieces.
		if not tutorial and max_length==15 and float(long_count)/arrows.size()<0.25: continue
		var candidate: Array = []
		for id in range(arrows.size()-1,-1,-1): candidate.append(id)
		if not tutorial: candidate = weave_dependencies(arrows,size)
		var lock_count = 0 if tutorial and number<5 else (1 if tutorial else tier+1)
		for key in lock_count:
			arrows[int(candidate[-1-key])].lock = key
			arrows[int(candidate[key])].key = key
		var level = {"schema_version":2,"ruleset":Rules.RULESET,"generator_version":VERSION,"seed":seed_value,"level_number":number,"size":size,"topology":"cube","difficulty":TIER_NAMES[tier],"difficulty_tier":tier,"arrows":arrows}
		var errors = Rules.validate(level)
		if not errors.is_empty(): continue
		var graph = Compiled.new(level).analyze()
		if graph.cyclic: continue
		var initial_moves = Compiled.new(level).legal_moves([]).size()
		if not tutorial and (float(initial_moves)/arrows.size()>[0.15,0.10,0.07,0.05,0.04][tier] or int(graph.depth)<[12,25,40,60,80][tier]): continue
		if number==3 and int(graph.depth)<2: continue
		if number==2:
			var faces: Dictionary = {}
			for arrow in arrows:
				for cell in arrow.cells: faces[int(cell[0])] = true
			if faces.size()<3: continue
		if number==4 and bent<4: continue
		if not Rules.replay_solution(level,candidate): continue
		level.construction_solution = candidate
		level.solution = graph.order
		level.validation = {"valid":true,"solvable":true,"attempts":attempt+1,"candidate_attempts":candidates,"explored_states":arrows.size(),"dependency_depth":graph.depth,"initial_moves":initial_moves,"initial_move_fraction":float(initial_moves)/arrows.size(),"minimum_dependency_depth":[12,25,40,60,80][tier],"maximum_initial_move_fraction":[0.15,0.10,0.07,0.05,0.04][tier],"density":float(covered)/data.cells.size(),"face_density":face_coverage.map(func(value): return float(value)/(size*size)),"bent_fraction":float(bent)/arrows.size(),"wrap_fraction":float(wraps)/arrows.size(),"long_fraction":float(long_count)/arrows.size(),"short_fraction":float(short_count)/arrows.size(),"length_histogram":lengths,"locks":lock_count,"generation_usec":Time.get_ticks_usec()-started}
		return level
	return {"error":"Generation budget exhausted","seed":seed_value,"generator_version":VERSION,"attempts":max_attempts}
# Reorient entire bodies, never add invisible dependencies. Both endpoint
# orientations are evaluated against the same occupied geometry. At each step
# choose a legal endpoint with the deepest already-cleared blocker ancestry.
# Deferred boundary arrows can then point inward instead of being free exits.
func weave_dependencies(arrows: Array, size: int) -> Array:
	var level = {"size":size,"arrows":arrows}
	var occupied = Rules.occupancy(level)
	var variants: Array = []
	for arrow in arrows:
		var choices: Array = []
		for flip in 2:
			var option = arrow.duplicate(true)
			if flip==1:
				option.cells.reverse()
				for d in 4:
					var step = Topology.step(option.cells[-2],d,size)
					if Topology.same_cell(step.cell,option.cells[-1]): option.head_direction = step.direction; break
			for heading in 4:
				option.head_direction = heading
				if not Rules.trajectory_valid(level,option): continue
				var blockers: Dictionary = {}
				for cell in Rules.exit_cells(level,option):
					var owner = int(occupied.get(Rules.cell_index(cell,size),-1))
					if owner>=0 and owner!=int(arrow.id): blockers[owner] = true
				choices.append({"arrow":option.duplicate(true),"blockers":blockers.keys()})
		variants.append(choices)
	var cleared: Dictionary = {}
	var depths: Dictionary = {}
	var order: Array = []
	while order.size()<arrows.size():
		var best_id = -1
		var best_option: Dictionary = {}
		var best_score = -1
		var best_depth = 0
		for id in arrows.size():
			if cleared.has(id): continue
			for option in variants[id]:
				var legal = true
				var depth = 0
				for blocker in option.blockers:
					if not cleared.has(blocker): legal = false; break
					depth = maxi(depth,int(depths[blocker])+1)
				if not legal: continue
				var score = depth*1000+option.blockers.size()*20
				if score>best_score:
					best_score = score
					best_id = id
					best_option = option.arrow
					best_depth = depth
		assert(best_id>=0,"Original constructive orientations guarantee an available move")
		arrows[best_id] = best_option
		cleared[best_id] = true
		depths[best_id] = best_depth
		order.append(best_id)
	return order
static func bend_count(arrow: Dictionary, size: int) -> int:
	var previous = -1
	var count = 0
	for i in range(1,arrow.cells.size()):
		for d in 4:
			var step = Topology.step(arrow.cells[i-1],d,size)
			if Topology.same_cell(step.cell,arrow.cells[i]):
				if previous>=0 and d!=previous: count += 1
				previous = int(step.direction)
				break
	return count
static func date_seed(utc_date: String) -> int:
	var result = 314159
	for byte in (VERSION+":"+utc_date).to_utf8_buffer(): result = (result*31+int(byte))%2147483647
	return result
func daily(utc_date: String, options: Dictionary = {}) -> Dictionary:
	var config = {"max_attempts":8}
	config.merge(options,true)
	var level = generate(date_seed(utc_date),4,0,config)
	if level.has("error"):
		var reason: String = level.error
		var campaign = JSON.parse_string(FileAccess.get_file_as_string("res://resources/levels/campaign.json"))
		level = campaign.levels[80+posmod(date_seed(utc_date),20)].duplicate(true)
		level["fallback"] = true
		level["fallback_reason"] = reason
		level["fallback_source_level"] = level.level_number
		level["daily_seed"] = date_seed(utc_date)
	level.validation.erase("generation_usec")
	level["daily_date_utc"] = utc_date
	return level
