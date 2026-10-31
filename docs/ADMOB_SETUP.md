# AdMob integration

Pinned vendor: [Poing Studios v5.1.0](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0), MIT. GDScript addon is under `addons/admob`; native core and ads debug/release AARs are installed from the official `android-template-v4.7.2.zip`. No mediation SDKs are enabled. Its actual exporter pins `ads-mobile-sdk:1.4.0` and `constraintlayout:2.2.0`; do not confuse this Next-Gen Google library with legacy play-services-ads. Source APIs were read before implementing the adapter, including native UMP bindings. Bundled skill examples refer to newer APIs absent from this release; the game uses the installed API instead.

`resources/configurations/ads.json` controls disabled/test/production. Disabled is the committed default. The APK can include the SDK while game code never initializes or loads ads. This is not proof that an included SDK has no automatic data behavior; review the final manifest, SDK disclosures and network behavior before publication.

The facade `scripts/ads/ads_service.gd` avoids initializing on desktop or when native singletons are absent. It never invokes vendor editor mock ads. Test mode only accepts Google's exact Android test App ID and test rewarded/interstitial IDs. Change mode to `test` to exercise those on an authorized physical device later. Do not click or repeatedly load live ads.

Production additionally requires `audience_reviewed=true`, non-test IDs and matching `admob/general/android/app_id` in project settings. Supply the real App ID (contains `~`) and ad unit IDs (contain `/`) independently. Configure AdMob Privacy & messaging before testing consent. Resolve audience, child-directed and age-of-consent settings based on the actual product; no children/adult assertion has been made.

At launch with ads enabled, UMP requests updated consent information. Required forms are loaded and shown. The v5.1.0 binding does not expose `canRequestAds`; the adapter conservatively permits only SDK `OBTAINED` or `NOT_REQUIRED` statuses, including cached status on update failure. Unknown/required consent never requests ads. SDK initialization occurs once. Privacy Options appears only when SDK reports REQUIRED. Opening options destroys cached ad objects and rechecks consent before loading again.

Rewarded hints require an explicit player click and available ad. Only the legitimate SDK earned-reward callback emits `reward_earned`; per-request tokens suppress duplicates and stale callbacks. Dismissal/failure gives no reward. Failures never block puzzles. Interstitial eligibility is checked only at a completed-level transition: after level5, every fourth completion, at least180seconds apart. Startup, restart and solving never call it. No ad result gates progression.

Before release: verify forms in relevant test geographies, consent failures, privacy options, dismissal without reward, duplicate callbacks, app backgrounding, native dependency manifest, approved audience flags, offline play and SDK network behavior. None of those Android runtime checks can be claimed from desktop policy tests.

`release/app-ads.txt.template` needs a real publisher ID. Host the completed file at `https://YOUR_DEVELOPER_WEBSITE/app-ads.txt`, use that developer website in the store listing and verify that AdMob successfully crawls it. Never ship the placeholder as a publisher record.
