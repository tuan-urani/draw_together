#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Error at line $LINENO: $BASH_COMMAND" >&2' ERR

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "Error: Please run this script with bash." >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Bootstrap a new Flutter template project (script-first workflow).

Usage:
  bootstrap_flutter_template.sh [options]

Options:
  -n, --name <project_name>        Project folder name (required if --non-interactive)
  -o, --org <org_id>               Reverse-domain org id (default: com.example)
  -f, --flutter-version <version>  Flutter version for FVM (default: stable)
  -d, --dir <parent_dir>           Parent directory (default: current dir)
      --force                      Allow create/overwrite in non-empty existing directory
      --non-interactive            Do not prompt for missing values
  -h, --help                       Show this help

Examples:
  ./bootstrap_flutter_template.sh
  ./bootstrap_flutter_template.sh --name my_app --org com.company --flutter-version 3.38.5
  ./bootstrap_flutter_template.sh --name crm_mobile --dir ~/workspace --force
EOF
}

PROJECT_NAME=""
ORG_ID="com.example"
FLUTTER_VERSION="stable"
PARENT_DIR="$(pwd)"
FORCE=0
NON_INTERACTIVE=0
FVM_BIN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      PROJECT_NAME="${2:-}"
      shift 2
      ;;
    -o|--org)
      ORG_ID="${2:-}"
      shift 2
      ;;
    -f|--flutter-version)
      FLUTTER_VERSION="${2:-}"
      shift 2
      ;;
    -d|--dir)
      PARENT_DIR="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

prompt_required() {
  local current="$1"
  local message="$2"
  if [[ -n "$current" ]]; then
    printf '%s' "$current"
    return
  fi
  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    printf '%s' ""
    return
  fi
  read -r -p "$message" current
  printf '%s' "$current"
}

prompt_with_default() {
  local current="$1"
  local message="$2"
  local fallback="$3"
  local input=""

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    if [[ -n "$current" ]]; then
      printf '%s' "$current"
    else
      printf '%s' "$fallback"
    fi
    return
  fi

  read -r -p "$message" input
  if [[ -n "$input" ]]; then
    printf '%s' "$input"
    return
  fi

  if [[ -n "$current" ]]; then
    printf '%s' "$current"
  else
    printf '%s' "$fallback"
  fi
}

normalize_project_name() {
  local value="$1"
  value="$(printf '%s' "$value" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9_]+/_/g; s/_+/_/g; s/^_+|_+$//g')"
  if [[ -z "$value" ]]; then
    value="flutter_app"
  fi
  if [[ "$value" =~ ^[0-9] ]]; then
    value="app_$value"
  fi
  printf '%s' "$value"
}

append_path_once() {
  local target="$1"
  [[ -n "$target" ]] || return 0
  [[ -d "$target" ]] || return 0
  case ":$PATH:" in
    *":$target:"*) ;;
    *) export PATH="$PATH:$target" ;;
  esac
}

ensure_dart() {
  if command -v dart >/dev/null 2>&1; then
    return
  fi

  if command -v flutter >/dev/null 2>&1; then
    local flutter_cmd=""
    local flutter_bin=""
    local flutter_dart_bin=""
    flutter_cmd="$(command -v flutter)"
    flutter_bin="$(cd "$(dirname "$flutter_cmd")" && pwd)"
    flutter_dart_bin="$flutter_bin/cache/dart-sdk/bin"
    append_path_once "$flutter_dart_bin"
  fi

  append_path_once "/opt/homebrew/opt/dart/libexec/bin"
  append_path_once "/usr/local/opt/dart/libexec/bin"

  if ! command -v dart >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Error: dart command not found.
Please install Dart (or Flutter) and ensure dart is available in PATH.
Example (macOS with Homebrew):
  brew tap dart-lang/dart
  brew install dart
EOF
    exit 1
  fi
}

