extends SceneTree
const Topology = preload("res://scripts/geometry/cube_topology.gd")
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
const Graph = preload("res://scripts/solver/dependency_graph.gd")
const Solver = preload("res://scripts/solver/puzzle_solver.gd")
const Generator = preload("res://scripts/generation/level_generator.gd")
var checks = 0
var failures: Array = []
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message); push_error(message)
func _init() -> void:
	_test_topology()
	_test_rules()
	_test_generation()
	print("Logic checks: %d; failures: %d" % [checks,failures.size()])
	if failures.is_empty() and OS.get_cmdline_user_args().has("--stress"): _stress()
	quit(0 if failures.is_empty() else 1)
func _test_topology() -> void:
	for size in [3,5,7,9,11,13,15,17,21,25]:
		for face in 6:
			check(Topology.normal(face).length()==1.0,"Unit face normal")
			for row in size:
				for col in size:
					var cell: Array = [face,row,col]
					for direction in 4:
						var next = Topology.step(cell,direction,size)
						check(Topology.valid(next.cell,size),"Valid folded cell")
						var back = Topology.step(next.cell,(int(next.direction)+2)%4,size)
						check(back.cell==cell,"Every cube transition is reversible")
						check(int(back.direction)==(direction+2)%4,"Reverse direction transports correctly")
						var a = Topology.world_position(cell,size,1.0,0.0)
						var b = Topology.world_position(next.cell,size,1.0,0.0)
						var expected = (2.0 if int(next.cell[0])==face else sqrt(2.0))/size
						check(absf(a.distance_to(b)-expected)<0.00001,"Adjacent centers preserve physical spacing")
	# A seam with reversed row orientation is an explicit regression case.
	check(Topology.step([4,0,0],3,4).cell==[1,0,3],"Top north to reversed Back column")
	check(Topology.step([0,1,3],0,4).cell==[3,1,0],"Front east to Right west")
	check(not Topology.valid([0,1.5,0],4),"Fractional coordinates are invalid")
	var loop: Array = [0,1,1]
	var heading = 0
	for i in 16:
		var next = Topology.step(loop,heading,4)
		loop = next.cell
		heading = int(next.direction)
	check(loop==[0,1,1] and heading==0,"Four-face geodesic closes after 4N steps")

func sample() -> Dictionary:
	return {"schema_version":2,"ruleset":Rules.RULESET,"size":5,"arrows":[
		{"id":0,"cells":[[0,2,0],[0,2,1]],"head_direction":0,"key":-1,"lock":-1},
		{"id":1,"cells":[[0,3,3],[0,2,3],[0,1,3]],"head_direction":3,"key":-1,"lock":7},
		{"id":2,"cells":[[0,0,4],[0,0,3]],"head_direction":2,"key":7,"lock":-1}]}
