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

// Upload-key signing config — reads from gitignored `android/key.properties`.
// Falls back to debug signing only if the file isn't present (e.g. fresh
// clone with no upload key generated yet).
val keystoreProperties: Properties? = run {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        Properties().apply { keystoreFile.inputStream().use { load(it) } }
    } else {
        null
    }
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

    signingConfigs {
        keystoreProperties?.let { props ->
            create("release") {
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