discover_working_fvm() {
  local candidate=""
  local pub_cache_fvm="$HOME/.pub-cache/bin/fvm"

  if command -v fvm >/dev/null 2>&1; then
    candidate="$(command -v fvm)"
    if "$candidate" --version >/dev/null 2>&1; then
      FVM_BIN="$candidate"
      return 0
    fi
  fi

  if command -v which >/dev/null 2>&1; then
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      if "$candidate" --version >/dev/null 2>&1; then
        FVM_BIN="$candidate"
        return 0
      fi
    done <<< "$(which -a fvm 2>/dev/null || true)"
  fi

  if [[ -x "$pub_cache_fvm" ]]; then
    if "$pub_cache_fvm" --version >/dev/null 2>&1; then
      FVM_BIN="$pub_cache_fvm"
      return 0
    fi
  fi

  return 1
}

run_fvm() {
  "$FVM_BIN" "$@"
}

ensure_fvm() {
  append_path_once "$HOME/.pub-cache/bin"

  if ! discover_working_fvm; then
    ensure_dart
  fi

  if ! discover_working_fvm; then
    echo "Installing FVM..."
    dart pub global activate fvm >/dev/null
    append_path_once "$HOME/.pub-cache/bin"
  fi

  if ! discover_working_fvm; then
    echo "Error: FVM installation failed or fvm is not runnable." >&2
    exit 1
  fi
}

ensure_line_in_file() {
  local file="$1"
  local line="$2"
  touch "$file"
  if ! grep -Fxq "$line" "$file"; then
    printf '%s\n' "$line" >>"$file"
  fi
}

configure_android_flavors() {
  local android_app_id="$ORG_ID.$APP_PACKAGE_NAME"
  local gradle_kts_file="android/app/build.gradle.kts"

  if [[ ! -f "$gradle_kts_file" ]]; then
    echo "Warning: Android Gradle Kotlin file not found, skip flavor config: $gradle_kts_file"
    return 0
  fi

  cat >"$gradle_kts_file" <<EOF
import java.io.File

fun loadEnv(name: String): Map<String, String> {
    val envFile = rootProject.file("../" + name)
    val env = mutableMapOf<String, String>()

    if (envFile.exists()) {
        envFile.forEachLine { line ->
            if (line.isNotBlank() && !line.startsWith("#") && line.contains("=")) {
                val parts = line.split("=", limit = 2)
                env[parts[0].trim()] = parts[1].trim()
            }
        }
    }
    return env
}

val stagingEnv = loadEnv(".env.staging")
val prodEnv = loadEnv(".env.prod")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "$android_app_id"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "$android_app_id"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("prod") {
            dimension = "app"
            resValue("string", "google_maps_api_key", prodEnv["GOOGLE_MAP_API_KEY"] ?: "")
        }
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "google_maps_api_key", stagingEnv["GOOGLE_MAP_API_KEY"] ?: "")
        }
    }
}

flutter {
    source = "../.."
}
EOF

  echo "Configured Android product flavors (prod/staging)."
}

PROJECT_NAME="$(prompt_required "$PROJECT_NAME" "Project name: ")"
if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: project name is required." >&2
  exit 1
fi

ORG_ID="$(prompt_with_default "$ORG_ID" "Org id (default: $ORG_ID): " "com.example")"
FLUTTER_VERSION="$(prompt_with_default "$FLUTTER_VERSION" "Flutter version (default: $FLUTTER_VERSION): " "stable")"

APP_PACKAGE_NAME="$(normalize_project_name "$PROJECT_NAME")"
if [[ ! -d "$PARENT_DIR" ]]; then
  echo "Error: parent directory does not exist: $PARENT_DIR" >&2
  exit 1
fi
PARENT_DIR="$(cd "$PARENT_DIR" && pwd)"
PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"

if [[ -d "$PROJECT_DIR" ]] && [[ -n "$(ls -A "$PROJECT_DIR" 2>/dev/null || true)" ]] && [[ "$FORCE" -ne 1 ]]; then
  echo "Error: '$PROJECT_DIR' exists and is not empty. Use --force to continue." >&2
  exit 1
fi

echo "Bootstrapping project:"
echo "- Directory: $PROJECT_DIR"
echo "- App package name: $APP_PACKAGE_NAME"
echo "- Org: $ORG_ID"
echo "- Flutter version: $FLUTTER_VERSION"

