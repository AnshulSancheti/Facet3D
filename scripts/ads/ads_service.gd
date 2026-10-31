class_name AdsService
extends Node
## Ad-free by default. This facade never uses the editor's simulated ad rewards.
signal reward_earned
signal status_changed(message: String)
signal interstitial_finished
signal event_logged(event_name: String, details: Dictionary)

var configuration: Dictionary = {}
var _adapter: Node
var _started := false
var _last_interstitial_ms := -180000
var _seen_transition := -1
var _pending_reward := false
var _request_token := 0
var _credited_tokens: Dictionary = {}

func start() -> void:
	if _started:
		return
	_started = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/configurations/ads.json"))
	if parsed is Dictionary:
		configuration = parsed
	if configuration.get("mode", "disabled") == "disabled":
		status_changed.emit("Advertisements are disabled. All puzzles remain playable offline.")
		return
	if not _configuration_valid():
		status_changed.emit("Advertising configuration needs review; ads remain disabled.")
		return
	if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
		status_changed.emit("Advertising service is unavailable on this device.")
		return
	var path := "res://scripts/ads/admob_adapter.gd"
	if not FileAccess.file_exists(path):
		return
	_adapter = load(path).new()
	add_child(_adapter)
	_adapter.status_changed.connect(func(message: String): status_changed.emit(message))
	_adapter.reward_received.connect(_on_reward_received)
	_adapter.reward_closed.connect(func(): _pending_reward = false)
	_adapter.interstitial_closed.connect(func(): interstitial_finished.emit())
	_adapter.event_logged.connect(func(event_name: String, details: Dictionary): event_logged.emit(event_name, details))
	_adapter.start(configuration)

func _configuration_valid() -> bool:
	var mode: String = configuration.get("mode", "disabled")
	if mode == "test":
		return configuration.get("android_app_id", "") == "ca-app-pub-3940256099942544~3347511713" and configuration.get("rewarded_unit_id", "") == "ca-app-pub-3940256099942544/5224354917" and configuration.get("interstitial_unit_id", "") == "ca-app-pub-3940256099942544/1033173712"
	if mode != "production" or not configuration.get("audience_reviewed", false):
		return false
	for field in ["android_app_id", "rewarded_unit_id", "interstitial_unit_id"]:
		var value: String = configuration.get(field, "")
		if not value.begins_with("ca-app-pub-") or "3940256099942544" in value:
			return false
	return configuration.android_app_id == ProjectSettings.get_setting("admob/general/android/app_id", "")

func rewarded_available() -> bool:
	return is_instance_valid(_adapter) and not _pending_reward and _adapter.rewarded_available()

func request_rewarded_hint() -> bool:
	if not rewarded_available():
		status_changed.emit("No advertisement is available. You can continue playing.")
		return false
	_request_token += 1
	_pending_reward = true
	event_logged.emit("rewarded_ad_requested", {})
	if not _adapter.show_rewarded(_request_token):
		_pending_reward = false
		return false
	return true

func _on_reward_received(token: int) -> void:
	# Token identity survives duplicate, late, or reordered SDK callbacks.
	if token != _request_token or _credited_tokens.has(token):
		return
	_credited_tokens[token] = true
	event_logged.emit("rewarded_ad_completed", {})
	reward_earned.emit()

func interstitial_policy_allows(completed_level: int, total_completions: int, at_transition := true) -> bool:
	var frequency: int = maxi(1, int(configuration.get("interstitial_level_frequency", 4)))
	if not at_transition or completed_level <= int(configuration.get("ad_free_first_levels", 5)) or total_completions % frequency != 0 or total_completions == _seen_transition:
		return false
	if Time.get_ticks_msec() - _last_interstitial_ms < int(configuration.get("interstitial_cooldown_seconds", 180)) * 1000:
		return false
	return total_completions > 0

func maybe_interstitial(completed_level: int, total_completions: int, at_transition := true) -> bool:
	if not interstitial_policy_allows(completed_level, total_completions, at_transition):
		return false
	if not is_instance_valid(_adapter) or not _adapter.interstitial_available():
		return false
	_seen_transition = total_completions
	_last_interstitial_ms = Time.get_ticks_msec()
	return _adapter.show_interstitial()

func privacy_options_required() -> bool:
	return is_instance_valid(_adapter) and _adapter.privacy_options_required()

func show_privacy_options() -> void:
	if privacy_options_required():
		_adapter.show_privacy_options()
	else:
		status_changed.emit("No advertising privacy options are currently required.")
