import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Pull the AdMob App ID from a gitignored `android/local.properties` (key
// `ADMOB_APP_ID_ANDROID=...`) so the literal value never lands in tracked
// sources. Falls back to Google's universal sample App ID, which is safe to
// ship if a real ID isn't configured — the SDK will refuse to serve real ads.
val admobAppIdAndroid: String = run {
    val props = Properties()
    val localPropsFile = rootProject.file("local.properties")
    if (localPropsFile.exists()) {
        localPropsFile.inputStream().use { props.load(it) }
    }
    (project.findProperty("ADMOB_APP_ID_ANDROID") as String?)
        ?: props.getProperty("ADMOB_APP_ID_ANDROID")
        ?: System.getenv("ADMOB_APP_ID_ANDROID")
        ?: "ca-app-pub-3940256099942544~3347511713"
}

android {
    namespace = "com.heffelhoff.heffelhoffsudoku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.heffelhoff.heffelhoffsudoku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["admobAppId"] = admobAppIdAndroid
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