echo "Preparing Flutter toolchain..."
ensure_fvm
echo "- FVM binary: $FVM_BIN"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "Running: fvm use $FLUTTER_VERSION --force"
if ! run_fvm use "$FLUTTER_VERSION" --force; then
  echo "Error: fvm use failed. Please verify your Flutter version and FVM setup." >&2
  echo "Try manually: $FVM_BIN use $FLUTTER_VERSION --force" >&2
  exit 1
fi

create_args=(run_fvm flutter create . --org "$ORG_ID" --project-name "$APP_PACKAGE_NAME")
if [[ "$FORCE" -eq 1 ]]; then
  create_args+=(--overwrite)
fi

echo "Running: flutter create"
if ! "${create_args[@]}"; then
  echo "Error: flutter create failed. Please verify Flutter SDK and project arguments." >&2
  exit 1
fi

configure_android_flavors

mkdir -p .vscode
cat >.vscode/settings.json <<'JSON'
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  }
}
JSON

run_fvm flutter pub add get flutter_bloc equatable dio retrofit json_annotation flutter_dotenv flutter_svg intl
run_fvm flutter pub add flutter_keyboard_visibility:^6.0.0 cached_network_image:^3.3.1 flutter_inappwebview:^6.1.5 pin_code_fields:^8.0.1 gif:^2.3.0
run_fvm flutter pub add carousel_slider:^5.1.1 smooth_page_indicator:^2.0.1
run_fvm flutter pub add shared_preferences
run_fvm flutter pub add percent_indicator:^4.2.2
run_fvm flutter pub add common_widget --git-url https://github.com/tuan-urani/common_widget --git-ref main
run_fvm flutter pub add --dev build_runner retrofit_generator json_serializable

mkdir -p \
  lib/src/api \
  lib/src/core/managers \
  lib/src/core/model/request \
  lib/src/core/model/response \
  lib/src/core/repository \
  lib/src/di \
  lib/src/enums \
  lib/src/extensions \
  lib/src/helper \
  lib/src/locale \
  lib/src/ui/base \
  lib/src/ui/base/interactor \
  lib/src/ui/main \
  lib/src/ui/home/binding \
  lib/src/ui/home/bloc \
  lib/src/ui/splash \
  lib/src/ui/routing \
  lib/src/ui/widgets \
  lib/src/utils

cat >lib/main.dart <<EOF
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:$APP_PACKAGE_NAME/src/di/di_graph_setup.dart';
import 'package:$APP_PACKAGE_NAME/src/locale/translation_manager.dart';
import 'package:$APP_PACKAGE_NAME/src/utils/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependenciesGraph();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: TranslationManager.defaultLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
    );
  }
}
EOF

cat >lib/src/di/di_graph_setup.dart <<'EOF'
import 'environment_module.dart';
import 'register_core_module.dart';
import 'register_manager_module.dart';

Future<void> setupDependenciesGraph() async {
  await registerEnvironmentModule();
  await registerCoreModule();
  await registerManagerModule();
}
EOF

cat >lib/src/di/environment_module.dart <<'EOF'
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> registerEnvironmentModule() async {
  if (dotenv.isInitialized) return;
  await dotenv.load(fileName: '.env');
}
EOF

cat >lib/src/di/register_core_module.dart <<'EOF'
Future<void> registerCoreModule() async {
  // Register core services/repositories here.
}
EOF

cat >lib/src/di/register_manager_module.dart <<'EOF'
Future<void> registerManagerModule() async {
  // Register app-wide managers here.
}
EOF

cat >lib/src/utils/app_colors.dart <<'EOF'
import 'package:flutter/material.dart';
import '../extensions/color_extension.dart';

class AppColors {
  // ===========================================================================
  // PRIMARY
  // ===========================================================================
  static const Color primary = Color(0xFF84C93F);
  static const Color primaryLight = Color(0xFF5CC7A0);

  /// Alpha variants
  static const Color primaryAlpha10 = Color(0x1A84C93F);

  // Backward compatibility
  static const Color color84C93F = primaryAlpha10;
  static const Color color1A84C93F = primaryAlpha10;

