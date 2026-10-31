extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func touch(index: int, down: bool, point: Vector2) -> void:
	var event = InputEventScreenTouch.new()
	event.index = index
	event.pressed = down
	event.position = point
	game._unhandled_input(event)
func run() -> void:
	game = load("res://scenes/main/main.tscn").instantiate()
	game.store = game.Store.new("user://edge_gameplay_test.json")
	game.store.data = game.store.defaults()
	game.store.data.settings.reduced_motion = true
	root.add_child(game)
	await process_frame
	game.start_level(95)
	await create_timer(0.3).timeout
	assert(game.level.size==25 and game.level.arrows.size()>130)
	assert(game.view.find_children("*","StaticBody3D",true,false).size()==1,"Only one selection body for dense puzzle")
	assert(game.view.find_children("*","MeshInstance3D",true,false).size()==game.level.arrows.size()+1,"One combined mesh per arrow")
	var cube_id = game.view.get_node("CeramicSculpture").get_instance_id()
	# Grid selection identifies the exact owner across all six visible faces.
	var selections = 0
	for face in 6:
		game.pivot.quaternion = Quaternion(game.View.Topology.normal(face),Vector3.FORWARD*-1)
		await physics_frame
		await physics_frame
		for row in 25:
			for col in 25:
				var cell = [face,row,col]
				var expected = int(game.view.cell_owner.get(game.Rules.cell_index(cell,25),-1))
				var world = game.view.to_global(game.View.Topology.world_position(cell,25))
				var pixel = game.screen_from_world(world)
				assert(game.pick_arrow(pixel)==expected,"Visible grid lookup must match occupancy")
				selections += 1
	var target = int(game.board.legal_moves([])[0])
	game.attempt(target)
	while game.busy: await process_frame
	assert(target in game.removed and not game.view.pieces.has(target))
	assert(game.view.get_node("CeramicSculpture").get_instance_id()==cube_id,"No whole-puzzle rebuild per removal")
	game.undo()
	assert(game.removed.is_empty() and game.view.pieces.has(target))
	assert(game.view.get_node("CeramicSculpture").get_instance_id()==cube_id,"Undo restores only the arrow")
	var balance = int(game.store.data.hints)
	game.hint()
	assert(game.store.data.hints==balance-1 and game.removed.is_empty())
	await process_frame
	# Two-finger pinch changes zoom only; residual one-finger drag cannot rotate/select.
	var center = game.play_area.get_global_rect().get_center()
	var rotation = game.pivot.quaternion
	touch(0,true,center-Vector2(50,0))
	touch(1,true,center+Vector2(50,0))
	var drag = InputEventScreenDrag.new()
	drag.index = 1
	drag.position = center+Vector2(250,0)
	drag.relative = Vector2(200,0)
	game._unhandled_input(drag)
	assert(game.zoom==3.0 and game.pivot.quaternion.is_equal_approx(rotation))
	touch(1,false,drag.position)
	drag.index = 0
	drag.position = center
	drag.relative = Vector2(50,0)
	game._unhandled_input(drag)
	touch(0,false,center)
	assert(game.removed.is_empty() and game.pivot.quaternion.is_equal_approx(rotation) and not game.pressed)
	game.zoom = 1
	game.store.data.current = 7
	game.store.data.unlocked = 7
	game.start_level(1,"2026-10-22")
	var deadline = Time.get_ticks_msec()+10000
	while not game.playing and Time.get_ticks_msec()<deadline: await process_frame
	assert(game.playing and game.daily_date=="2026-10-22" and game.level.size==25)
	assert(game.store.data.current==7,"Daily never changes campaign current level")
	game.start_level(1,"2026-10-23")
	game.start_level(7)
	await create_timer(1.0).timeout
	assert(game.number==7 and game.daily_date=="","Canceled daily result must not replace a campaign")
	game.sound.shutdown()
	game.queue_free()
	await create_timer(0.2).timeout
	print("EDGE_GAMEPLAY_PASS: 3750 grid picks, dense meshes, incremental remove/undo, solver hint, pinch suppression, async daily and cancellation/isolation")
	quit()
