plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.mkproject.brain_blocks"
    compileSdk = 36 // Android 15対応
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.mkproject.brain_blocks"
        minSdk = 23 // Android 5.0以上をサポート
        targetSdk = 36 // 最新SDKをターゲット
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // マルチAPK生成（サイズ最適化）
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        
        // Proguard設定
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }

    signingConfigs {
        create("release") {
            // リリース用署名設定（実際の値は環境変数やキーストアから読み込み）
            keyAlias = project.findProperty("keyAlias") as String? ?: System.getenv("KEY_ALIAS")
            keyPassword = project.findProperty("keyPassword") as String? ?: System.getenv("KEY_PASSWORD")
            storeFile = file(project.findProperty("storeFile") as String? ?: System.getenv("STORE_FILE") ?: "debug.keystore")
            storePassword = project.findProperty("storePassword") as String? ?: System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // リリースビルド最適化
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    // APK splits設定（サイズ最適化）
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = true
        }
    }
    
    // Bundle設定
    bundle {
        language {
            enableSplit = false // 多言語対応のため無効化
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.window:window-java:1.3.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    
    // Google Play Services (AdMob用)
    implementation("com.google.android.gms:play-services-ads:23.5.0")
    implementation("com.google.firebase:firebase-analytics-ktx:21.5.1")
}