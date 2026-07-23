import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de release réelle (CLAUDE.md §9.2) — jamais commitée (voir
// android/.gitignore). Écrite par la CI GitHub Actions à partir de secrets
// pour le job build_android_release_aab ; absente sinon, auquel cas le
// build release retombe automatiquement sur la clé de debug plus bas.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rentavtc.renta_vtc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications (API java.time désucrées) —
        // sans ça, le build release échoue au lieu de simplement avertir.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rentavtc.renta_vtc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // rootProject.file, pas file() : storeFile est relatif à
                // android/ (où vit key.properties), pas à android/app/.
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Vraie clé de release si key.properties est présent en local ;
            // sinon repli sur la clé de debug (cas de la CI, qui ne doit
            // jamais avoir accès à cette clé secrète).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 minifiait/renommait des classes dont WorkManager (utilisé en
            // interne par flutter_local_notifications) a besoin par
            // réflexion au démarrage, provoquant un crash immédiat au
            // lancement ("Failed to create an instance of
            // androidx.work.impl.WorkDatabase") — désactivé tant qu'on n'a
            // pas de règles ProGuard/R8 dédiées.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
