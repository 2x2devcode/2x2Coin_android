#!/bin/bash

# Forçar o Qt a rodar em modo terminal (sem exigir interface gráfica/Display)
export QT_QPA_PLATFORM=minimal

# Terminal Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="build.log"
echo "--- Build Log Started at $(date) ---" > "$LOG_FILE"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[WARN] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
    echo "[OK] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
    echo "----------------------------------------"
    tail -n 20 "$LOG_FILE"
    echo "----------------------------------------"
    echo "Check the $LOG_FILE file for more details."
    exit 1
}

# 1. Check Operating System
log_info "1 of 10 Checking operating system..."

if ! grep -q "22.04" /etc/os-release; then
    log_warn "This script is optimized for Ubuntu 22.04. Your system might be incompatible."
else
    log_success "Ubuntu 22.04 detected."
fi

# 2. Install Dependencies if necessary
log_info "2 of 10 Checking and installing system dependencies..."

DEPS="build-essential cmake git curl wget zip unzip openjdk-17-jdk libssl-dev python3-pip libxcb-cursor0"
MISSING_DEPS=""

for dep in $DEPS; do
    if ! dpkg -s $dep >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    log_info "Installing missing dependencies: $MISSING_DEPS"
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y $MISSING_DEPS >> "$LOG_FILE" 2>&1 || log_error "Failed to install dependencies."
else
    log_success "All system dependencies are installed."
fi

# Path Configurations (Corrigido para apontar o SDK/NDK para o /root/)
if [ "$USER" = "root" ] || [ "$HOME" = "/root" ]; then
    export QT_PATH="${QT_ANDROID_PATH:-/root/Qt/6.5.3/android_arm64_v8a}"
else
    export QT_PATH="${QT_ANDROID_PATH:-$HOME/Qt/6.5.3/android_arm64_v8a}"
fi

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/root/android-sdk}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$ANDROID_SDK_ROOT/ndk/25.2.9519653}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export OPENSSL_ANDROID="${OPENSSL_ANDROID:-/home/yiimp/openssl-android}"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
ALT_OPENSSL="$PROJECT_ROOT/third_party/android_openssl"

# Resolve OpenSSL path
resolve_openssl_root() {
    local root="$1"
    [ -f "$root/ssl_3/arm64-v8a/libcrypto_3.so" ] && echo "$root" && return 0
    [ -f "$root/ssl_1.1/arm64-v8a/libcrypto_1_1.so" ] && echo "$root" && return 0
    [ -f "$root/arm64-v8a/libcrypto.so" ] && echo "$root" && return 0
    return 1
}

# 3. Ensure OpenSSL for Android
if ! resolve_openssl_root "$OPENSSL_ANDROID" >/dev/null 2>&1; then
    if [ -d "$OPENSSL_ANDROID" ]; then
        log_info "Directory $OPENSSL_ANDROID exists but without libraries — re-cloning KDAB android_openssl..."
        rm -rf "$OPENSSL_ANDROID"
    fi
    log_info "Cloning KDAB android_openssl into $OPENSSL_ANDROID ..."
    git clone --depth 1 https://github.com/KDAB/android_openssl.git "$OPENSSL_ANDROID" >> "$LOG_FILE" 2>&1 \
        || log_error "git clone android_openssl failed"
fi

if ! resolve_openssl_root "$OPENSSL_ANDROID" >/dev/null 2>&1; then
    log_info "Trying project-local third_party/android_openssl ..."
    if [ ! -d "$ALT_OPENSSL" ]; then
        mkdir -p "$(dirname "$ALT_OPENSSL")"
        git clone --depth 1 https://github.com/KDAB/android_openssl.git "$ALT_OPENSSL" >> "$LOG_FILE" 2>&1 \
            || log_error "git clone into third_party failed"
    fi
    if resolve_openssl_root "$ALT_OPENSSL" >/dev/null 2>&1; then
        OPENSSL_ANDROID="$ALT_OPENSSL"
        export OPENSSL_ANDROID
    fi
fi

if ! resolve_openssl_root "$OPENSSL_ANDROID" >/dev/null 2>&1; then
    log_error "OpenSSL libs missing under OPENSSL_ANDROID=$OPENSSL_ANDROID"
fi

OPENSSL_ROOT_RESOLVED="$(resolve_openssl_root "$OPENSSL_ANDROID")"

if [ -f "$OPENSSL_ROOT_RESOLVED/ssl_3/arm64-v8a/libcrypto_3.so" ]; then
    OPENSSL_ARCH_DIR="$OPENSSL_ROOT_RESOLVED/ssl_3/arm64-v8a"
