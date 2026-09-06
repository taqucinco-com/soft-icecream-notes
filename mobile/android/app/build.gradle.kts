import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --dart-define-from-file等で渡されたdart-defineは、Flutter Gradle Pluginにより
// "dart-defines"プロパティとしてbase64エンコードされた"KEY=VALUE"のカンマ区切りで渡される。
// ここからGOOGLE_MAP_KEYを取り出し、AndroidManifest.xmlのmanifestPlaceholdersに注入する。
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.associate {
        val decoded = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
        val (key, value) = decoded.split("=", limit = 2)
        key to value
    }
    ?: emptyMap()

val ciDebugKeystore = rootProject.file("ci-debug.keystore")

android {
    namespace = "com.taqucinco.soft_icecream_notes.icecream_log"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.taqucinco.soft_icecream_notes.icecream_log"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["googleMapsApiKey"] = dartDefines["GOOGLE_MAP_KEY"] ?: ""
    }

    signingConfigs {
        if (System.getenv("GITHUB_ACTIONS") == "true" && ciDebugKeystore.exists()) {
            getByName("debug") {
                storeFile = ciDebugKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
