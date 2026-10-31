extends RefCounted
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
const Compiled = preload("res://scripts/solver/compiled_board.gd")
var _failed: Dictionary = {}
var _states = 0
var _budget = 0
var _deadline = 0
var _timed_out = false
func solve(level: Dictionary, removed: Array = [], state_budget: int = 100000, time_budget_ms: int = 1000, method: String = "graph") -> Dictionary:
	var started = Time.get_ticks_msec()
	var errors = Rules.validate(level)
	var normalized: Array = []
	for id in removed:
		if Rules.arrow_by_id(level,int(id)).is_empty(): errors.append("Unknown removed id")
		if not normalized.has(int(id)): normalized.append(int(id))
	if not errors.is_empty(): return {"solvable":false,"solution":[],"legal_moves":[],"immediate_legal_moves":0,"explored_states":0,"timed_out":false,"status":"invalid","errors":errors,"complexity":0,"branching_factor":0.0}
	var board = Compiled.new(level)
	var legal = board.legal_moves(normalized)
	var graph = board.analyze(normalized)
	var solution: Array = graph.order
	_states = solution.size()
	_timed_out = state_budget<solution.size() or time_budget_ms<=0 or Time.get_ticks_msec()-started>=time_budget_ms
	var solved: bool = not graph.cyclic and not _timed_out
	if method=="dfs":
		_failed.clear()
		_states = 0
		_budget = state_budget
		_deadline = Time.get_ticks_msec()+time_budget_ms
		_timed_out = false
		solution = []
		solved = _search(board,normalized.duplicate(),solution)
	return {"solvable":solved,"solution":solution if solved else [],"legal_moves":legal,"immediate_legal_moves":legal.size(),"explored_states":_states,"timed_out":_timed_out,"status":"solved" if solved else ("budget_exhausted" if _timed_out else "unsolvable"),"complexity":int(graph.depth)*2+board.ids.size()-legal.size(),"branching_factor":float(legal.size()),"method":method}
func _search(board: RefCounted, removed: Array, sequence: Array) -> bool:
	if removed.size()==board.ids.size(): return true
	if _states>=_budget or Time.get_ticks_msec()>=_deadline:
		_timed_out = true
		return false
	var ordered = removed.duplicate()
	ordered.sort()
	var key = str(ordered)
	if _failed.has(key): return false
	_states += 1
	for id in board.legal_moves(removed):
		removed.append(id)
		sequence.append(id)
		if _search(board,removed,sequence): return true
		removed.pop_back()
		sequence.pop_back()
		if _timed_out: return false
	_failed[key] = true
	return false
