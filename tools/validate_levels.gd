extends SceneTree
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
const Solver = preload("res://scripts/solver/puzzle_solver.gd")
func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://resources/levels/campaign.json"))
	if not data is Dictionary or data.get("levels",[]).size()!=100: push_error("Expected 100 levels"); quit(1); return
	for level in data.levels:
		var result = Solver.new().solve(level,[],100000,4000,"dfs")
		if not result.solvable or not Rules.replay_solution(level,level.solution) or not Rules.replay_solution(level,result.solution) or not Rules.replay_solution(level,level.construction_solution):
			push_error("Campaign validation failed: "+str(level.level_number)); quit(1); return
	print("PASS: 100 edge-rule campaign levels, independent DFS, occupancy replay and reverse-construction proofs")
	quit()
