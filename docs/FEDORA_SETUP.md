# Fedora Android build setup

Inspected 2026-10-22: Godot4.7.2 standard Linux executable at `/home/intelligentape/Downloads/Godot_v4.7.2-stable_linux (4).x86_64`; official SDK at `/home/intelligentape/Android/Sdk`, SDK platform36, build-tools36.0.0, platform-tools and NDK28.2.13676358. Initial inventory showed Java21 and25 paths, but the Java21 path contained only manuals; only JDK25 had executables. JDK17 was initially absent. Official Temurin17 is installed locally at `~/.local/share/facet-toolchains/jdk-17` for builds; Godot recommends JDK17 and supports newer JDKs. No ADB or emulator commands are used by build automation. Both Android export presets deliberately have `runnable=false`, which disables the engine's own ADB polling.

Prefer official SDK command-line tools, not old distribution Android packages. Commands for a fresh Fedora machine (review installations yourself):

```bash
sudo dnf install java-17-openjdk-devel unzip zip python3
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
# Download official command-line tools from https://developer.android.com/studio#command-tools
# Extract cmdline-tools into $ANDROID_HOME/cmdline-tools/latest first.
sdkmanager --sdk_root="$ANDROID_HOME" 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0' 'ndk;29.0.14206865'
sdkmanager --sdk_root="$ANDROID_HOME" --licenses
```

License acceptance is a developer decision. Existing accepted SDK installations are reused here. The official 4.7.2 source template pins Gradle 8.11.1, AGP 8.6.1, build-tools 36.1.0 and NDK 29.0.14206865. The wrapper supplies Gradle; no global Gradle package is required. Gradle may install missing official SDK packages only against licenses already accepted in the existing SDK; this task does not accept new license terms.

Download the standard engine and export templates from the [official4.7.2 release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable). Extract `templates/android_source.zip`, `templates/android_debug.apk`, `templates/android_release.apk`, and `templates/version.txt` to `~/.local/share/godot/export_templates/4.7.2.stable/` (strip `templates/`). The initial template archive was1.28GB; Android entries alone are installed. The build script extracts `android_source.zip` into ignored `android/build` automatically.

```bash
export GODOT_BIN='/home/intelligentape/Downloads/Godot_v4.7.2-stable_linux (4).x86_64'
export JAVA_HOME="$HOME/.local/share/facet-toolchains/jdk-17"
export ANDROID_HOME="$HOME/Android/Sdk"
tools/build_android.sh debug
```

The build uses a temporary editor-settings profile for SDK/JDK paths and does not overwrite global settings. It imports, runs tests, exports ARM64 and audits APK ELF/ZIP16KB alignment. Logs are under `release/build-logs`, artifacts under `release/builds`. A debug keystore is generated only if missing using the standard public Android debug identity; it is not a production key.

For a separately authorized production upload key, generate it interactively outside the repository:

```bash
keytool -genkeypair -v -keystore /PRIVATE/PATH/facet-upload.jks -alias facet-upload -keyalg RSA -keysize 4096 -validity 10000
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/PRIVATE/PATH/facet-upload.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=facet-upload
read -rsp 'Upload keystore password: ' GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
tools/build_android.sh release
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Godot's Gradle export passes signing secrets to the Gradle process; use a trusted machine and protect process/build logs. Never commit keys, credentials or export credential files. Google Play App Signing retains the distribution signing key; the upload key authenticates uploads. No production key has been generated in this task.

The debug export completed without NDK29 because official engine libraries are prebuilt. The script checks this separately and prints the native-source-rebuild limitation; it does not silently install/accept new NDK terms. The current official repository's NDK29 license hash was absent from existing accepted licenses. NDK28.2 remains installed. No NDK29 source build was performed. Build-tools36.1.0 was installed by Gradle against the already accepted SDK license.

The official template uses AGP8.6.1, while Android's current supported minimum for API36 is8.9.1 ([tooling matrix](https://developer.android.com/build/releases/about-agp)). The debug artifact built and static audits passed; release toolchain upgrade/revalidation remains pending. The engine and native plugin versions were not substituted.
