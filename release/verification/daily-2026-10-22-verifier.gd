extends SceneTree
const G = preload("res://scripts/generation/level_generator.gd")
const R = preload("res://scripts/puzzle/puzzle_rules.gd")
const C = preload("res://scripts/solver/compiled_board.gd")
func _init():
 var l = G.new().daily("2026-10-22")
 var board = C.new(l)
 var opening = board.legal_moves([])
 print("DAILY arrows=",l.arrows.size()," fallback=",l.get("fallback",false)," initial=",opening," depth=",board.analyze().depth)
 print("VALIDATION ",R.validate(l)," solution replay=",R.replay_solution(l,l.solution))
 for id in opening:
  var a = R.arrow_by_id(l,id)
  print("OPENING id=",id," head=",a.cells.back()," heading=",a.head_direction," key=",a.get("key",-1))
 var rng = RandomNumberGenerator.new()
 rng.seed = 90210
 for trial in 20:
  var gone: Array = []
  while gone.size()<l.arrows.size():
   var moves = board.legal_moves(gone)
   assert(not moves.is_empty(),"Unexpected deadlock")
   gone.append(moves[rng.randi_range(0,moves.size()-1)])
  assert(R.replay_solution(l,gone))
 print("PASS: 20 different complete legal removal orders; no deadlocks")
 quit()
