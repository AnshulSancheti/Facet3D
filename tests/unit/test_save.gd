extends SceneTree
const Store = preload("res://scripts/persistence/save_store.gd")
const PATH = "user://save_test_isolated.json"
func write(value: String) -> void:
	var file = FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(value)
	file.close()
func clean() -> void:
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("save_test_isolated.json"): DirAccess.remove_absolute("user://"+file)
func _initialize() -> void:
	clean()
	var old = '{"schema":1,"unlocked":48,"current":40,"hints":3,"completed":{"39":42},"daily":{"2026-10-22":120},"settings":{"sound":false,"music":true,"invert_drag":true,"sensitivity":1.7},"stats":{"moves":99,"sessions":5}}'
	write(old)
	var migrated = Store.new(PATH)
	assert(migrated.migration_error.is_empty())
	assert(FileAccess.get_file_as_string(migrated.archive_path)==old,"Exact old bytes archived before replacement")
	assert(migrated.data.schema==2 and migrated.data.unlocked==1 and migrated.data.current==1)
	assert(migrated.data.completed.is_empty() and migrated.data.daily.is_empty() and migrated.data.stats.moves==0)
	assert(migrated.data.hints==3 and not migrated.data.settings.sound and migrated.data.settings.invert_drag)
	assert(migrated.data.settings.sensitivity==1.7)
	migrated.complete(3,42)
	migrated.complete(3,51)
	assert(migrated.data.completed["3"]==42 and migrated.data.unlocked==4)
	migrated.complete(1,10,"2026-10-22")
	assert(migrated.data.unlocked==4 and migrated.data.daily[Store.daily_key("2026-10-22")]==10)
	assert(not migrated.data.daily.has("2026-10-22"))
	var loaded = Store.new(PATH)
	assert(loaded.data.current==1 and loaded.data.unlocked==4,"Schema2 does not reset again")
	write("{broken")
	var recovered = Store.new(PATH)
	assert(recovered.data.unlocked==4,"Corruption backup recovers")
	write('{"schema":2,"ruleset":"face_edge_snake_v2","completed":{},"settings":{"sound":17,"sensitivity":999},"stats":"broken","unlocked":999}')
	var sanitized = Store.new(PATH)
	assert(sanitized.data.unlocked==100 and sanitized.data.settings.sound and sanitized.data.settings.sensitivity==2.0)
	var first_archive = migrated.archive_path
	write(old.replace('"hints":3','"hints":6'))
	var second = Store.new(PATH)
	assert(second.archive_path!=first_archive and FileAccess.get_file_as_string(first_archive)==old,"Never overwrite an existing archive")
	assert(second.data.hints==6)
	clean()
	print("SAVE_TEST_PASS: exact legacy archive, campaign reset, preferences/hints retained, no repeat reset, daily namespace, corruption recovery and archive non-overwrite")
	quit()
