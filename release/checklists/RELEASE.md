# Release gate

- [x] Native Godot4.7.2 GDScript project and Android ARM64/API36 export presets.
- [x] Official Poing5.1.0 runtime/native ads and UMP adapter; configurable disabled default.
- [x] No credentials in repository; production mode requires reviewed configuration.
- [x] Actual debug APK built; merged manifest/dependency inventory and APK signature recorded.
- [x] Debug APK ELF and ZIP16KB static audit passed for both packaged ARM64 libraries.
- [ ] Signed AAB/bundletool derived APK audit.
- [ ] Authorized physical Android/16KB runtime, gestures, audio, offline/background/save tests.
- [ ] Native rewarded/interstitial/UMP callback, denial, error and privacy-options tests.
- [ ] Frame time, thermal, memory, battery and installation-size measurements.
- [ ] Replace package/identity/contact/privacy website placeholders.
- [ ] Secure authorized upload key, App Signing and incrementing version code.
- [ ] Owner-approved audience/content-rating/Families evaluation.
- [ ] Final SDK-specific Data Safety, ads and advertising-ID declarations.
- [ ] Public privacy policy and real app-ads.txt verified.
- [ ] Original actual-game screenshots, icon/feature graphic and store listing verified.
- [ ] Applicable internal/closed testing, pre-launch reports and accessibility completed.
- [ ] Explicit owner authorization to publish.

- [ ] Resolve official template AGP8.6.1 versus Android API36 supported minimum8.9.1 before release.
- [ ] Review SDK-inherited phone-state/WorkManager foreground-service permissions on real Android; provenance is in android/manifest-merger-debug.txt.
