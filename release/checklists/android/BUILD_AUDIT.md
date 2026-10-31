# Android debug artifact audit — 2026-10-22

Artifact: `/home/intelligentape/Projects/Facet3D/release/builds/facet-escape-3d-debug.apk`

SHA256: `c8a844bac8d7269473c47b4cfe37993df67ed72d8fe825a9c575096bf3e569a2`

Bytes:88591247 (84.49MiB). Final cached build imported latest stable scripts/theme and ran the full wrapper:19577 logical checks/0failures,100 serialized campaign resources+independent DFS, ads policies, save and gameplay integration smoke tests. Gradle debug export succeeded. Test ads remain disabled in packaged ads.json; no live ads or fake rewards were exercised.

APK signature schemev2 verifies. Badging verifies package`com.yourstudio.facetescape3d`, versionCode1/versionName0.1.0, minSDK24, targetSDK36, compileSDK36, ARM64. Manifest verifies portrait, allowBackup=false, extractNativeLibs=false, Google test AdMob AppID and Poing ads/reward/interstitial/UMP plugin registration. `AndroidManifest-debug.xml`, `manifest-merger-debug.txt` and `dependencies-debug.txt` record actual merged dependencies and origin.

Both packaged native libraries, `libgodot_android.so` and `libc++_shared.so`, have every ELF LOAD segment aligned16384; build-tools36.1 zipalign `-c -P16 4` passes. Ads/UMP introduce no additional .so files. APK alignment/signature/manifest reports are alongside the artifact. This is static validation; no physical or emulated Android runtime was accessed.

APK includes exact campaign.json, disabled ads.json and distribution licenses `GODOT_LICENSE.txt`, `GODOT_THIRD_PARTY.txt`, and `addons/admob/LICENSE`. Vendor editor artwork/sample assets are excluded.

Native dependency graph resolves Google Next-Gen ads-mobile-sdk1.4.0, UMP4.0.0, WorkManager2.7.0; no mediation enabled. Permission provenance and unresolved foreground-service review are documented in DATA_SAFETY.md. The standard permission `android.permission.AD_ID` is a redundant vendor AAR declaration, distinct from actual `com.google.android.gms.permission.AD_ID`; it remains visible in the audit. No other unexpected telephony/storage/camera/location runtime permissions were added by game code.

Build used official Godot4.7.2 templates (SHA verified against release digest), official Poing5.1.0 binaries (SHA verified), official Temurin17 installed locally, SDK36/build-tools36.1, Gradle8.11.1 and template AGP8.6.1. No production signing key generated. NDK29 native-source compilation unavailable; prebuilt export succeeded without it. API36 supported minimumAGP8.9.1 toolchain revalidation is still required for release. Signed AAB, bundletool generated APK audit, hardware16KB test, native consent/ad callbacks and phone performance remain unverified. No ADB, emulator, publication or paid account commands were run by build automation.
