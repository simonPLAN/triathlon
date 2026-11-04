import java.util.Base64
import java.util.Properties
import java.net.URI

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val identite = Properties().apply {
    rootProject.file("application.properties").reader(Charsets.UTF_8).use { load(it) }
}
val cleUpload = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.isFile) fichier.inputStream().use { load(it) }
}
fun secret(nom: String, propriete: String): String? =
    providers.environmentVariable(nom).orNull?.takeIf { it.isNotBlank() }
        ?: cleUpload.getProperty(propriete)?.takeIf { it.isNotBlank() }

val fichierCle = secret("TRIATHLON_STORE_FILE", "storeFile")
val motDePasseMagasin = secret("TRIATHLON_STORE_PASSWORD", "storePassword")
val aliasCle = secret("TRIATHLON_KEY_ALIAS", "keyAlias")
val motDePasseCle = secret("TRIATHLON_KEY_PASSWORD", "keyPassword")
val signatureDisponible = listOf(fichierCle, motDePasseMagasin, aliasCle, motDePasseCle).all { it != null }
val parametresDart = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.filter { it.isNotEmpty() }?.associate {
        val entree = String(Base64.getDecoder().decode(it), Charsets.UTF_8).split("=", limit = 2)
        entree[0] to entree.getOrElse(1) { "" }
    }.orEmpty()
val nomPublic = identite.getProperty("appName", "Triathlon")
val identifiantPublic = identite.getProperty("applicationId", "com.example.triathlon")

android {
    namespace = identite.getProperty("namespace", identifiantPublic)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildFeatures { resValues = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = identifiantPublic
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environnement"
    productFlavors {
        create("production") {
            dimension = "environnement"
            resValue("string", "app_name", nomPublic)
            manifestPlaceholders["authScheme"] = "triathlon"
        }
        create("staging") {
            dimension = "environnement"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "$nomPublic (test)")
            manifestPlaceholders["authScheme"] = "triathlon-staging"
        }
    }

    signingConfigs {
        if (signatureDisponible) {
            create("upload") {
                storeFile = rootProject.file(fichierCle!!)
                storePassword = motDePasseMagasin
                keyAlias = aliasCle
                keyPassword = motDePasseCle
            }
        }
    }
    buildTypes {
        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = if (signatureDisponible) signingConfigs.getByName("upload") else null
        }
    }
}

// Controle au moment de produire un artefact Release, sans bloquer analyse/debug.
// Aucun repli vers la cle debug, meme en l'absence de key.properties.
listOf("production", "staging").forEach { environnement ->
    val variante = environnement.replaceFirstChar { it.uppercase() } + "Release"
    val verification = tasks.register("verifier$variante") {
        group = "verification"
        doLast {
            require(identite.getProperty("identityConfirmed") == "true" &&
                !identifiantPublic.startsWith("com.example.") &&
                identifiantPublic.matches(Regex("[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+"))) {
                "Identite Android a confirmer dans android/application.properties avant Release."
            }
            require(signatureDisponible && rootProject.file(fichierCle!!).isFile) {
                "Signature upload manquante : configurer les variables TRIATHLON_* ou android/key.properties."
            }
            require(parametresDart["APP_ENV"] == environnement) {
                "APP_ENV doit correspondre a la variante $environnement."
            }
            val nomAttendu = if (environnement == "staging") "$nomPublic (test)" else nomPublic
            require(parametresDart["APP_NAME"] == nomAttendu) {
                "APP_NAME doit correspondre au nom Android de la variante."
            }
            val url = parametresDart["SUPABASE_URL"].orEmpty()
            val uri = runCatching { URI(url) }.getOrNull()
            require(uri?.scheme == "https" && !uri.host.isNullOrBlank() &&
                uri.userInfo == null && uri.query == null && uri.fragment == null &&
                (uri.path.isNullOrEmpty() || uri.path == "/")) {
                "SUPABASE_URL explicite et HTTPS requis pour une Release."
            }
            val production = identite.getProperty("productionSupabaseHost")
            require(!production.isNullOrBlank()) { "Configurer productionSupabaseHost." }
            require(if (environnement == "production") uri!!.host == production else uri!!.host != production) {
                "Le projet Supabase ne correspond pas a cet environnement."
            }
            val cle = parametresDart["SUPABASE_PUBLISHABLE_KEY"].orEmpty()
            require(cle.startsWith("sb_publishable_") || runCatching {
                val payload = cle.split(".")[1]
                val json = String(Base64.getUrlDecoder().decode(payload), Charsets.UTF_8)
                (groovy.json.JsonSlurper().parseText(json) as Map<*, *>)["role"] == "anon"
            }.getOrDefault(false)) { "Une cle publique publishable/anon est requise ; aucune cle privilegiee." }
            if (environnement == "production") {
                listOf("PRIVACY_POLICY_URL", "ACCOUNT_DELETION_URL").forEach { nom ->
                    val publique = runCatching { URI(parametresDart[nom].orEmpty()) }.getOrNull()
                    require(publique?.scheme == "https" && publique.host?.contains(".") == true &&
                        publique.userInfo == null && publique.fragment == null) {
                        "$nom doit designer une page publique HTTPS valide avant publication."
                    }
                }
                val email = parametresDart["SUPPORT_EMAIL"].orEmpty()
                require(email.count { it == '@' } == 1 &&
                    email.substringAfter('@').contains('.') && email.none { it.isWhitespace() } &&
                    email.substringBefore('@').isNotBlank()) {
                    "SUPPORT_EMAIL doit contenir le contact de support public."
                }
            }
            require(flutter.versionCode > 0) { "Numero de build positif requis." }
        }
    }
    tasks.configureEach {
        if (name.endsWith(variante) && listOf("assemble", "bundle", "package", "validateSigning").any { name.startsWith(it) }) {
            dependsOn(verification)
        }
    }
}

tasks.register("afficherConfigurationAndroid") {
    group = "verification"
    doLast {
        println("compileSdk=${android.compileSdk}; targetSdk=${android.defaultConfig.targetSdk}; minSdk=${android.defaultConfig.minSdk}")
        println("ndkVersion=${android.ndkVersion}; versionName=${flutter.versionName}; versionCode=${flutter.versionCode}")
        println("applicationId=$identifiantPublic; namespace=${android.namespace}")
        println("Variantes: production / staging (.staging); signature Release: upload uniquement")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter { source = "../.." }
