extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.store = game.Store.new("user://redesign_test.json")
	game.store.data = game.store.defaults()
	game.start_level(12)
	await create_timer(0.5).timeout
	# A front surface point must follow the pointer on screen in both axes.
	for drag in [Vector2(35,0),Vector2(-35,0),Vector2(0,35),Vector2(0,-35)]:
		game.pivot.rotation = Vector3.ZERO
		var point = Vector3(0,0,1.55)
		var before = game.screen_from_world(game.pivot.to_global(point))
		game.pointer(true,before)
		game.rotate_by(drag,before+drag)
		var after = game.screen_from_world(game.pivot.to_global(point))
		assert((after-before).dot(drag)>0,"Surface must follow the drag")
		game.pointer(false,before+drag)
		assert(game.removed.is_empty(),"Drag cannot release a piece")
	game.velocity = Vector2.ZERO
	game.pivot.rotation = Vector3(-0.35,0.5,0)
	for size in [Vector2i(360,800),Vector2i(540,960),Vector2i(720,1280)]:
		root.size = size
		root.content_scale_size = Vector2i(540,roundi(540.0*size.y/size.x))
		await create_timer(0.1).timeout
		var bounds = Rect2()
		var first = true
		for x in [-1.55,1.55]:
			for y in [-1.55,1.55]:
				for z in [-1.55,1.55]:
					var pixel = game.screen_from_world(game.pivot.to_global(Vector3(x,y,z)))
					if first: bounds = Rect2(pixel,Vector2.ZERO); first = false
					else: bounds = bounds.expand(pixel)
		print("FRAMING ",size," ",root.get_visible_rect()," ",bounds," camera ",game.camera.position.z)
		assert(root.get_visible_rect().encloses(bounds),"Cube must fit portrait viewport")
		for button in game.screen.find_children("*","Button",true,false):
			assert(not bounds.intersects(button.get_global_rect()),"Cube must clear HUD buttons")
	game.sound.shutdown()
	await create_timer(0.15).timeout
	game.queue_free()
	await create_timer(0.15).timeout
	print("CALM_REDESIGN_PASS: four drag directions, no drag selection, cube bounds and HUD clearance at three portrait sizes")
	quit()
