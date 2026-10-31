extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	for size in [Vector2i(360,800),Vector2i(540,960),Vector2i(720,1280)]:
		root.size = size
		root.content_scale_size = Vector2i(540,roundi(540.0*size.y/size.x))
		await process_frame
		game.menu()
		await create_timer(0.3).timeout
		var rect = root.get_visible_rect()
		for button in game.screen.find_children("*","Button",true,false):
			assert(rect.encloses(button.get_global_rect()),"Menu button outside responsive viewport")
		game.start_level(65)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/facet-%dx%d.png" % [size.x,size.y])
		for button in game.screen.find_children("*","Button",true,false):
			assert(rect.encloses(button.get_global_rect()),"HUD button outside responsive viewport")
	print("RESPONSIVE_PASS: desktop360x800,540x960,720x1280 menus and gameplay button extents; captures in /tmp")
	game.sound.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await create_timer(0.1).timeout
	quit()