func _test_rules() -> void:
	var level = sample()
	check(Rules.validate(level).is_empty(),"New schema/body headings valid")
	check(Rules.blockers(level,[],0)==[1],"Head ray sees another body's middle")
	check(Rules.legal_moves(level)==[2],"Only unblocked unlocked head available")
	check(not Rules.can_remove(level,[],1),"Physical/key dependency blocks")
	check(Rules.can_remove(level,[2.0],1),"Numeric JSON removed key unlocks")
	check(not Rules.can_remove(level,[2],2),"No double removal")
	check(not Rules.can_remove(level,[],999),"No unknown removal")
	var original: Array = []
	var move = Rules.apply_move(level,original,2)
	check(original.is_empty() and move.valid and move.removed==[2],"Simulation does not mutate input")
	var failed = Rules.apply_move(level,original,0)
	check(not failed.valid and failed.removed.is_empty(),"Invalid tap is immutable")
	for method in ["graph","dfs"]:
		var result = Solver.new().solve(level,[],10000,1000,method)
		check(result.solvable and result.solution==[2,1,0],"Solver and actual rule agree: "+method)
		check(Rules.replay_solution(level,result.solution),"Independent replay: "+method)
	check(Graph.analyze(level).depth==2,"Graph includes blockers and key edges")
	var budget = Solver.new().solve(level,[],0)
	check(budget.timed_out and budget.status=="budget_exhausted","Budget is not unsolvability")
	check(Rules.validate(JSON.parse_string(JSON.stringify(level))).is_empty(),"JSON roundtrip")
	var edge = {"schema_version":2,"ruleset":Rules.RULESET,"size":5,"arrows":[{"id":0,"cells":[[0,2,3],[0,2,4]],"head_direction":0}]}
	check(Rules.exit_cells(edge,edge.arrows[0]).is_empty() and Rules.can_remove(edge,[],0),"Head at edge escapes immediately")
	edge.arrows.append({"id":1,"cells":[[3,2,0],[3,2,1]],"head_direction":0})
	check(Rules.can_remove(edge,[],0),"Adjacent face does not block outward tangent exit")
	var wrapped = {"schema_version":2,"ruleset":Rules.RULESET,"size":5,"arrows":[{"id":0,"cells":[[2,2,4],[0,2,0],[0,2,1]],"head_direction":0},{"id":1,"cells":[[0,2,4],[0,2,3]],"head_direction":2}]}
	check(Rules.validate(wrapped).is_empty(),"Correct folded body orientation")
	check(Rules.blockers(wrapped,[],1)==[0],"Wrapped portion blocks another head lane")
	check(Graph.analyze(wrapped).cyclic and not Solver.new().solve(wrapped).solvable,"Opposing head cycle rejected")
	check(Rules.can_remove(wrapped,[1],0),"Wrapped arrow can leave its head face")
	var invalid = sample()
	invalid.arrows[0].head_direction = 1
	check(Rules.validate(invalid).is_empty(),"Visible quarter-turn head is supported")
	invalid = sample()
	invalid.arrows[0].cells = [[0,2,1],[0,1,1],[0,1,2],[0,1,3],[0,2,3],[0,2,2]]
	invalid.arrows[0].head_direction = 2
	check(not Rules.validate(invalid).is_empty(),"No self-crossing exit lane")
	invalid = sample()
	invalid.arrows[2].cells = invalid.arrows[0].cells.duplicate(true)
	invalid.arrows[2].head_direction = 0
	check(not Rules.validate(invalid).is_empty(),"Overlapping bodies rejected")
	invalid = sample()
	invalid.arrows[0].route = [[0,2,2]]
	check(Solver.new().solve(invalid).status=="invalid","Legacy tracks rejected explicitly")
