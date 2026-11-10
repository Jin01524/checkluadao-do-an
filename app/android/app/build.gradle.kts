import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyProperties = Properties()
val releaseKeyFile = rootProject.file("key.properties")
if (releaseKeyFile.exists()) {
    FileInputStream(releaseKeyFile).use { releaseKeyProperties.load(it) }
}
val requestedRelease = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val releaseKeyFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
if (requestedRelease &&
    (!releaseKeyFile.exists() || releaseKeyFields.any { releaseKeyProperties.getProperty(it).isNullOrBlank() })
) {
    throw GradleException("Release signing requires android/key.properties with storeFile, storePassword, keyAlias and keyPassword.")
}

android {
    namespace = "com.checkluadao.app_checkluadao_ttnt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.checkluadao.app_checkluadao_ttnt"
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

    if (releaseKeyFile.exists() && releaseKeyFields.all { !releaseKeyProperties.getProperty(it).isNullOrBlank() }) {
        signingConfigs.create("release") {
            storeFile = file(releaseKeyProperties.getProperty("storeFile"))
            storePassword = releaseKeyProperties.getProperty("storePassword")
            keyAlias = releaseKeyProperties.getProperty("keyAlias")
            keyPassword = releaseKeyProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            if (signingConfigs.names.contains("release")) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}

flutter {
    source = "../.."
}