elif [ -f "$OPENSSL_ROOT_RESOLVED/ssl_1.1/arm64-v8a/libcrypto_1_1.so" ]; then
    OPENSSL_ARCH_DIR="$OPENSSL_ROOT_RESOLVED/ssl_1.1/arm64-v8a"
else
    OPENSSL_ARCH_DIR="$OPENSSL_ROOT_RESOLVED/arm64-v8a"
fi

log_success "OpenSSL OK: $OPENSSL_ARCH_DIR"
export OPENSSL_ANDROID

# 3b. Generate image assets
log_info "3 of 10 Generating image assets..."
if command -v python3 >/dev/null 2>&1; then
    python3 scripts/generate_assets.py >> "$LOG_FILE" 2>&1 || log_info "Asset script skipped (non-fatal)."
elif command -v python >/dev/null 2>&1; then
    python scripts/generate_assets.py >> "$LOG_FILE" 2>&1 || log_info "Asset script skipped (non-fatal)."
else
    log_info "Python not found; ensure required assets exist manually."
fi

# 4. Configure Build Directory
BUILD_DIR="build-android-arm64-release"
log_info "4 of 10 Cleaning previous build directory..."
rm -rf "$BUILD_DIR" >> "$LOG_FILE" 2>&1
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1

EXPECTED_MANIFEST="$PROJECT_ROOT/android/AndroidManifest.xml"

# 5. Run qmake
log_info "5 of 10 Configuring project with qmake..."
ABS_OPENSSL=$(realpath "$OPENSSL_ANDROID")
ABS_SDK=$(realpath "$ANDROID_SDK_ROOT")
ABS_NDK=$(realpath "$ANDROID_NDK_ROOT")

ANDROID_NDK_ROOT="$ABS_NDK" \
ANDROID_SDK_ROOT="$ABS_SDK" \
"$QT_PATH/bin/qmake" ../2x2coin-wallet.pro \
    -spec "$QT_PATH/mkspecs/android-clang" \
    CONFIG+=release \
    ANDROID_ABIS=arm64-v8a \
    OPENSSL_ANDROID="$ABS_OPENSSL" \
    ANDROID_SDK_ROOT="$ABS_SDK" \
    ANDROID_NDK_ROOT="$ABS_NDK" \
    DEFINES+=OPENSSL_SUPPRESS_DEPRECATED \
    QMAKE_CXXFLAGS+=-Wno-deprecated-declarations \
    >> "../$LOG_FILE" 2>&1 || log_error "qmake configuration failed."

# 6. Compile C++
log_info "6 of 10 Compiling native code (C++)..."
make -j$(nproc) >> "../$LOG_FILE" 2>&1 || log_error "C++ compilation failed."

# 7. Prepare androiddeployqt structure
log_info "7 of 10 Preparing deployment structure..."
mkdir -p android-build/libs/arm64-v8a

SO_ORIGINAL=$(find . -maxdepth 3 -name "lib2x2coin-wallet*.so" | grep -v "android-build" | head -n 1)
if [ -n "$SO_ORIGINAL" ] && [ -f "$SO_ORIGINAL" ]; then
    cp "$SO_ORIGINAL" android-build/libs/arm64-v8a/lib2x2coin-wallet_arm64-v8a.so
    log_success "Binary successfully positioned for androiddeployqt."
else
    log_error "Native binary was not generated."
fi

KEYSTORE_NAME="android-build/debug.keystore"
if [ ! -f "$KEYSTORE_NAME" ]; then
    keytool -genkeypair -v \
        -keystore "$KEYSTORE_NAME" \
        -storepass android \
        -alias androiddebugkey \
        -keypass android \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US" \
        >> "../$LOG_FILE" 2>&1
fi

# ==============================================================================
# 8. Generate APK (Versão Monolítica Final - Estrutura Estrita de ABIs)
# ==============================================================================
log_info "8 of 10 Starting APK generation..."

if [ "$USER" = "root" ] || [ "$HOME" = "/root" ]; then
    ANDROID_DEPLOY_QT="/root/Qt/6.5.3/gcc_64/bin/androiddeployqt"
else
    ANDROID_DEPLOY_QT="/home/yiimp/Qt/6.5.3/gcc_64/bin/androiddeployqt"
fi

DEPLOY_JSON="android-2x2coin-wallet-deployment-settings.json"
if [ ! -f "$DEPLOY_JSON" ]; then
    log_error "Deployment JSON file not found."