  // ===========================================================================
  // SECONDARY
  // ===========================================================================
  static const Color secondary1 = Color(0xFFCAE7B4);
  static const Color secondary2 = Color(0xFFE6F4EC);

  // ===========================================================================
  // NEUTRAL / BLACK
  // ===========================================================================
  static const Color black = Color(0xFF000000);

  // ===========================================================================
  // NEUTRAL / WHITE
  // ===========================================================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // ===========================================================================
  // STATUS
  // ===========================================================================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ===========================================================================
  // TEXT
  // ===========================================================================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textDisabled = Color(0xFFC0C0C0);
  static const Color textInverse = white;

  static const greyF3 = Color(0xFFF3F3F3);
  static const color2D7DD2 = Color(0xFF2D7DD2);
  static const color1D2410 = Color(0xFF1D2410);
  static const color484848 = Color(0xFF484848);
  static const color1C274C = Color(0xFF1C274C);
  static const colorFFF4F2 = Color(0xFFFFF4F2);
  static const colorF5F7FA = Color(0xFFF5F7FA);
  static const colorE6F7ED = Color(0xFFE6F7ED);
  static const color667394 = Color(0xFF667394);
  static const colorFF9800 = Color(0xFFFF9800);
  static const colorB8BCC6 = Color(0xFFB8BCC6);
  static const colorF2F4F7 = Color(0xFFF2F4F7);
  static const colorF9FAFB = Color(0xFFF9FAFB);
  static const colorE1E1E1 = Color(0xFFE1E1E1);
  static const colorE3F2D9 = Color(0xFFE3F2D9);
  static const colorEEEDE9 = Color(0xFFEEEDE9);
  static const color333333 = Color(0xFF333333);
  static const colorEFF8DD = Color(0xFFEFF8DD);
  static const color475467 = Color(0xFF475467);
  static const colorE8EDF5 = Color(0xFFE8EDF5);
  static const colorF4F4F4 = Color(0xFFF4F4F4);
  static const color131A29 = Color(0xFF131A29);
  static const colorD1E8BE = Color(0xFFD1E8BE);
  static const colorE6FAD2 = Color(0xFFE6FAD2);
  static const colorDAFFE0 = Color(0xFFDAFFE0);
  static const color0F000000 = Color(0x0F000000);
  static const colorFAFAFA = Color(0xFFFAFAFA);
  static const colorF8F1DD = Color(0xFFF8F1DD);
  static const colorB7B7B7 = Color(0xFFB7B7B7);
  static const colorFF8C42 = Color(0xFFFF8C42);
  static const color1AFF8C42 = Color(0x1AFF8C42);
  static const colorF1D2BC = Color(0xFFF1D2BC);
  static const colorDFE4F5 = Color(0xFFDFE4F5);
  static const colorF39702 = Color(0xFFF39702);
  static const colorFB1B8D1 = Color(0xFFB1B8D1);
  static const colorF64748B = Color(0xFF64748B);
  static const colorFEF4056 = Color(0xFFEF4056);
  static const colorF586AA6 = Color(0xFF586AA6);
  static const colorFDEF1BC = Color(0xFFDEF1BC);
  static const color101828 = Color(0xFF101828);
  static const colorFFE53E = Color(0xFFFFE53E);
  static const colorEEEAE8 = Color(0xFFEEEAE8);
  static const colorEF4056 = Color(0xFFEF4056);
  static const color1AEF4056 = Color(0x1AEF4056);
  static const colorFF5B42 = Color(0xFFFF5B42);
  static const color33FF5B42 = Color(0x33FF5B42);
  static const color0095FF = Color(0xFF0095FF);
  static const color1A0095FF = Color(0x1A0095FF);
  static const color88CF66 = Color(0xFF88CF66);
  static const color1A88CF66 = Color(0x1A88CF66);
  static const color1A2D7DD2 = Color(0x1A2D7DD2);
  static const colorFEFEFE = Color(0xFFFEFEFE);
  static const colorDCDFEB = Color(0xFFDCDFEB);
  static const color80586AA6 = Color(0x80586AA6);
  static const colorF59AEF9 = Color(0xFF59AEF9);
  static const colorFE4F3FF = Color(0xFFE4F3FF);
  static const colorF6B7280 = Color(0xFF6B7280);
  static const colorFE6F4EC = Color(0xFFE6F4EC);
  static const colorFBFC9DE = Color(0xFFBFC9DE);
  static const colorFE7EDF3 = Color(0xFFE7EDF3);
  static const colorFDCDFEB = Color(0xFFDCDFEB);
  static const colorF101828 = Color(0xFF101828);
  static const colorF646C72 = Color(0xFF646C72);
  static const colorF3F7FC9 = Color(0xFF3F7FC9);
  static const colorFA1AEBE = Color(0xFFA1AEBE);
  static const colorEAF9E6 = Color(0xFFEAF9E6);
  static const colorC8E6C9 = Color(0xFFC8E6C9);
  static const colorE3F2FD = Color(0xFFE3F2FD);
  static const colorFFF3E0 = Color(0xFFFFF3E0);
  static const colorF3E5F5 = Color(0xFFF3E5F5);
  static const color9C27B0 = Color(0xFF9C27B0);
  static const colorFAF9F8 = Color(0xFFFAF9F8);
  static const colorCDCDCD = Color(0xFFCDCDCD);
  static const colorD9DEED = Color(0xFFD9DEED);
  static const colorFDFFFD = Color(0xFFFDFFFD);
  static const colorEBEDF0 = Color(0xFFEBEDF0);
  static const colorF8FAFB = Color(0xFFF8FAFB);
  static const colorFFEAEA = Color(0xFFFFEAEA);
  static const colorEAECF0 = Color(0xFFEAECF0);
  static const colorFFE2D0 = Color(0xFFFFE2D0);

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================
  static const Color background = white;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundDisabled = Color(0xFFE5E5E5);
  static const Color backgroundOverlay = Color(0x80000000);

