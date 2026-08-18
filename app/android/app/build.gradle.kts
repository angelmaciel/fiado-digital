plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fiadodigital.fiado_digital"
    // flutter_secure_storage 11 exige compilar contra el SDK 37, y para eso
    // hizo falta subir el Android Gradle Plugin a 9.3.1 en settings.gradle.kts:
    // el 9.1.0 que traía la plantilla solo llegaba hasta el 36.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Lo exige flutter_local_notifications: usa las APIs de fecha y hora
        // de Java 8, que en las versiones viejas de Android no existen. El
        // desugaring las reescribe para que funcionen igual.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fiadodigital.fiado_digital"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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

dependencies {
    // Traduce las APIs modernas de fecha y hora de Java para que funcionen en
    // versiones viejas de Android. Va de la mano con
    // `isCoreLibraryDesugaringEnabled` y lo exige flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
