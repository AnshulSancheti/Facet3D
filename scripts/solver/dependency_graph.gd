extends RefCounted
const Compiled = preload("res://scripts/solver/compiled_board.gd")
static func analyze(level: Dictionary, removed: Array = []) -> Dictionary:
	return Compiled.new(level).analyze(removed)