  // ===========================================================================
  // BORDER
  // ===========================================================================
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================
  static LinearGradient primaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient secondaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary1],
  );

  static LinearGradient primaryTextGradient() =>
      const LinearGradient(colors: [primary, primaryLight]);

  static LinearGradient fadeGradient() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [black.withOpacityX(0.3), black],
  );

  static LinearGradient disabledGradient() =>
      const LinearGradient(colors: [border, borderDark]);

  static LinearGradient primaryBackgroundGradient() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F7FA), Color(0xFFF2F1EC)],
  );

  // ===========================================================================
  // UTIL
  // ===========================================================================
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
EOF

cat >lib/src/utils/app_styles.dart <<'EOF'
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppStyles {
  // Font Families
  static const String fontFamily = 'ZenMaruGothic';
  static const String fontHiraginoKakuProW6 = 'ZenMaruGothic';
  static const String fontHiraginoKakuStd = 'ZenMaruGothic';

  static TextStyle h40({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(45.0, color, fontWeight, height, fontFamily: fontFamily);

  // Text Styles
  static TextStyle h1({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(32.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h2({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) => _textStyle(28.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle headlineLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(36.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle titleLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
  }) => _textStyle(26.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h3({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) => _textStyle(24.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h4({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) => _textStyle(20.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle h5({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w500,
    double? height,
  }) => _textStyle(18.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodyLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(16.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodyMedium({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(14.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle bodySmall({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(12.0, color, fontWeight, height, fontFamily: fontFamily);

  static TextStyle caption({
    String fontFamily = fontFamily,
    Color color = AppColors.black,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) => _textStyle(10.0, color, fontWeight, height, fontFamily: fontFamily);

  // Button Styles
  static TextStyle buttonLarge({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w600,
  }) => _textStyle(16.0, color, fontWeight, 1.5, fontFamily: fontFamily);

  static TextStyle buttonMedium({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w500,
  }) => _textStyle(14.0, color, fontWeight, 1.4, fontFamily: fontFamily);

  static TextStyle buttonSmall({
    String fontFamily = fontFamily,
    Color color = AppColors.white,
    FontWeight fontWeight = FontWeight.w500,
  }) => _textStyle(12.0, color, fontWeight, 1.3, fontFamily: fontFamily);

  // Helper method for text styles
  static TextStyle _textStyle(
    double fontSize,
    Color color,
    FontWeight fontWeight,
    double? height, {
    required String fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }
}
EOF

cat >lib/src/utils/app_assets.dart <<'EOF'
class AppAssets {
  AppAssets._();

  static const String iconsInputRequiredSvg =
      'assets/images/icons/input_required.svg';
  static const String iconsChevronDownSvg =
      'assets/images/icons/chevron down.svg';
  static const String iconsRadioCheckSvg =
      'assets/images/icons/radio_check.svg';
  static const String iconsRadioUncheckSvg =
      'assets/images/icons/radio_uncheck.svg';
  static const String iconsHideEyeSvg = 'assets/images/icons/hide_eye.svg';
  static const String iconsShowEyeSvg = 'assets/images/icons/show_eye.svg';
}
EOF

cat >lib/src/utils/app_dimensions.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDimensions {
  /// Use for padding
  static const double top = 14;
  static const double marginLeft = 14;
  static const double marginRight = 14;
  static const EdgeInsets sideMargins = EdgeInsets.symmetric(horizontal: 14);
  static const EdgeInsets allMargins = EdgeInsets.all(14);

  static const EdgeInsetsGeometry paddingTop = EdgeInsets.only(top: 280);

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static double bottomBarHeight = 80 + Get.mediaQuery.padding.bottom;
  static double iconPlusBottomBarHeight = 40;
  static double totalBottomBarHeight =
      bottomBarHeight + iconPlusBottomBarHeight;
}
EOF

cat >lib/src/extensions/color_extension.dart <<'EOF'
import 'dart:ui';

extension ColorOpacity on Color {
  Color withOpacityX(double value) => withAlpha((value * 255).toInt());
}
EOF

cat >lib/src/extensions/int_extensions.dart <<'EOF'
import 'package:flutter/material.dart';

/// Tai cac UI, Widget sau nay chi can go 6.height or 6.width thay vi phai ghi SizedBox(width: 6), SizedBox(height: 6)
extension IntExtensions on int? {
  /// Leaves given height of space
  Widget get height => SizedBox(height: this?.toDouble());

  /// Leaves given width of space
  Widget get width => SizedBox(width: this?.toDouble());

  /// Radius
  Radius get radius => Radius.circular(this?.toDouble() ?? 0);

  /// BorderRadius All
  BorderRadius get borderRadiusAll =>
      BorderRadius.circular(this?.toDouble() ?? 0);

  /// BorderRadius Top
  BorderRadius get borderRadiusTop =>
      BorderRadius.vertical(top: (this ?? 0).radius);

  /// BorderRadius Bottom
  BorderRadius get borderRadiusBottom =>
      BorderRadius.vertical(bottom: (this ?? 0).radius);

  /// BorderRadius Left
  BorderRadius get borderRadiusLeft =>
      BorderRadius.horizontal(left: (this ?? 0).radius);

  /// BorderRadius Right
  BorderRadius get borderRadiusRight =>
      BorderRadius.horizontal(right: (this ?? 0).radius);

  /// Padding all
  EdgeInsets get paddingAll => EdgeInsets.all((this ?? 0).toDouble());

  /// Padding horizontal
  EdgeInsets get paddingHorizontal =>
      EdgeInsets.symmetric(horizontal: (this ?? 0).toDouble());

  /// Padding vertical
  EdgeInsets get paddingVertical =>
      EdgeInsets.symmetric(vertical: (this ?? 0).toDouble());

  EdgeInsets get paddingLeft => EdgeInsets.only(left: (this ?? 0).toDouble());

  EdgeInsets get paddingRight => EdgeInsets.only(right: (this ?? 0).toDouble());

  EdgeInsets get paddingTop => EdgeInsets.only(top: (this ?? 0).toDouble());

  EdgeInsets get paddingBottom =>
      EdgeInsets.only(bottom: (this ?? 0).toDouble());
}
EOF

cat >lib/src/extensions/string_extensions.dart <<'EOF'
import 'dart:io';

extension NullableStringExtensions on String? {
  /// Returns [true] if this nullable string is either null or empty.
  bool isNullOrEmpty() {
    return this?.trim().isEmpty ?? true;
  }
}

extension StringExtensions on String {
  bool get isNetworkUri => startsWith('http');

  bool get isSvg => endsWith('.svg');

  bool get isLocalPath => File(this).existsSync();

  /// Capitalize first letter of the word
  String get inFirstLetterCaps =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';

  /// Capitalize first letter of each word
  String get capitalizeFirstOfEach => replaceAll(
    RegExp(' +'),
    ' ',
  ).split(' ').map((str) => str.inFirstLetterCaps).join(' ');

  /// Format thousands number to convert to double.
  String get formatThousands => replaceAll(',', '');
}
EOF

cat >lib/src/extensions/double_extensions.dart <<'EOF'
extension DoubleNullExtension on double? {
  bool get isNotNull => this != null;
}

extension DouleWithoutDecimal on double? {
  String get withoutDecimal =>
      this != null ? (this! % 1 == 0 ? '${this!.toInt()}' : '$this') : '0';
}
EOF

cat >lib/src/ui/base/interactor/page_states.dart <<'EOF'
enum PageState { initial, loading, failure, success }
EOF

cat >lib/src/enums/toast_type.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../extensions/int_extensions.dart';
import '../locale/locale_key.dart';
import '../utils/app_colors.dart';

enum ToastType {
  success(Colors.green),
  error(AppColors.error);

  final Color color;
  const ToastType(this.color);

  Widget get icon {
    IconData icon;
    switch (this) {
      case ToastType.success:
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        icon = Icons.error_rounded;
    }

    return Padding(
      padding: 20.paddingLeft,
      child: Icon(icon, size: 40, color: color),
    );
  }

  Widget get title {
    switch (this) {
      case ToastType.success:
        return Text(LocaleKey.success.tr, style: TextStyle(color: color));
      case ToastType.error:
        return Text(LocaleKey.error.tr, style: TextStyle(color: color));
    }
  }
}
EOF

cat >lib/src/utils/app_shared.dart <<'EOF'
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class AppShared {
  static const String keyName = 'app';
  static const String keyBox = '${keyName}_shared';

  static const String _keyFcmToken = '${keyName}_keyFCMToken';
  static const String _keyTokenValue = '${keyName}_keyTokenValue';
  static const String _keyLanguageCode = '${keyName}_keyLanguageCode';

  final SharedPreferences _prefs;
  final StreamController<String?> _tokenValueController =
      StreamController<String?>.broadcast();

  AppShared(this._prefs);

  Future<void> setTokenFcm(String firebaseToken) async {
    await _prefs.setString(_keyFcmToken, firebaseToken);
  }

  String? getTokenFcm() => _prefs.getString(_keyFcmToken);

  Future<void> setLanguageCode(String languageCode) async {
    await _prefs.setString(_keyLanguageCode, languageCode);
  }

  String? getLanguageCode() => _prefs.getString(_keyLanguageCode);

  Future<void> setTokenValue(String tokenValue) async {
    await _prefs.setString(_keyTokenValue, tokenValue);
    _tokenValueController.add(tokenValue);
  }

  String? getTokenValue() => _prefs.getString(_keyTokenValue);

  Stream<String?> watchTokenValue() => _tokenValueController.stream;

  Future<int> clear() async {
    await _prefs.remove(_keyFcmToken);
    await _prefs.remove(_keyTokenValue);
    await _prefs.remove(_keyLanguageCode);
    _tokenValueController.add(null);
    return 1;
  }

  void dispose() {
    _tokenValueController.close();
  }
}
EOF

cat >lib/src/utils/app_pages.dart <<EOF
import 'package:get/get.dart';

import 'package:$APP_PACKAGE_NAME/src/ui/home/binding/home_binding.dart';
import 'package:$APP_PACKAGE_NAME/src/ui/home/home_page.dart';
import 'package:$APP_PACKAGE_NAME/src/ui/main/main_page.dart';
import 'package:$APP_PACKAGE_NAME/src/ui/splash/splash_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(
      name: splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: main,
      page: () => const MainPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
  ];
}
EOF

cat >lib/src/ui/splash/splash_page.dart <<EOF
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:$APP_PACKAGE_NAME/src/utils/app_pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Get.offNamed(AppPages.main);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
EOF

cat >lib/src/locale/locale_key.dart <<'EOF'
class LocaleKey {
  LocaleKey._();

  static const String homeTitle = 'home_title';
  static const String loginSessionExpires = 'loginSessionExpires';
  static const String success = 'success';
  static const String error = 'error';
  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String widgetCancel = 'widgetCancel';
  static const String widgetConfirm = 'widgetConfirm';
}
EOF

cat >lib/src/locale/lang_en.dart <<'EOF'
import 'locale_key.dart';

final Map<String, String> enUs = <String, String>{
  LocaleKey.homeTitle: 'Home',
  LocaleKey.loginSessionExpires: 'Login session expires!',
  LocaleKey.success: 'Success',
  LocaleKey.error: 'Error',
  LocaleKey.ok: 'OK',
  LocaleKey.cancel: 'Cancel',
  LocaleKey.widgetCancel: 'Cancel',
  LocaleKey.widgetConfirm: 'Confirm',
};
EOF

cat >lib/src/locale/lang_ja.dart <<'EOF'
import 'locale_key.dart';

final Map<String, String> jaJp = <String, String>{
  LocaleKey.homeTitle: 'ホーム',
  LocaleKey.loginSessionExpires: 'ログインセッションが期限切れです！',
  LocaleKey.success: '成功',
  LocaleKey.error: 'エラー',
  LocaleKey.ok: 'OK',
  LocaleKey.cancel: 'キャンセル',
  LocaleKey.widgetCancel: 'キャンセル',
  LocaleKey.widgetConfirm: '決定する',
};
EOF

cat >lib/src/locale/translation_manager.dart <<'EOF'
import 'dart:ui';

import 'package:get/get.dart';

import 'lang_en.dart';
import 'lang_ja.dart';

class TranslationManager extends Translations {
  static const Locale defaultLocale = Locale('en', 'US');
  static const Locale fallbackLocale = Locale('en', 'US');
  static const List<Locale> appLocales = <Locale>[
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ];

  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
        'en_US': enUs,
        'ja_JP': jaJp,
      };
}
EOF

cat >lib/src/ui/main/main_page.dart <<EOF
import 'package:flutter/material.dart';

import 'package:$APP_PACKAGE_NAME/src/ui/home/home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
EOF

cat >lib/src/ui/home/home_page.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../locale/locale_key.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKey.homeTitle.tr),
      ),
      body: Center(
        child: Text(LocaleKey.homeTitle.tr),
      ),
    );
  }
}
EOF

cat >lib/src/ui/home/binding/home_binding.dart <<EOF
import 'package:get/get.dart';

import 'package:$APP_PACKAGE_NAME/src/ui/home/bloc/home_bloc.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeBloc>()) {
      Get.lazyPut<HomeBloc>(HomeBloc.new);
    }
  }
}
EOF

cat >lib/src/ui/home/bloc/home_bloc.dart <<'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Cubit<int> {
  HomeBloc() : super(0);
}
EOF

cat >lib/src/ui/routing/home_router.dart <<EOF
import 'package:flutter/material.dart';

import 'package:$APP_PACKAGE_NAME/src/ui/home/home_page.dart';

Route<dynamic> homeRouter(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const HomePage(),
  );
}
EOF

cat >.env <<'EOF'
API_BASE_URL=https://api.example.com
EOF

cat >.env.staging <<'EOF'
API_BASE_URL=https://staging-api.example.com
EOF

cat >.env.prod <<'EOF'
API_BASE_URL=https://api.example.com
EOF

ensure_line_in_file .gitignore ".env"
ensure_line_in_file .gitignore ".env.staging"
ensure_line_in_file .gitignore ".env.prod"

run_fvm dart run common_widget update

if [[ -n "$FVM_BIN" ]]; then
  run_fvm dart format lib >/dev/null || true
fi

echo ""
echo "Bootstrap completed."
echo "Next steps:"
echo "1) cd \"$PROJECT_DIR\""
echo "2) fvm flutter run"
