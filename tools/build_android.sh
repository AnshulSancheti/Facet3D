#!/usr/bin/env bash
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
MODE="${1:-debug}"
[[ "$MODE" == debug || "$MODE" == release ]] || { echo 'Usage: tools/build_android.sh [debug|release]' >&2; exit 2; }
mkdir -p release/builds release/build-logs
exec > >(tee "release/build-logs/android-${MODE}-$(date -u +%Y%m%dT%H%M%SZ).log") 2>&1
GODOT_BIN="${GODOT_BIN:-}"
if [[ -z "$GODOT_BIN" ]]; then
  for candidate in godot godot4; do
    if command -v "$candidate" >/dev/null; then GODOT_BIN="$(command -v "$candidate")"; break; fi
  done
fi
if [[ -z "$GODOT_BIN" && -x "$HOME/Downloads/Godot_v4.7.2-stable_linux (4).x86_64" ]]; then
  GODOT_BIN="$HOME/Downloads/Godot_v4.7.2-stable_linux (4).x86_64"
fi
[[ -n "$GODOT_BIN" && -x "$GODOT_BIN" ]] || { echo 'Set GODOT_BIN to Godot 4.7.2 standard executable.'; exit 1; }
GODOT_VERSION="$("$GODOT_BIN" --version)"
[[ "$GODOT_VERSION" == 4.7.2.stable* && "$GODOT_VERSION" != *mono* ]] || { echo "Required Godot 4.7.2 standard, found $GODOT_VERSION"; exit 1; }
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
if [[ -z "${JAVA_HOME:-}" ]]; then
  for candidate in "$HOME/.local/share/facet-toolchains/jdk-17" /usr/lib/jvm/java-17-openjdk /usr/lib/jvm/java-25-openjdk; do
    if [[ -x "$candidate/bin/javac" ]]; then export JAVA_HOME="$candidate"; break; fi
  done
fi
export JAVA_HOME="${JAVA_HOME:-}"
[[ -x "$JAVA_HOME/bin/java" && -x "$JAVA_HOME/bin/javac" ]] || { echo 'Set JAVA_HOME to JDK17 or a compatible newer full JDK.'; exit 1; }
"$JAVA_HOME/bin/java" -version
[[ -f "$ANDROID_HOME/platforms/android-36/android.jar" && -x "$ANDROID_HOME/build-tools/36.1.0/zipalign" ]] || { echo 'Missing official Android SDK platform36/build-tools36.1.0'; exit 1; }
if [[ ! -f "$ANDROID_HOME/ndk/29.0.14206865/source.properties" ]]; then
  echo 'NDK29.0.14206865 absent: official engine native source rebuild unavailable.'
  echo 'Continuing with verified official prebuilt engine libraries; Gradle APK export does not compile native source.'
fi
TEMPLATE_DIR="${GODOT_TEMPLATE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.7.2.stable}"
[[ -f "$TEMPLATE_DIR/android_source.zip" ]] || { echo "Missing matching Android source template: $TEMPLATE_DIR/android_source.zip"; exit 1; }
if [[ ! -f android/build/build.gradle && ! -f android/build/app/build.gradle ]]; then
  mkdir -p android/build
  unzip -qo "$TEMPLATE_DIR/android_source.zip" -d android/build
  touch android/build/.gdignore
  chmod +x android/build/gradlew
  printf '4.7.2.stable\n' > android/.build_version
fi
printf 'sdk.dir=%s\n' "$ANDROID_HOME" > android/build/local.properties
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/build-tools/36.1.0:$PATH"
# Godot reads these environment variables in headless export. No global editor settings changed.
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="${GODOT_ANDROID_KEYSTORE_DEBUG_PATH:-$HOME/.android/debug.keystore}"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="${GODOT_ANDROID_KEYSTORE_DEBUG_USER:-androiddebugkey}"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="${GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD:-android}"
if [[ "$MODE" == debug && ! -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" ]]; then
  mkdir -p "$(dirname "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH")"
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" -storepass android -keypass android -alias androiddebugkey -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -keysize 2048 -validity 10000
fi
# Both export presets must remain non-runnable: this disables Godot ADB discovery.
if grep -q '^runnable=true' export_presets.cfg; then
  echo 'Android presets must have runnable=false; device discovery is not authorized.'; exit 1
fi
TASK_CONFIG_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_CONFIG_DIR"' EXIT
mkdir -p "$TASK_CONFIG_DIR/godot"
cat > "$TASK_CONFIG_DIR/godot/editor_settings-4.7.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]
[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/shutdown_adb_on_exit = false
SETTINGS
export XDG_CONFIG_HOME="$TASK_CONFIG_DIR"
"$GODOT_BIN" --headless --editor --path "$TASK_ROOT" --import --quit
[[ -x tools/run_tests.sh ]] || { echo 'Missing required executable tools/run_tests.sh'; exit 1; }
GODOT_BIN="$GODOT_BIN" tools/run_tests.sh
if [[ "$MODE" == release ]]; then
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set release upload keystore path}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set release keystore alias}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set release keystore password}"
  [[ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ]] || { echo 'Release keystore missing'; exit 1; }
  "$GODOT_BIN" --headless --path "$TASK_ROOT" --export-release 'Android Release' "$TASK_ROOT/release/builds/facet-escape-3d-release.aab"
  echo 'Release AAB created. Audit bundletool alignment, derived APKs, policies and hardware before publishing.'
else
  "$GODOT_BIN" --headless --path "$TASK_ROOT" --export-debug 'Android Debug' "$TASK_ROOT/release/builds/facet-escape-3d-debug.apk"
  python3 tools/audit_android.py release/builds/facet-escape-3d-debug.apk
fi
