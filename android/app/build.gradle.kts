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
    namespace = "com.urani.drawtogether.draw_together"
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
        applicationId = "com.urani.drawtogether.draw_together"
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
