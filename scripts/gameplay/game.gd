extends Node3D
const Rules = preload("res://scripts/puzzle/puzzle_rules.gd")
const Compiled = preload("res://scripts/solver/compiled_board.gd")
const Solver = preload("res://scripts/solver/puzzle_solver.gd")
const Generator = preload("res://scripts/generation/level_generator.gd")
const View = preload("res://scripts/gameplay/puzzle_view.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Ads = preload("res://scripts/ads/ads_service.gd")
const Sound = preload("res://scripts/audio/sound_bank.gd")
var store = Store.new()
var sound = Sound.new()
var ads = Ads.new()
var pivot = Node3D.new()
var view = View.new()
var camera = Camera3D.new()
var ui = CanvasLayer.new()
var screen: Control
var hud_label: Label
var message: Label
var level: Dictionary
var removed: Array = []
var history: Array = []
var number = 1
var daily_date = ""
var playing = false
var busy = false
var generation_id = 0
var elapsed = 0.0
var moves = 0
var drag_start = Vector2.ZERO
var dragging = false
var pressed = false
var fingers: Dictionary = {}
var pinch_distance = 0.0
var velocity = Vector2.ZERO
var zoom = 1.0
var play_area = TextureRect.new()
var world_viewport = SubViewport.new()
var world_root = Node3D.new()
var footer: Control
var menu_chapter: Label
var performance_probe: Node
var board: RefCounted
var campaign: Array = []
var daily_thread = Thread.new()
var daily_cache: Dictionary = {}
var daily_pending: Dictionary = {}
var pinching = false
var progress: ProgressBar
var screen_mode = "menu"
var backdrop_has_sculpture = true
const CUBE_CORNERS = [Vector3(-1.56,-1.56,-1.56),Vector3(-1.56,-1.56,1.56),Vector3(-1.56,1.56,-1.56),Vector3(-1.56,1.56,1.56),Vector3(1.56,-1.56,-1.56),Vector3(1.56,-1.56,1.56),Vector3(1.56,1.56,-1.56),Vector3(1.56,1.56,1.56)]
const TITLE_FONT = preload("res://assets/fonts/FacetSerif.ttf")
func _ready() -> void:
	Engine.max_fps = 60
	if OS.has_feature("debug") and DisplayServer.get_name()!="headless":
		performance_probe = preload("res://scripts/utilities/performance_probe.gd").new()
		add_child(performance_probe)
	add_child(sound)
	sound.enabled = bool(store.data.settings.sound)
	sound.set_music(bool(store.data.settings.music))
	setup_world()
	world_root.add_child(pivot)
	pivot.add_child(view)
	pivot.rotation = Vector3(-0.35, 0.5, 0)
	world_root.add_child(camera)
	camera.position = Vector3(0,0,9)
	camera.current = true
	camera.fov = 43
	add_child(ui)
	ui.layer = 3
	store.event("app_launch")
	store.data.stats.sessions += 1
	store.event("session_start")
	add_child(ads)
	ads.event_logged.connect(func(event_name,details): store.event(event_name,details))
	ads.status_changed.connect(func(text):
		if is_instance_valid(message) and playing: message.text = text)
	ads.reward_earned.connect(func():
		store.data.hints += 1
		store.save()
		playing = true
		hud()
		message.text = "Hint earned. Tap Hint when you want to use it.")
	ads.start()
	var packaged = JSON.parse_string(FileAccess.get_file_as_string("res://resources/levels/campaign.json"))
	campaign = packaged.levels
	Generator.table(25)
	splash()
func setup_world() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	layer.add_child(play_area)
	play_area.name = "PuzzleArea"
	play_area.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	play_area.stretch_mode = TextureRect.STRETCH_SCALE
	play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(world_viewport)
	play_area.texture = world_viewport.get_texture()
	world_viewport.own_world_3d = true
	world_viewport.transparent_bg = true
	world_viewport.handle_input_locally = false
	world_viewport.add_child(world_root)
	for child in $Atmosphere.get_children():
		if child is WorldEnvironment or child is Light3D:
			child.reparent(world_root)
			if child is WorldEnvironment:
				child.environment.background_mode = Environment.BG_COLOR
				child.environment.background_color = Color(0,0,0,0)
func _process(delta: float) -> void:
	poll_daily()
	if playing:
		elapsed += delta
		if is_instance_valid(hud_label): hud_label.text = "Daily ritual" if daily_date!="" else "Level %02d" % number
		if is_instance_valid(progress): progress.value = 100.0*removed.size()/maxf(1,level.arrows.size())
	if screen_mode=="menu" and not bool(store.data.settings.reduced_motion): pivot.rotation.y += delta*0.045
	play_area.visible = view.visible
	if backdrop_has_sculpture!=view.visible:
		backdrop_has_sculpture = view.visible
		$Atmosphere/Backdrop/Gradient.material.set_shader_parameter("sculpture_visible",view.visible)
	if not pressed and not pinching and playing:
		apply_rotation(velocity*delta)
		velocity = velocity.lerp(Vector2.ZERO,minf(delta*6,1))
	var viewport_size = get_viewport().get_visible_rect().size
	var top = viewport_size.y*0.23 if screen_mode=="menu" else 145.0
	var bottom = viewport_size.y*0.79 if screen_mode=="menu" else viewport_size.y-105
	if screen_mode=="game":
		if is_instance_valid(message): top = maxf(130,message.get_global_rect().end.y+16)
		if is_instance_valid(footer): bottom = footer.get_global_rect().position.y-16
	elif screen_mode=="menu" and is_instance_valid(menu_chapter): bottom = menu_chapter.get_global_rect().position.y-14
	play_area.position = Vector2(0,top)
	play_area.size = Vector2(viewport_size.x,maxf(100,bottom-top))
	# Canvas scaling is logical; render the offscreen scene at physical pixels.
	var native_scale = Vector2(get_window().size)/viewport_size
	var native_size = Vector2i((play_area.size*native_scale).round())
	if world_viewport.size!=native_size: world_viewport.size = native_size
	var aspect = play_area.size.x/maxf(1,play_area.size.y)
	var tangent = tan(deg_to_rad(43.0)*0.5)
	var fit = 5.5
	for corner in CUBE_CORNERS:
		var point = pivot.to_global(corner)
		fit = maxf(fit,point.z+absf(point.x)/(tangent*aspect*0.98))
		fit = maxf(fit,point.z+absf(point.y)/(tangent*0.98))
	camera.position.z = fit
	camera.fov = rad_to_deg(2.0*atan(tangent/zoom))
func screen_from_world(point: Vector3) -> Vector2:
	return play_area.position+camera.unproject_position(point)*play_area.size/Vector2(world_viewport.size)
func viewport_from_screen(point: Vector2) -> Vector2:
	return (point-play_area.position)*Vector2(world_viewport.size)/play_area.size
func pick_arrow(point: Vector2) -> int:
	if not play_area.get_global_rect().has_point(point): return -1
	var pixel = viewport_from_screen(point)
	var origin = camera.project_ray_origin(pixel)
	var direction = camera.project_ray_normal(pixel)
	var query = PhysicsRayQueryParameters3D.create(origin,origin+direction*50)
	var hit = world_root.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider.has_meta("cube_surface"): return -1
	return view.select_cell(view.to_local(hit.position),view.global_basis.inverse()*hit.normal)
func poll_daily() -> void:
	if daily_thread.is_started() and not daily_thread.is_alive():
		var result = daily_thread.wait_to_finish()
		daily_cache[result.date] = result.level
	if daily_pending.is_empty(): return
	var date: String = daily_pending.date
	if daily_cache.has(date):
		var request = daily_pending
		daily_pending = {}
		if int(request.token)==generation_id: activate_level(int(request.number),date,daily_cache[date].duplicate(true))
	elif not daily_thread.is_started(): daily_thread.start(func(): return {"date":date,"level":Generator.new().daily(date)})
func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.set_content_margin_all(12)
	box.border_color = border
	box.set_border_width_all(1)
	return box
func reset_ui(mode: String) -> VBoxContainer:
	screen_mode = mode
	if is_instance_valid(performance_probe): performance_probe.set_screen(mode)
	pressed = false
	dragging = false
	fingers.clear()
	pinching = false
	pinch_distance = 0.0
	if screen:
		ui.remove_child(screen)
		screen.queue_free()
	screen = Control.new()
	screen.theme = preload("res://resources/themes/facet_theme.tres")
	ui.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin = MarginContainer.new()
	screen.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,32)
	margin.add_theme_constant_override("margin_top",44)
	margin.add_theme_constant_override("margin_bottom",32)
	if OS.get_name() == "Android":
		var safe = DisplayServer.get_display_safe_area()
		var display = DisplayServer.screen_get_size()
		var ratio = get_viewport().get_visible_rect().size.y / maxf(display.y,1)
		margin.add_theme_constant_override("margin_top",maxi(44,int(safe.position.y*ratio)+12))
		margin.add_theme_constant_override("margin_bottom",maxi(32,int((display.y-safe.end.y)*ratio)+12))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	if not bool(store.data.settings.reduced_motion):
		screen.modulate.a = 0.0
		create_tween().bind_node(screen).tween_property(screen,"modulate:a",1.0,0.16)
	return column