fi

sed -i 's|"android-build-tools-version": ".*"|"android-build-tools-version": "34.0.0"|g' "$DEPLOY_JSON"

BUILD_ROOT="/root/2x2Coin_android/build-android-arm64-release"
ABS_OUTPUT="$BUILD_ROOT/android-build"

# Forçamos o Gradle a aceitar o Java 17 do sistema globalmente antes de qualquer coisa
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"

log_info "Executando androiddeployqt estrutural..."
"$ANDROID_DEPLOY_QT" \
    --input "$DEPLOY_JSON" \
    --output "$ABS_OUTPUT" \
    --android-platform android-34 \
    --jdk "$JAVA_HOME" \
    --gradle \
    --release \
    --no-build >> "../$LOG_FILE" 2>&1

# Cria rigorosamente a árvore de diretórios moderna do Android exigida pelo Gradle 8
mkdir -p "$ABS_OUTPUT/src/main/java"
mkdir -p "$ABS_OUTPUT/src/main/res"

# --- ESTRUTURAÇÃO DA ABI CORRETA PARA AS LIBS NATIVAS ---
# Criamos uma pasta jniLibs dedicada para não confundir o empacotador do Gradle
JNILIBS_DIR="$ABS_OUTPUT/src/main/jniLibs/arm64-v8a"
mkdir -p "$JNILIBS_DIR"

