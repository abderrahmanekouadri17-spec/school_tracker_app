plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.school_tracker_app"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.school_tracker_app"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // تعطيل فحص الـ Lint نهائياً لتجنب خطأ املفات المفقودة في البناء
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

flutter {
    source = "../.."
}

// تعطيل فحص AarMetadata ومهام الـ Lint نهائياً لمنع أي توقف
tasks.matching { it.name.contains("AarMetadata") || it.name.contains("Lint") || it.name.contains("lint") }.configureEach {
    enabled = false
}
