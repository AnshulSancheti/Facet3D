extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func check(condition: bool, description: String) -> void:
	if condition: return
	printerr("CERAMIC_FAIL: ",description)
	quit(1)
func bounds() -> Rect2:
	var result = Rect2()
	var first = true
	for x in [-1.56,1.56]:
		for y in [-1.56,1.56]:
			for z in [-1.56,1.56]:
				var pixel = game.screen_from_world(game.pivot.to_global(Vector3(x,y,z)))
				if first: result = Rect2(pixel,Vector2.ZERO); first = false
				else: result = result.expand(pixel)
	return result
func run() -> void:
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.store = game.Store.new("user://ceramic_presentation_test.json")
	game.store.data = game.store.defaults()
	game.store.data.settings.reduced_motion = true
	game.menu()
	await create_timer(0.5).timeout
	var sculpture = game.view.get_node("CeramicSculpture")
	check(sculpture.mesh.get_aabb().size.is_equal_approx(Vector3.ONE*2.98),"Ceramic must remain within original cube envelope")
	var normals = sculpture.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for normal in normals:
		check(maxf(absf(normal.x),maxf(absf(normal.y),absf(normal.z)))>0.9999,"Cube faces retain sharp axis-aligned normals")
	check(game.sound.music_player.stream.loop,"Ambient score must loop")
	# Toggles must remain independent across background/resume.
	game.sound.enabled = false
	game.sound.set_music(true)
	game.sound.set_backgrounded(true)
	await create_timer(0.3).timeout
	check(game.sound.music_player.stream_paused,"Background pauses music after fade")
	game.sound.set_backgrounded(false)
	await create_timer(0.7).timeout
	check(not game.sound.music_player.stream_paused and not game.sound.enabled,"Resume music without enabling effects")
	game.sound.set_music(false)
	await create_timer(0.3).timeout
	check(game.sound.music_player.stream_paused,"Music off must be honored")
	game.start_level(65)
	# Conservative corner bounds across representative rotations and portrait ratios.
	for size in [Vector2i(360,800),Vector2i(540,960),Vector2i(720,1280)]:
		root.size = size
		root.content_scale_size = Vector2i(540,roundi(540.0*size.y/size.x))
		await create_timer(0.1).timeout
		for angle in [Vector3.ZERO,Vector3(-0.35,0.5,0),Vector3(0.65,0.8,0.2),Vector3(-0.8,-0.8,0.1)]:
			game.pivot.rotation = angle
			await process_frame
			await process_frame
			var rect = bounds()
			check(root.get_visible_rect().encloses(rect),"Rotated sculpture fits portrait")
			for button in game.screen.find_children("*","Button",true,false):
				check(not rect.intersects(button.get_global_rect()),"Cube clears controls")
				check(button.size.y>=48,"Touch targets retain 48 logical pixels")
		game.zoom = 3.0
		await process_frame
		for button in game.screen.find_children("*","Button",true,false): check(not game.play_area.get_global_rect().intersects(button.get_global_rect()),"Zoomed viewport cannot cover controls")
		game.zoom = 1.0
		for mode in [game.menu,game.level_select,game.daily_menu,func(): game.settings(false),game.pause_menu]:
			mode.call()
			await process_frame
			for button in game.screen.find_children("*","Button",true,false):
				# Scrollable offscreen level cells are deliberately clipped by the scroll area.
				if game.screen_mode != "levels": check(root.get_visible_rect().encloses(button.get_global_rect()),"Screen controls fit portrait")
		game.start_level(65)
	game.sound.shutdown()
	await create_timer(0.1).timeout
	game.queue_free()
	await create_timer(0.15).timeout
	print("CERAMIC_PRESENTATION_PASS: mesh envelope, ambient loop and background/preferences, rotated cube bounds, all menu layouts and 48px targets at three portrait ratios")
	quit()
