extends SceneTree
const G = preload("res://scripts/generation/level_generator.gd")
func _init():
 for tier in 5:
  for i in 3:
   var l = G.new().generate(31007+tier+i*7919,tier,0)
   if l.has("error"): print(l); continue
   print("MEASURE ",tier," size ",l.size," arrows ",l.arrows.size()," initial ",l.validation.initial_moves," depth ",l.validation.dependency_depth," ms ",l.validation.generation_usec/1000)
 quit()