func _test_generation() -> void:
	for tier in 5:
		var a = Generator.new().generate(31007+tier,tier,0)
		var b = Generator.new().generate(31007+tier,tier,0)
		check(not a.has("error"),"Generated tier "+str(tier))
		if a.has("error"): continue
		a.validation.erase("generation_usec")
		b.validation.erase("generation_usec")
		check(JSON.stringify(a)==JSON.stringify(b),"Deterministic tier "+str(tier))
		check(Rules.validate(a).is_empty() and Rules.replay_solution(a,a.solution),"All generated geometry and solution valid")
		check(a.size==[9,13,17,21,25][tier],"Calibrated board size")
		check(a.validation.wrap_fraction>=(0.05 if tier>=2 else 0.1) and a.validation.wrap_fraction<=0.2,"Occasional wraps")
		check(a.validation.initial_move_fraction<=[0.15,0.10,0.07,0.05,0.04][tier],"Opening choices capped by actual blockers")
		check(a.validation.dependency_depth>=[12,25,40,60,80][tier],"Deep independently derived dependency chains")
		check(a.validation.bent_fraction>=0.6,"Shape diversity")
		for arrow in a.arrows:
			check(arrow.cells.size()>=2 and arrow.cells.size()<=15 and not arrow.has("route"),"Long body; no stored track")
		var dfs = Solver.new().solve(a,[],100000,4000,"dfs")
		check(dfs.solvable and Rules.replay_solution(a,dfs.solution),"Independent DFS continuation")
	check(Generator.date_seed("2026-10-22")==Generator.date_seed("2026-10-22"),"Stable UTC date seed")
	check(Generator.date_seed("2026-10-22")!=Generator.date_seed("2026-10-23"),"Different UTC dates")
	var daily_a = Generator.new().daily("2026-10-22")
	var daily_b = Generator.new().daily("2026-10-22")
	daily_a.validation.erase("generation_usec")
	daily_b.validation.erase("generation_usec")
	check(JSON.stringify(daily_a)==JSON.stringify(daily_b),"Deterministic daily including fallback")
	check(Rules.replay_solution(daily_a,daily_a.solution) and daily_a.size==25,"Dense daily is solvable")
	check(Generator.new().generate_config({"board_size":26}).has("error"),"Unsupported size rejected")
	var fallback_a = Generator.new().daily("2026-10-22",{"board_size":26})
	var fallback_b = Generator.new().daily("2026-10-22",{"board_size":26})
	check(fallback_a.get("fallback",false) and fallback_a.size==25 and Rules.replay_solution(fallback_a,fallback_a.solution),"Daily budget failure has validated dense fallback")
	check(JSON.stringify(fallback_a)==JSON.stringify(fallback_b),"Daily fallback is deterministic and recorded")
func _stress() -> void:
	var report = {"generator_version":Generator.VERSION,"samples":1000,"attempts":0,"accepted":0,"invalid_generations":0,"solver_failures":0,"generation_failures":[],"total_generation_usec":0,"maximum_generation_usec":0,"worst_solver_states":0,"tiers":[]}
	for tier in 5:
		var summary = {"tier":tier,"accepted":0,"density_min":1.0,"density_max":0.0,"long_fraction_total":0.0,"initial_fraction_max":0.0,"dependency_depth_min":100000}
		for index in 200:
			var seed_value = 1900003+tier*100003+index*7919
			var start = Time.get_ticks_usec()
			var level = Generator.new().generate(seed_value,tier,0)
			var duration = Time.get_ticks_usec()-start
			report.total_generation_usec += duration
			report.maximum_generation_usec = maxi(report.maximum_generation_usec,duration)
			if level.has("error"):
				report.generation_failures.append({"seed":seed_value,"tier":tier,"error":level.error})
				report.attempts += int(level.get("attempts",16))
				continue
			report.attempts += int(level.validation.attempts)
			if not Rules.validate(level).is_empty(): report.invalid_generations += 1; continue
			var solved = Solver.new().solve(level)
			if not solved.solvable or not Rules.replay_solution(level,solved.solution): report.solver_failures += 1; continue
			report.worst_solver_states = maxi(report.worst_solver_states,int(solved.explored_states))
			report.accepted += 1
			summary.accepted += 1
			summary.density_min = minf(summary.density_min,level.validation.density)
			summary.density_max = maxf(summary.density_max,level.validation.density)
			summary.initial_fraction_max = maxf(summary.initial_fraction_max,level.validation.initial_move_fraction)
			summary.dependency_depth_min = mini(summary.dependency_depth_min,level.validation.dependency_depth)
			summary.long_fraction_total += level.validation.long_fraction
			if index%100==99: print("STRESS_PROGRESS tier ",tier," ",index+1,"/200")
		report.tiers.append(summary)
	report.success_rate = float(report.accepted)/1000.0
	report.average_generation_usec = float(report.total_generation_usec)/1000.0
	var file = FileAccess.open("res://tests/generation/edge_v21_stress_results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("STRESS_RESULT ",JSON.stringify(report))
	check(report.accepted==1000 and report.invalid_generations==0 and report.solver_failures==0,"1,000 independently replayed stress samples")