log_warn "Montando ecossistema de bibliotecas binarias arm64-v8a..."
# Copia todas as libs nativas do Qt 6 para a subpasta correta da arquitetura ABI
cp /root/Qt/6.5.3/android_arm64_v8a/lib/*.so "$JNILIBS_DIR/" 2>/dev/null

# Copia de forma garantida a lib da carteira compilada para a mesma pasta
cp "$BUILD_ROOT/lib2x2coin-wallet_arm64-v8a.so" "$JNILIBS_DIR/" 2>/dev/null
# --------------------------------------------------------

# Injeção Manual do build.gradle Estruturado de Forma Correta
log_warn "Sincronizando configuracao estrutural do build.gradle..."
cat << 'EOF' > "$ABS_OUTPUT/build.gradle"
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Única função do buildscript: carregar o plugin de compilação do Android
        classpath 'com.android.tools.build:gradle:8.2.2'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Aponta para as dependências locais internas do Qt no servidor
        maven { url "/root/Qt/6.5.3/android_arm64_v8a/src/android/dependency" }
    }
}

apply plugin: 'com.android.application'

// Aqui ficam as dependências do aplicativo que vão entrar no classes.dex
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar', '*.aar'])

    // Versão estável e disponível globalmente (Corrige o erro checkReleaseAarMetadata)
    implementation "androidx.biometric:biometric:1.1.0"

    // Força o Gradle a compilar e embutir os arquivos JAR e AAR do motor do Qt
    implementation fileTree(dir: '/root/Qt/6.5.3/android_arm64_v8a/jar', include: ['*.jar'])
    implementation fileTree(dir: '/root/Qt/6.5.3/android_arm64_v8a/src/android/dependency', include: ['*.aar', '*.jar'])
}

android {
    namespace "com.coin2x2.wallet"
    compileSdk 34

    compileSdkVersion 34
    buildToolsVersion "34.0.0"
    ndkVersion "25.2.9519653"

    packagingOptions.jniLibs.useLegacyPackaging true

    sourceSets {
        main {
            manifest.srcFile 'src/main/AndroidManifest.xml'
            
            // Mapeamento estático e agressivo para as pastas de código-fonte Java do Qt
            java.srcDirs = ['/root/Qt/6.5.3/android_arm64_v8a/src/android/java/src', 'src/main/java']
            aidl.srcDirs = ['/root/Qt/6.5.3/android_arm64_v8a/src/android/java/src', 'src/main/aidl']
            res.srcDirs = ['/root/Qt/6.5.3/android_arm64_v8a/src/android/java/res', 'src/main/res']
            assets.srcDirs = ['src/main/assets']
            
            // Aponta para a raiz estruturada contendo a pasta arm64-v8a limpa
            jniLibs.srcDirs = ['src/main/jniLibs']
        }
    }

    tasks.withType(JavaCompile) {
        options.incremental = true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    lintOptions {
        abortOnError false
    }

    aaptOptions {
        noCompress 'rcc'
    }

    defaultConfig {
        resConfig "en"
        minSdkVersion 26
        targetSdkVersion 34
        ndk.abiFilters = ["arm64-v8a"]
    }
}

gradle.projectsLoaded {
    rootProject.allprojects {
        buildscript {
            repositories {
                google()
                mavenCentral()
            }
        }
        repositories {
            google()
            mavenCentral()
        }
        pluginManager.withPlugin('com.android.application') {
            dependencies {
                implementation "androidx.biometric:biometric:1.1.0"
            }
        }
    }
}
EOF

# Tratamento e posicionamento do Manifesto no local correto moderno (src/main/)
# Removido o atributo package="..." redundante para sanar a recomendação do task processReleaseMainManifest
GENERATED_MANIFEST="$ABS_OUTPUT/src/main/AndroidManifest.xml"
log_warn "Injetando AndroidManifest.xml compativel com as amarracoes do Qt..."
cat << 'EOF' > "$GENERATED_MANIFEST"
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application 
        android:label="2x2Coin Wallet" 
        android:icon="@android:drawable/sym_def_app_icon"
        android:theme="@android:style/Theme.NoTitleBar" 
        android:allowBackup="true"
        android:hasCode="true">
        
        <activity 
            android:name="org.qtproject.qt.android.bindings.QtActivity" 
            android:exported="true" 
            android:configChanges="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|layoutDirection|locale|fontScale|keyboard|keyboardHidden|navigation">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <meta-data android:name="android.app.lib_name" android:value="2x2coin-wallet_arm64-v8a" />
        </activity>
    </application>
</manifest>
EOF

# Configuração do SDK do Android para o Gradle do sistema
echo "sdk.dir=/root/android-sdk" > "$ABS_OUTPUT/local.properties"

# Ativando suporte ao AndroidX e Jetifier
log_warn "Injetando propriedades AndroidX globais..."
echo "android.useAndroidX=true" > "$ABS_OUTPUT/gradle.properties"
echo "android.enableJetifier=true" >> "$ABS_OUTPUT/gradle.properties"

log_info "Disparando compilacao com Gradle Global (Java 17)..."
cd "$ABS_OUTPUT"

gradle assembleRelease
GRADLE_EXIT_CODE=$?

cd /root/2x2Coin_android/

if [ $GRADLE_EXIT_CODE -ne 0 ]; then
    log_error "A compilacao do Gradle falhou."
    exit 1
fi

# Resgate e centralização do APK gerado pelo Gradle
FOUND_RAW_APK=$(find "$ABS_OUTPUT/build/outputs/apk/" -name "*.apk" | head -n 1)
if [ -n "$FOUND_RAW_APK" ] && [ -f "$FOUND_RAW_APK" ]; then
    cp "$FOUND_RAW_APK" ./2x2coin-wallet-release-unsigned.apk
else
    log_error "O processo do Gradle rodou com sucesso, mas o arquivo APK bruto nao foi localizado."
    exit 1
fi

log_success "Fase Gradle concluida com sucesso!"

# 9. APK Signing and Alignment
log_info "9 of 10 Checking signing dependencies..."
check_and_install() {
    local command_name=$1
    local package_name=$2
    if ! command -v "$command_name" &> /dev/null; then
        sudo apt-get update -y && sudo apt-get install -y "$package_name"
    fi
}
check_and_install "keytool" "default-jdk-headless"
check_and_install "zipalign" "zipalign"
check_and_install "apksigner" "apksigner"

TARGET_NAME="2x2coin-wallet"
APK_RAW="2x2coin-wallet-release-unsigned.apk"
APK_FINAL="${TARGET_NAME}.apk"
KEYSTORE_PATH="$ABS_OUTPUT/debug.keystore"

log_info "Applying zipalign..."
rm -f "$APK_FINAL"
zipalign -v 4 "$APK_RAW" "$APK_FINAL" >> "$LOG_FILE" 2>&1

log_info "Signing APK with apksigner..."
apksigner sign --ks "$KEYSTORE_PATH" --ks-pass pass:android "$APK_FINAL" >> "$LOG_FILE" 2>&1

# 10. Copy Final APK
log_info "10 of 10 Copying signed APK..."
cp "$APK_FINAL" "$BUILD_DIR/${APK_FINAL}"

echo "=========================================================================="
echo -e "${GREEN}[SUCCESS] Process completed successfully!${NC}"
echo "[ROOT LOCATION]   $(pwd)/${APK_FINAL}"
echo "[BUILD COPY]      $(pwd)/$BUILD_DIR/${APK_FINAL}"
echo "=========================================================================="
