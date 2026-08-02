import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
val allowUnsignedRelease =
    providers.environmentVariable("PAWPAL_ALLOW_UNSIGNED_RELEASE").orNull == "true"

if (releaseTaskRequested) {
    val releaseEnvFile = rootProject.file("../.env")
    if (!releaseEnvFile.exists()) {
        throw GradleException("Missing .env. Release builds require the PawPal production environment.")
    }

    val releaseEnv = releaseEnvFile.readLines()
        .filter { it.isNotBlank() && !it.trimStart().startsWith("#") && it.contains("=") }
        .associate { line ->
            val separator = line.indexOf('=')
            line.substring(0, separator) to line.substring(separator + 1)
        }
    val expectedSupabaseUrl = "https://esrxaniydzgzxxxwzqca.supabase.co"
    if (releaseEnv["SUPABASE_URL"] != expectedSupabaseUrl) {
        throw GradleException(
            "Refusing release build: SUPABASE_URL is not the PawPal production project.",
        )
    }
    val anonKey = releaseEnv["SUPABASE_ANON_KEY"].orEmpty()
    if (anonKey.length < 20 || anonKey == "your_supabase_anon_key") {
        throw GradleException(
            "Refusing release build: SUPABASE_ANON_KEY is missing or a placeholder.",
        )
    }
}

if (releaseTaskRequested && !hasReleaseKeystore && !allowUnsignedRelease) {
    throw GradleException(
        "Missing android/key.properties. Copy android/key.properties.example, fill it in, and point storeFile at the Android upload keystore. CI may set PAWPAL_ALLOW_UNSIGNED_RELEASE=true for a non-publishable verification build.",
    )
}

fun requiredKeystoreValue(name: String): String =
    keystoreProperties[name] as? String
        ?: throw GradleException("Missing '$name' in android/key.properties")

android {
    namespace = "com.creativecurrents.pawpal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.creativecurrents.pawpal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // RevenueCat Purchases 10 uses Google Play Billing 8 (API 23+).
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = requiredKeystoreValue("keyAlias")
                keyPassword = requiredKeystoreValue("keyPassword")
                storeFile = file(requiredKeystoreValue("storeFile"))
                storePassword = requiredKeystoreValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
