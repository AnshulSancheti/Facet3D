extends Node
## Debug-only bounded frame sampling. No identifiers or external transmission.
var samples: Array[float] = []
var warmup = 2.0
var duration = 0.0
var metadata: Dictionary = {"screen":"menu"}
var reports: Array = []
func set_board(size: int, count: int) -> void:
	metadata = {"screen":"game","board_size":size,"arrows":count}
	samples.clear()
	warmup = 2.0
	duration = 0
func set_screen(mode: String) -> void:
	if metadata.get("screen","")==mode: return
	metadata = {"screen":mode}
	samples.clear()
	warmup = 2.0
	duration = 0
func _process(delta: float) -> void:
	if warmup>0: warmup -= delta; return
	if samples.size()<1500: samples.append(delta)
	duration += delta
	if duration<8.0: return
	var sorted = samples.duplicate()
	sorted.sort()
	var report = metadata.duplicate()
	var game = get_parent()
	var view = game.get("view")
	report["visible_arrow_count"] = view.pieces.size() if view.visible else 0
	var viewport = game.get("world_viewport")
	report["viewport_pixels"] = [viewport.size.x,viewport.size.y]
	report["samples"] = samples.size()
	report["window_seconds"] = duration
	report["average_fps"] = samples.size()/duration
	report["median_frame_ms"] = sorted[sorted.size()/2]*1000
	report["p95_frame_ms"] = sorted[mini(sorted.size()-1,floori(sorted.size()*0.95))]*1000
	report["godot_static_heap_bytes"] = OS.get_static_memory_usage()
	report["render_draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	report["render_video_memory_bytes"] = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	reports.append(report)
	if reports.size()>12: reports.pop_front()
	var file = FileAccess.open("user://performance_report.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(reports,"\t")); file.close()
	print("FACET_PERFORMANCE ",JSON.stringify(report))
	samples.clear()
	duration = 0