func label_in(parent: Node, text: String, size: int = 22, color: Color = Color("e6edf1")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
func spacer(parent: Node) -> void:
	var control = Control.new()
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
func button(parent: Node, text: String, action: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",16)
	b.add_theme_color_override("font_color",Color("0c1424") if primary else Color("e6edf1"))
	b.add_theme_stylebox_override("normal",style(Color("dce2de") if primary else Color(0.65,0.72,0.85,0.035),Color(0.8,0.85,0.95,0.08)))
	b.add_theme_stylebox_override("hover",style(Color("c2d3d1") if primary else Color(0.7,0.8,0.9,0.10)))
	b.add_theme_stylebox_override("pressed",style(Color("a9c4c4") if primary else Color(0.7,0.8,0.9,0.16)))
	b.add_theme_stylebox_override("disabled",style(Color(0.65,0.72,0.85,0.015)))
	b.add_theme_color_override("font_disabled_color",Color("617086"))
	b.add_theme_stylebox_override("focus",style(Color.TRANSPARENT,Color("a1dcd9")))
	b.pressed.connect(func(): sound.enabled = store.data.settings.sound; sound.play_note("tap"); action.call())
	parent.add_child(b)
	return b

func heading(parent: Node, text: String, size: int = 36) -> Label:
	var title = label_in(parent,text,size,Color("e8e5e7"))
	title.add_theme_font_override("font",TITLE_FONT)
	return title
func icon_button(parent: Node, text: String, icon_name: String, action: Callable) -> Button:
	var b = button(parent,text,action)
	b.icon = load("res://assets/icons/"+icon_name+".svg")
	b.add_theme_constant_override("icon_max_width",20)
	b.add_theme_constant_override("h_separation",8)
	b.tooltip_text = text if text != "" else icon_name.capitalize()
	b.add_theme_stylebox_override("normal",style(Color.TRANSPARENT))
	return b

func splash() -> void:
	var c = reset_ui("splash")
	spacer(c)
	label_in(c,"◇",80,Color("d6c49a"))
	heading(c,"Facet",64)
	label_in(c,"Escape into a little stillness",16,Color("a4b0c6"))
	spacer(c)
	await get_tree().create_timer(0.45).timeout
	if screen_mode == "splash": menu()
func menu() -> void:
	playing = false
	generation_id += 1
	daily_pending = {}
	view.show()
	if not campaign.is_empty(): view.build(campaign[84],[])
	pivot.position = Vector3(0,0.05,0)
	pivot.scale = Vector3.ONE * 0.94
	zoom = 1.0
	pivot.rotation = Vector3(-0.35,0.5,0)
	var c = reset_ui("menu")
	heading(c,"Facet",66)
	label_in(c,"Escape 3D",13,Color("c0cbc9"))
	label_in(c,"Small puzzles. A little stillness.",16,Color("a4b0c6"))
	spacer(c)
	menu_chapter = label_in(c,"Chapter %02d  ·  %s" % [int(store.data.current),["Stillwater","Moonrise","Drift","Afterglow","Starlight"][mini(4,(int(store.data.current)-1)/20)]],14,Color("a4b0c6"))
	if not store.migration_error.is_empty(): label_in(c,store.migration_error,16,Color("f2d4a2"))
	var play = button(c,"Begin" if int(store.data.current)==1 and store.data.completed.is_empty() else "Continue",func(): start_level(int(store.data.current)),true)
	play.custom_minimum_size = Vector2(220,52)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row = HBoxContainer.new()
	c.add_child(row)
	row.add_theme_constant_override("separation",8)
	icon_button(row,"Levels","levels",level_select)
	icon_button(row,"Daily","daily",daily_menu)
	icon_button(row,"Settings","settings",func(): settings(false))

func start_level(index: int, daily: String = "") -> void:
	busy = false
	generation_id += 1
	number = clampi(index,1,100)
	daily_date = daily
	if daily!="" and not daily_cache.has(daily):
		playing = false
		view.hide()
		var c = reset_ui("loading_daily")
		spacer(c)
		heading(c,"Preparing today’s puzzle")
		label_in(c,"A fresh arrangement is taking shape…",18)
		button(c,"Back",daily_menu)
		spacer(c)
		daily_pending = {"token":generation_id,"date":daily,"number":number}
		return
	activate_level(number,daily,daily_cache[daily].duplicate(true) if daily!="" else campaign[number-1])
func activate_level(index: int, daily: String, definition: Dictionary) -> void:
	number = index
	daily_date = daily
	level = definition
	board = Compiled.new(level)
	if is_instance_valid(performance_probe): performance_probe.set_board(int(level.size),level.arrows.size())
	removed = []
	history = []
	elapsed = 0
	moves = 0
	if daily=="":
		store.data.current = number
		store.save()
	view.show()
	zoom = 1.0
	velocity = Vector2.ZERO
	pressed = false
	fingers.clear()
	pivot.position = Vector3.ZERO
	pivot.scale = Vector3.ONE
	view.build(level,removed)
	if not bool(store.data.settings.reduced_motion):
		view.scale = Vector3.ONE * 0.90
		create_tween().bind_node(view).tween_property(view,"scale",Vector3.ONE,0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else: view.scale = Vector3.ONE
	pivot.rotation = Vector3(-0.35,0.5,0)
	playing = true
	store.event("level_start",{"level":number,"daily":daily})
	hud()
func hud() -> void:
	view.show()
	var c = reset_ui("game")
	var top = HBoxContainer.new()
	c.add_child(top)
	hud_label = label_in(top,"Daily ritual" if daily_date != "" else "Level %02d" % number,16,Color("c3d0df"))
	hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var pause = icon_button(top,"","pause",pause_menu)
	pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause.custom_minimum_size.x = 48
	pause.tooltip_text = "Pause"
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 3
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track = style(Color("1e2c40"))
	track.set_content_margin_all(0)
	var fill = style(Color("7fb9bd"))
	fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background",track)
	progress.add_theme_stylebox_override("fill",fill)
	c.add_child(progress)
	var tutorials = ["Tap an arrow. Its head needs a clear line to the face’s edge.","Drag to turn the cube. Pinch to look closer.","Clear the arrow blocking the head’s exit first.","Long bent arrows follow their head out of the face.","Golden keys release matching pearl locks."]
	message = label_in(c,tutorials[number-1] if number <= 5 and daily_date == "" else "",16,Color("91a4bb"))
	spacer(c)
	var row = HBoxContainer.new()
	footer = row
	row.add_theme_constant_override("separation",10)
	c.add_child(row)
	icon_button(row,"Undo","undo",undo)
	icon_button(row,"Hint · %d" % int(store.data.hints),"hint",hint)
	icon_button(row,"Reset","reset",restart)

func pause_menu() -> void:
	view.hide()
	playing = false
	velocity = Vector2.ZERO
	var c = reset_ui("pause")
	spacer(c)
	heading(c,"Take a breath")
	button(c,"Resume",func(): playing = true; hud(),true)
	button(c,"Restart",restart)
	button(c,"Settings",func(): settings(true))
	button(c,"Home",menu)
	spacer(c)
func restart() -> void:
	store.event("level_restart",{"level":number})
	start_level(number,daily_date)
func undo() -> void:
	if busy or history.is_empty(): return
	var restore_id = int(removed.back())
	removed = history.pop_back()
	moves = maxi(0,moves-1)
	view.restore_arrow(restore_id,removed)
	hud()
func hint() -> void:
	if busy: return
	if int(store.data.hints) <= 0:
		if ads.rewarded_available(): reward_offer()
		else: message.text = "No hints left. Ads unavailable; you can still solve every puzzle."
		return
	var result = Solver.new().solve(level,removed)
	if result.solvable and not result.solution.is_empty():
		var hint_id = int(result.solution[0])
		for arrow in level.arrows:
			if int(arrow.id) == hint_id:
				pivot.quaternion = Quaternion(View.Topology.normal(int(arrow.cells.back()[0])),Vector3(0,0,1))
		velocity = Vector2.ZERO
		zoom = 1.0
		view.highlight(hint_id,bool(store.data.settings.reduced_motion))
		store.data.hints -= 1
		store.event("hint_used",{"level":number})
		store.save()
		sound.play_note("hint")
		hud()
		message.text = "The highlighted arrow has a clear exit."
	else: message.text = "Hint search could not finish. No hint was spent."
func attempt(id: int) -> void:
	if busy or not playing: return
	if board==null or not board.can_remove(removed,id):
		message.text = "The head is blocked, or this arrow needs its key."
		view.highlight(id,bool(store.data.settings.reduced_motion))
		sound.play_note("invalid")
		return
	busy = true
	var move_generation = generation_id
	history.append(removed.duplicate())
	removed.append(id)
	moves += 1
	store.data.stats.moves += 1
	sound.enabled = store.data.settings.sound
	sound.play_note("remove")
	if store.data.settings.haptics and OS.get_name() == "Android": Input.vibrate_handheld(18)
	await view.remove_arrow(id, bool(store.data.settings.reduced_motion))
	if move_generation != generation_id: return
	busy = false
	view.sync_state(removed)
	for arrow in level.arrows:
		if int(arrow.id) == id and int(arrow.get("key",-1)) >= 0:
			sound.play_note("unlock")
			for target in level.arrows:
				if int(target.get("lock",-1)) == int(arrow.key) and int(target.id) not in removed: view.highlight(int(target.id),bool(store.data.settings.reduced_motion))
	if removed.size() == level.arrows.size(): victory()
func reward_offer() -> void:
	playing = false
	var c = reset_ui("reward_offer")
	spacer(c)
	heading(c,"A fresh perspective")
	label_in(c,"Watch an optional advertisement to earn one hint.",22)
	button(c,"Watch ad · +1 hint",func():
		if ads.request_rewarded_hint():
			playing = true
			hud()
		else:
			playing = true
			hud()
			message.text = "The ad could not open. Continue playing.",true)
	button(c,"Keep playing",func(): playing = true; hud())
	spacer(c)
func victory() -> void:
	playing = false
	view.hide()
	store.complete(number,elapsed,daily_date)
	store.event("daily_challenge_completed" if daily_date != "" else "level_complete",{"level":number,"seconds":elapsed,"moves":moves})
	sound.play_note("victory")
	
	if daily_date == "": ads.maybe_interstitial(number,store.data.completed.size(),true)
	var c = reset_ui("victory")
	spacer(c)
	heading(c,"A little clearer.")
	label_in(c,"%d %s  ·  %d seconds" % [moves,"move" if moves == 1 else "moves",int(elapsed)],24)
	button(c,"Next level" if daily_date == "" and number < 100 else "Home",func():
		if daily_date == "" and number < 100: start_level(number+1)
		else: menu(),true)
	button(c,"Play again",restart)
	button(c,"Home",menu)
	spacer(c)
func level_select() -> void:
	playing = false
	view.hide()
	var c = reset_ui("levels")
	heading(c,"Your journey")
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.add_child(scroll)
	var groups = VBoxContainer.new()
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(groups)
	for tier in 5:
		label_in(groups,["Stillwater","Moonrise","Drift","Afterglow","Starlight"][tier],22,Color("d6c49a"))
		var grid = GridContainer.new()
		grid.columns = 4
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		groups.add_child(grid)
		for i in range(tier*20+1,tier*20+21):
			var b = button(grid,("✓ " if store.data.completed.has(str(i)) else "") + str(i),func(): start_level(i))
			b.disabled = i > int(store.data.unlocked)
	button(c,"Back",menu)
func daily_menu() -> void:
	playing = false
	generation_id += 1
	daily_pending = {}
	view.hide()
	var date = Time.get_date_string_from_system(true)
	var c = reset_ui("daily")
	spacer(c)
	heading(c,"Today’s quiet moment")
	label_in(c,date + " · UTC",24)
	label_in(c,"A shared, densely filled 25×25 puzzle.\nYour campaign stays separate.",20)
	label_in(c,"Best: %d seconds" % int(store.data.daily[Store.daily_key(date)]) if store.data.daily.has(Store.daily_key(date)) else "Unsolved today",22,Color("d6c49a"))
	button(c,"Begin today",func(): start_level(1,date),true)
	button(c,"Back",menu)
	spacer(c)
func settings(in_game: bool) -> void:
	playing = false
	view.hide()
	var c = reset_ui("settings")
	heading(c,"Make it yours")
	for key in ["sound","music","haptics","reduced_motion","invert_drag"]:
		var toggle = CheckButton.new()
		toggle.text = key.capitalize().replace("_"," ")
		toggle.custom_minimum_size.y = 54
		toggle.button_pressed = bool(store.data.settings[key])
		toggle.toggled.connect(func(value): store.data.settings[key] = value; sound.enabled = bool(store.data.settings.sound); sound.set_music(bool(store.data.settings.music)); store.save())
		c.add_child(toggle)
	label_in(c,"Camera sensitivity",18)
	var slider = HSlider.new()
	slider.min_value = 0.3
	slider.max_value = 2.0
	slider.step = 0.1
	slider.value = float(store.data.settings.sensitivity)
	slider.value_changed.connect(func(value): store.data.settings.sensitivity = value; store.save())
	c.add_child(slider)
	button(c,"Privacy & credits",func(): info(in_game))
	if ads.privacy_options_required(): button(c,"Privacy options",ads.show_privacy_options)
	spacer(c)
	button(c,"Back",func():
		if in_game: pause_menu()
		else: menu())
func info(in_game: bool) -> void:
	var c = reset_ui("info")
	heading(c,"Privacy & credits")
	label_in(c,"Progress, preferences and a bounded gameplay event log are stored on this device. No account or external analytics. Advertising is disabled in this build. No advertising consent request is made.\n\nOriginal procedural geometry, puzzle generation and soundscape. Built with Godot Engine (MIT). Noto Serif and Noto Sans by the Noto Project Authors (SIL OFL 1.1).\n\nDeveloper contact and hosted privacy policy must be configured before distribution.",20)
	spacer(c)
	button(c,"Back",func(): settings(in_game))
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and playing: pause_menu(); return
	if not playing or busy: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom = minf(3.0,zoom*1.12)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom = maxf(1.0,zoom/1.12)
		elif event.button_index==MOUSE_BUTTON_LEFT: pointer(event.pressed,event.position)
	elif event is InputEventMouseMotion and pressed: rotate_by(event.relative,event.position)
	elif event is InputEventScreenTouch:
		if event.pressed: fingers[event.index] = event.position
		else: fingers.erase(event.index)
		if fingers.size()>=2:
			pinching = true
			pressed = false
			dragging = true
			velocity = Vector2.ZERO
			var values = fingers.values()
			pinch_distance = values[0].distance_to(values[1])
		elif pinching:
			if fingers.is_empty(): pinching = false; pinch_distance = 0
		else: pointer(event.pressed,event.position)
	elif event is InputEventScreenDrag:
		if not fingers.has(event.index): return
		fingers[event.index] = event.position
		if pinching:
			if fingers.size()>=2:
				var values = fingers.values()
				var distance: float = values[0].distance_to(values[1])
				if pinch_distance>1: zoom = clampf(zoom*distance/pinch_distance,1.0,3.0)
				pinch_distance = distance
		else: rotate_by(event.relative,event.position)
func pointer(down: bool, pos: Vector2) -> void:
	if down:
		if not play_area.get_global_rect().has_point(pos): return
		pressed = true
		drag_start = pos
		dragging = false
		velocity = Vector2.ZERO
	else:
		if pressed and not dragging and not pinching:
			var id = pick_arrow(pos)
			if id>=0: attempt(id)
		pressed = false
func apply_rotation(amount: Vector2) -> void:
	# Rotate about screen axes: dragging keeps following the finger even after
	# turning to another face, unlike coupled local Euler angles.
	pivot.quaternion = (Quaternion(Vector3.UP,amount.x) * Quaternion(Vector3.RIGHT,amount.y) * pivot.quaternion).normalized()
func rotate_by(relative: Vector2, pos: Vector2) -> void:
	if not pressed: return
	if pos.distance_to(drag_start) > 12: dragging = true
	if dragging:
		var scale_factor = 0.006 * float(store.data.settings.sensitivity)
		if bool(store.data.settings.get("invert_drag",false)): relative = -relative
		apply_rotation(relative * scale_factor)
		velocity = relative * scale_factor * 12
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		sound.set_backgrounded(true)
		store.save()
		if playing: pause_menu()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		sound.set_backgrounded(false)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST: store.save()

func _exit_tree() -> void:
	if daily_thread.is_started(): daily_thread.wait_to_finish()
	store.save()
