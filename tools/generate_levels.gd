extends SceneTree
const Generator = preload("res://scripts/generation/level_generator.gd")

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources/levels")
	var levels: Array = []
	for number in range(1,101):
		var level := Generator.new().generate(943791+number*7919,mini(4,(number-1)/20),number)
		if level.has("error"):
			push_error(str(level))
			quit(1)
			return
		# Runtime timings belong in the audit report, not deterministic content.
		level.validation.erase("generation_usec")
		levels.append(level)
	var file := FileAccess.open("res://resources/levels/campaign.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"generator_version":Generator.VERSION,"levels":levels},"\t"))
	print("Generated and independently solved 100 campaign levels")
	quit(0)
