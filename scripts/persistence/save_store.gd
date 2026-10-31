extends RefCounted
const RULESET = "face_edge_snake_v2"
var path_base = "user://progress.json"
var data: Dictionary
var migration_error = ""
var archive_path = ""
func _init(custom_path: String = "user://progress.json") -> void:
	path_base = custom_path
	data = defaults()
	for path in [path_base,path_base+".bak"]:
		if not FileAccess.file_exists(path): continue
		var source = FileAccess.get_file_as_string(path)
		var parser = JSON.new()
		if parser.parse(source)!=OK: continue
		var parsed = parser.data
		if not parsed is Dictionary or not parsed.get("settings") is Dictionary or not parsed.get("completed") is Dictionary: continue
		if int(parsed.get("schema",0))==1:
			# Archive exact original bytes before replacing any old progress.
			archive_path = path_base+".v1.archive.json"
			var suffix = 1
			while FileAccess.file_exists(archive_path) or DirAccess.dir_exists_absolute(archive_path):
				if FileAccess.file_exists(archive_path) and FileAccess.get_file_as_string(archive_path)==source: break
				suffix += 1
				archive_path = path_base+".v1.archive.%d.json" % suffix
			if not FileAccess.file_exists(archive_path):
				var archive = FileAccess.open(archive_path,FileAccess.WRITE)
				if archive==null:
					migration_error = "Your old progress could not be backed up. Saving is paused; please free storage and retry."
					return
				archive.store_string(source)
				archive.flush()
				archive.close()
				if FileAccess.get_file_as_string(archive_path)!=source:
					migration_error = "Progress backup verification failed. Saving is paused."
					return
			read_preferences(parsed)
			data.hints = clampi(int(parsed.get("hints",5)) if parsed.get("hints",5) is float or parsed.get("hints",5) is int else 5,0,9999)
			save()
			return
		if int(parsed.get("schema",0))!=2 or parsed.get("ruleset","")!=RULESET: continue
		for field in ["unlocked","current","hints"]:
			if parsed.get(field) is float or parsed.get(field) is int: data[field] = int(parsed[field])
		data.unlocked = clampi(int(data.unlocked),1,100)
		data.current = clampi(int(data.current),1,int(data.unlocked))
		data.hints = clampi(int(data.hints),0,9999)
		for field in ["completed","daily"]:
			if parsed.get(field) is Dictionary:
				for key in parsed[field]:
					var value = parsed[field][key]
					if (value is float or value is int) and is_finite(float(value)) and float(value)>=0: data[field][str(key)] = value
		read_preferences(parsed)
		if parsed.get("stats") is Dictionary:
			for key in data.stats:
				var value = parsed.stats.get(key)
				if value is float or value is int: data.stats[key] = maxi(0,int(value))
		return
func read_preferences(parsed: Dictionary) -> void:
	for key in data.settings:
		var value = parsed.settings.get(key)
		if key=="sensitivity":
			if (value is float or value is int) and is_finite(float(value)): data.settings[key] = clampf(float(value),0.3,2)
		elif value is bool: data.settings[key] = value
func defaults() -> Dictionary:
	return {"schema":2,"ruleset":RULESET,"unlocked":1,"current":1,"completed":{},"daily":{},"hints":5,"settings":{"sound":true,"music":true,"haptics":true,"reduced_motion":false,"sensitivity":1.0,"invert_drag":false},"stats":{"moves":0,"sessions":0}}
func save() -> Error:
	if not migration_error.is_empty(): return ERR_CANT_CREATE
	var file = FileAccess.open(path_base+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(path_base):
		var copied = DirAccess.copy_absolute(path_base,path_base+".bak")
		if copied!=OK: return copied
	return DirAccess.rename_absolute(path_base+".tmp",path_base)
static func daily_key(date: String) -> String:
	return RULESET+":facet-edge-2.1.0:"+date
func complete(level: int, seconds: float, daily: String = "") -> void:
	var table: Dictionary = data.completed if daily.is_empty() else data.daily
	var key = str(level) if daily.is_empty() else daily_key(daily)
	table[key] = minf(float(table.get(key,INF)),seconds)
	if daily.is_empty(): data.unlocked = mini(100,maxi(int(data.unlocked),level+1))
	save()
func event(name: String, values: Dictionary = {}) -> void:
	var file = FileAccess.open("user://events.jsonl",FileAccess.READ_WRITE) if FileAccess.file_exists("user://events.jsonl") else FileAccess.open("user://events.jsonl",FileAccess.WRITE)
	if file:
		if file.get_length()>262144:
			file.close()
			file = FileAccess.open("user://events.jsonl",FileAccess.WRITE)
		file.seek_end()
		file.store_line(JSON.stringify({"event":name,"ruleset":RULESET,"utc":Time.get_datetime_string_from_system(true),"values":values}))
