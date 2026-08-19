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
        // Este identificador es el que Google Cloud Console asocia al cliente
        // OAuth de Android. Cambiarlo obliga a registrar uno nuevo.
        applicationId = "com.fiadodigital.fiado_digital"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Se firma con la clave de depuración a propósito: es la huella
            // SHA-1 registrada en Google Cloud Console, así que el login con
            // Google funciona también en los APK de release que se reparten a
            // mano. Publicar en Play Store exige una clave propia, y con ella
            // hay que registrar un segundo cliente OAuth de Android.
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
