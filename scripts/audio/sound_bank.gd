extends AudioStreamPlayer
## Imported original assets: synthesis is an offline authoring step.
var enabled = true
var music_enabled = false
var backgrounded = false
var music_player: AudioStreamPlayer
var music_fade: Tween
const NOTES = {
	"tap":preload("res://assets/audio/tap.wav"),
	"remove":preload("res://assets/audio/remove.wav"),
	"invalid":preload("res://assets/audio/invalid.wav"),
	"unlock":preload("res://assets/audio/unlock.wav"),
	"hint":preload("res://assets/audio/hint.wav"),
	"victory":preload("res://assets/audio/victory.wav")
}
func _ready() -> void:
	max_polyphony = 4
func play_note(kind: String) -> void:
	if not enabled or backgrounded: return
	stream = NOTES.get(kind,NOTES.tap)
	play()
func set_music(on: bool) -> void:
	music_enabled = on
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.stream = preload("res://assets/audio/moonlit.ogg")
		music_player.volume_db = -4.0
		add_child(music_player)
	update_music()
func set_backgrounded(value: bool) -> void:
	backgrounded = value
	if value: stop()
	update_music()
func update_music() -> void:
	if not is_instance_valid(music_player): return
	if is_instance_valid(music_fade): music_fade.kill()
	if music_enabled and not backgrounded:
		music_player.stream_paused = false
		if not music_player.playing:
			music_player.volume_db = -60
			music_player.play()
		music_fade = create_tween()
		music_fade.tween_property(music_player,"volume_db",-4.0,0.65)
	else:
		music_fade = create_tween()
		music_fade.tween_property(music_player,"volume_db",-60.0,0.2)
		music_fade.tween_callback(func(): music_player.stream_paused = true)
func shutdown() -> void:
	if is_instance_valid(music_fade): music_fade.kill()
	stop()
	stream = null
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
func _exit_tree() -> void:
	shutdown()
