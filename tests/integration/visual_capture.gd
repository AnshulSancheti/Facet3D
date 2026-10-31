extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.store = game.Store.new("user://visual_capture_test.json")
	game.store.data = game.store.defaults()
	game.menu()
	await capture("menu")
	game.start_level(1)
	await capture("beginner")
	game.start_level(5)
	await capture("keys")
	game.start_level(12)
	await capture("game")
	game.start_level(95)
	await capture("expert")
	game.settings(true)
	await capture("settings")
	game.pause_menu()
	await capture("pause")
	game.level_select()
	await capture("levels")
	game.daily_menu()
	await capture("daily")
	game.start_level(1)
	var solution = game.Solver.new().solve(game.level,[])
	game.store.data.settings.reduced_motion = true
	for id in solution.solution:
		game.attempt(int(id))
		while game.busy: await process_frame
	await capture("complete")
	print("VISUAL_CAPTURE_PASS: menu, beginner, keys, gameplay, expert, settings, pause, levels, daily and completion")
	game.sound.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await create_timer(0.1).timeout
	quit()
func capture(name: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/facet-"+name+".png")
