extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1080,1920)
	root.content_scale_size = Vector2i(540,960)
	var game = load("res://scenes/main/main.tscn").instantiate()
	game.store = game.Store.new("user://native_capture_test.json")
	game.store.data = game.store.defaults()
	game.store.data.settings.reduced_motion = true
	root.add_child(game)
	await process_frame
	game.start_level(95)
	await create_timer(0.6).timeout
	assert(game.world_viewport.size.x==root.size.x,"3D viewport must use physical pixel width")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/facet-edge-native-overview.png")
	game.zoom = 2.25
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/facet-edge-native-zoom.png")
	for button in game.screen.find_children("*","Button",true,false): assert(not game.play_area.get_global_rect().intersects(button.get_global_rect()))
	print("NATIVE_CAPTURE_PASS: physical viewport ",game.world_viewport.size," logical area ",game.play_area.size," 2.25x zoom clipped before HUD")
	game.sound.shutdown()
	game.queue_free()
	await create_timer(0.15).timeout
	quit()
