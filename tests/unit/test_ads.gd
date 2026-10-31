extends SceneTree
const Service = preload("res://scripts/ads/ads_service.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	var service := Service.new()
	root.add_child(service)
	service.start()
	check(not service.rewarded_available(), "Disabled ads cannot promise rewards")
	check(not service.request_rewarded_hint(), "Disabled ad request fails without charge")
	check(not service.maybe_interstitial(12, 12), "Disabled interstitial never starts")
	service.configuration = {"mode": "production", "audience_reviewed": false}
	check(not service._configuration_valid(), "Unreviewed production is denied")
	service.configuration = {"mode": "test", "android_app_id": "wrong"}
	check(not service._configuration_valid(), "Non-Google test configuration denied")
	service.configuration = JSON.parse_string(FileAccess.get_file_as_string("res://resources/configurations/ads.json"))
	service.configuration.mode = "test"
	check(service._configuration_valid(), "Exact Google test IDs accepted")
	check(not service.interstitial_policy_allows(4, 4), "Tutorial has no interstitials")
	check(not service.interstitial_policy_allows(8, 7), "Interstitial requires fourth completion")
	check(not service.interstitial_policy_allows(8, 8, false), "Solving cannot show interstitials")
	check(service.interstitial_policy_allows(8, 8, true), "Natural fourth completion is eligible")
	service._last_interstitial_ms = Time.get_ticks_msec()
	check(not service.interstitial_policy_allows(12, 12), "180second cooldown applies")
	service._last_interstitial_ms = -180000
	service._seen_transition = 12
	check(not service.interstitial_policy_allows(12, 12), "Same transition cannot repeat")
	var counter := [0]
	service.reward_earned.connect(func(): counter[0] += 1)
	service._request_token = 7
	service._on_reward_received(7)
	service._on_reward_received(7)
	service._on_reward_received(6)
	check(counter[0] == 1, "Reward callbacks are idempotent and token scoped")
	service.free()
	print("Ads policy checks: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
