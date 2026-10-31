extends Node
## APIs checked against installed Poing v5.1.0 source, not outdated examples.
signal reward_received(token: int)
signal reward_closed
signal interstitial_closed
signal status_changed(message: String)
signal event_logged(event_name: String, details: Dictionary)

var _config: Dictionary
var _initialized := false
var _initializing := false
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _fullscreen := false
var _reward_loader: RewardedAdLoader
var _interstitial_loader: InterstitialAdLoader

func start(config: Dictionary) -> void:
	_config = config
	for singleton_name in ["PoingGodotAdMobConsentInformation", "PoingGodotAdMobUserMessagingPlatform", "PoingGodotAdMobRewardedAd", "PoingGodotAdMobInterstitialAd"]:
		if not Engine.has_singleton(singleton_name):
			status_changed.emit("Native advertising support is incomplete; ads disabled.")
			return
	var parameters := ConsentRequestParameters.new()
	parameters.tag_for_under_age_of_consent = bool(config.get("ump_under_age_of_consent", false))
	UserMessagingPlatform.consent_information.update(parameters, _consent_updated, _consent_failed)

func _consent_updated() -> void:
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		if UserMessagingPlatform.consent_information.get_is_consent_form_available():
			UserMessagingPlatform.load_consent_form(_form_loaded, _consent_failed)
		else:
			status_changed.emit("Advertising consent is unavailable. Continue playing offline.")
	else:
		_initialize_if_allowed()

func _form_loaded(form: ConsentForm) -> void:
	form.show(func(_error: FormError): _initialize_if_allowed())

func _consent_failed(_error: FormError) -> void:
	# Cached obtained/not-required consent can permit ads; unknown/required cannot.
	status_changed.emit("Advertising privacy service could not update.")
	_initialize_if_allowed()

func _can_request_ads() -> bool:
	var status: int = UserMessagingPlatform.consent_information.get_consent_status()
	return status == ConsentInformation.ConsentStatus.OBTAINED or status == ConsentInformation.ConsentStatus.NOT_REQUIRED

func _initialize_if_allowed() -> void:
	if not _can_request_ads() or _initialized or _initializing:
		return
	_initializing = true
	var request := RequestConfiguration.new()
	request.tag_for_child_directed_treatment = int(_config.get("tag_for_child_directed_treatment", -1))
	request.tag_for_under_age_of_consent = int(_config.get("tag_for_under_age_of_consent", -1))
	request.max_ad_content_rating = _config.get("max_ad_content_rating", "G")
	MobileAds.set_request_configuration(request)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus):
		_initializing = false
		_initialized = true
		_load_ads()
	MobileAds.initialize(listener)

func _load_ads() -> void:
	if not _initialized or not _can_request_ads():
		return
	if _rewarded == null:
		_reward_loader = RewardedAdLoader.new()
		var callback := RewardedAdLoadCallback.new()
		callback.on_ad_loaded = func(ad: RewardedAd): _rewarded = ad
		callback.on_ad_failed_to_load = func(_error: LoadAdError): _load_failed("rewarded")
		_reward_loader.load(_config.rewarded_unit_id, AdRequest.new(), callback)
	if _interstitial == null:
		_interstitial_loader = InterstitialAdLoader.new()
		var callback := InterstitialAdLoadCallback.new()
		callback.on_ad_loaded = func(ad: InterstitialAd): _interstitial = ad
		callback.on_ad_failed_to_load = func(_error: LoadAdError): _load_failed("interstitial")
		_interstitial_loader.load(_config.interstitial_unit_id, AdRequest.new(), callback)

func _load_failed(kind: String) -> void:
	event_logged.emit("ad_load_failed", {"format": kind})
	status_changed.emit("No advertisement available. You can continue playing.")

func rewarded_available() -> bool:
	return _rewarded != null and not _fullscreen and _can_request_ads()

func show_rewarded(token: int) -> bool:
	if not rewarded_available():
		return false
	_fullscreen = true
	var ad := _rewarded
	_rewarded = null
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
		ad.destroy()
		_fullscreen = false
		reward_closed.emit()
		_load_ads()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError):
		ad.destroy()
		_fullscreen = false
		reward_closed.emit()
		_load_failed("rewarded")
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_reward: RewardedItem): reward_received.emit(token)
	ad.show(reward_listener)
	return true

func interstitial_available() -> bool:
	return _interstitial != null and not _fullscreen and _can_request_ads()

func show_interstitial() -> bool:
	if not interstitial_available():
		return false
	_fullscreen = true
	var ad := _interstitial
	_interstitial = null
	ad.full_screen_content_callback.on_ad_showed_full_screen_content = func(): event_logged.emit("interstitial_displayed", {})
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
		ad.destroy()
		_fullscreen = false
		interstitial_closed.emit()
		_load_ads()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError):
		ad.destroy()
		_fullscreen = false
		interstitial_closed.emit()
		_load_failed("interstitial")
	ad.show()
	return true

func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if not privacy_options_required() or _fullscreen:
		return
	UserMessagingPlatform.show_privacy_options_form(func(_error: FormError):
		if _rewarded:
			_rewarded.destroy()
			_rewarded = null
		if _interstitial:
			_interstitial.destroy()
			_interstitial = null
		_initialize_if_allowed()
		_load_ads()
	)

func _exit_tree() -> void:
	if _rewarded:
		_rewarded.destroy()
	if _interstitial:
		_interstitial.destroy()
