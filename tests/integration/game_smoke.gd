extends SceneTree
var game
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.store = game.Store.new("user://test_progress.json")
	game.store.data = game.store.defaults()
	game.start_level(5)
	await process_frame
	assert(game.level.arrows.size() > 0)
	var solution = game.Solver.new().solve(game.level,[])
	if not solution.solvable:
		printerr("SMOKE_FAIL ",solution)
		quit(1)
		return
	game.hint()
	assert(game.removed.is_empty() and game.store.data.hints == 4,"Hint delivers without moving and charges exactly once")
	for id in solution.solution:
		game.attempt(int(id))
		while game.busy: await process_frame
	assert(game.screen_mode == "victory")
	game.start_level(5)
	game.store.data.settings.reduced_motion = true
	game.attempt(int(solution.solution[0]))
	while game.busy: await process_frame
	game.undo()
	assert(game.removed.is_empty())
	game.restart()
	assert(game.removed.is_empty())
	# Exercise engine ray picking and drag differentiation using the real camera.
	var target = int(solution.solution[0])
	for arrow in game.level.arrows:
		if int(arrow.id) != target: continue
		game.pivot.quaternion = Quaternion(game.View.Topology.normal(int(arrow.cells.back()[0])),Vector3(0,0,1))
		await physics_frame
		await physics_frame
		var world = game.pivot.to_global(game.View.Topology.world_position(arrow.cells.back(),int(game.level.size)))
		var pixel = game.screen_from_world(world)
		game.pointer(true,pixel)
		game.rotate_by(Vector2(30,0),pixel+Vector2(30,0))
		game.pointer(false,pixel+Vector2(30,0))
		assert(game.removed.is_empty(),"A drag must not select an arrow")
		game.velocity = Vector2.ZERO
		game.pivot.quaternion = Quaternion(game.View.Topology.normal(int(arrow.cells.back()[0])),Vector3(0,0,1))
		await physics_frame
		await physics_frame
		pixel = game.screen_from_world(game.pivot.to_global(game.View.Topology.world_position(arrow.cells.back(),int(game.level.size))))
		game.pointer(true,pixel)
		game.pointer(false,pixel)
		while game.busy: await process_frame
		assert(target in game.removed,"Camera ray must pick the visible legal piece")
		break
	game.restart()
	# Pause/restart during motion must retain the fresh board.
	game.store.data.settings.reduced_motion = false
	game.attempt(target)
	game.pause_menu()
	game.restart()
	await create_timer(0.2).timeout
	assert(game.removed.is_empty() and not game.busy)
	game.pause_menu()
	game.settings(true)
	game.info(true)
	game.level_select()
	game.daily_menu()
	game.menu()
	print("GAME_SMOKE_PASS: menus, level5 solver sequence, animation, hint, undo, restart, physics picking, drag threshold, interrupted restart")
	game.sound.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit()
