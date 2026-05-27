#!/bin/bash

# Forçar o Qt a rodar em modo terminal (sem exigir interface gráfica/Display)
export QT_QPA_PLATFORM=minimal

# Terminal Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="build.log"
echo "--- Build Log Started at $(date) ---" > "$LOG_FILE"

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
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
    log_info "Warning: This script is optimized for Ubuntu 22.04. Your system might be incompatible."
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

# 4. Configure Build Directory (CORRIGIDO: Deixando o qmake criar o esqueleto limpo)
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

# 8. Generate APK (CORRIGIDO: sed apontando para a pasta original do Manifesto)
log_info "8 of 10 Starting APK generation..."

if [ "$USER" = "root" ] || [ "$HOME" = "/root" ]; then
    ANDROID_DEPLOY_QT="/root/Qt/6.5.3/gcc_64/bin/androiddeployqt"
else
    ANDROID_DEPLOY_QT="/root/Qt/6.5.3/gcc_64/bin/androiddeployqt"
fi

DEPLOY_JSON="android-2x2coin-wallet-deployment-settings.json"
if [ ! -f "$DEPLOY_JSON" ]; then
    log_error "Deployment JSON file not found."
fi

sed -i 's|"android-build-tools-version": ".*"|"android-build-tools-version": "34.0.0"|g' "$DEPLOY_JSON"

# Garante a existência da pasta e injeta o manifesto atualizado com o ID do pacote
mkdir -p android-build
cp /root/2x2Coin_android/android/AndroidManifest.xml /root/2x2Coin_android/build-android-arm64-release/android-build/AndroidManifest.xml

BUILD_ROOT="/root/2x2Coin_android/build-android-arm64-release"
ABS_OUTPUT="$BUILD_ROOT/android-build"

log_info "Limpando estruturas antigas..."
rm -rf "$ABS_OUTPUT"
mkdir -p "$ABS_OUTPUT/libs/arm64-v8a"

SOURCE_SO="$BUILD_ROOT/lib2x2coin-wallet_arm64-v8a.so"
if [ -f "$SOURCE_SO" ]; then
    log_info "Injetando binario C++ na estrutura do Android..."
    cp "$SOURCE_SO" "$ABS_OUTPUT/libs/arm64-v8a/lib2x2coin-wallet_arm64-v8a.so"
else
    log_error "Arquivo .so nao foi encontrado em $SOURCE_SO"
    exit 1
fi

# Forçamos o Gradle a aceitar o Java 17 do sistema globalmente antes de chamar o Qt
export GRADLE_OPTS="-Dorg.gradle.java.home=$JAVA_HOME"

log_info "Executando androiddeployqt..."
"$ANDROID_DEPLOY_QT" \
    --input "$DEPLOY_JSON" \
    --output "$ABS_OUTPUT" \
    --android-platform android-34 \
    --jdk "$JAVA_HOME" \
    --gradle \
    --release \
    --no-build >> "../$LOG_FILE" 2>&1

# --- INTERCEPTAÇÃO E CORREÇÃO DO MANIFESTO ---
GENERATED_MANIFEST="$ABS_OUTPUT/AndroidManifest.xml"

# Se o Qt pulou a geração por causa do no-build, nós mesmos criamos um gatilho de correção preventiva
if [ -f "$GENERATED_MANIFEST" ]; then
    log_info "Aplicando patch de remocao do AppCompat no Manifesto..."
    sed -i 's|style/Theme.AppCompat.Light.NoActionBar|android:style/Theme.NoTitleBar|g' "$GENERATED_MANIFEST"
    sed -i 's|@style/Theme.AppCompat|@android:style/Theme.NoTitleBar|g' "$GENERATED_MANIFEST"
else
    log_warn "Manifesto nao gerado nesta etapa, deixando para a compilacao do Gradle..."
fi

# --- CONFIGURAÇÃO DO GRADLE DO SISTEMA ---
log_info "Configurando local.properties..."
echo "sdk.dir=/root/android-sdk" > "$ABS_OUTPUT/local.properties"

log_info "Disparando compilacao com Gradle (Forçando Java 17)..."
cd "$ABS_OUTPUT"

# Chamamos o gradle passando explicitamente o seu JAVA_HOME (Java 17) para evitar o Java 21 do snap
gradle assembleRelease --java-home "$JAVA_HOME"
GRADLE_EXIT_CODE=$?

cd /root/2x2Coin_android/

if [ $GRADLE_EXIT_CODE -ne 0 ]; then
    log_error "A compilacao do Gradle falhou."
    exit 1
fi

# --- CÓPIA DO APK FINAL PARA A RAIZ ---
GENERATED_APK="$ABS_OUTPUT/build/outputs/apk/android-build-release-unsigned.apk"
GENERATED_APK_ALT="$ABS_OUTPUT/build/outputs/apk/release/android-build-release-unsigned.apk"

if [ -f "$GENERATED_APK" ]; then
    cp "$GENERATED_APK" ./2x2coin-wallet.apk
    log_success "Sucesso! APK copiado para a raiz do projeto."
elif [ -f "$GENERATED_APK_ALT" ]; then
    cp "$GENERATED_APK_ALT" ./2x2coin-wallet.apk
    log_success "Sucesso! APK copiado para a raiz do projeto."
else
    log_error "O processo terminou, mas o arquivo APK nao foi encontrado."
    exit 1
fi

log_success "Build concluido com sucesso!"

# 9. APK Signing and Alignment
echo "[INFO] 9 of 10 Checking signing dependencies..."
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
APK_RAW="${TARGET_NAME}-release.apk"
APK_FINAL="${TARGET_NAME}.apk"
KEYSTORE_NAME="$BUILD_DIR/android-build/debug.keystore"

if [ ! -f "$APK_RAW" ]; then
    APK_RAW=$(ls *-unsigned.apk 2>/dev/null | head -n 1)
    if [ -z "$APK_RAW" ]; then
        APK_RAW=$(ls *release.apk 2>/dev/null | head -n 1)
    fi
fi

echo "[INFO] Applying zipalign..."
rm -f "$APK_FINAL"
zipalign -v 4 "$APK_RAW" "$APK_FINAL"

echo "[INFO] Signing APK with apksigner..."
apksigner sign --ks "$KEYSTORE_NAME" --ks-pass pass:android "$APK_FINAL"

# 10. Copy Final APK
echo "[INFO] 10 of 10 Copying signed APK..."
cp "$APK_FINAL" "$BUILD_DIR/${APK_FINAL}"

echo "=========================================================================="
echo "[SUCCESS] Process completed successfully!"
echo "[ROOT LOCATION]  $(pwd)/${APK_FINAL}"
echo "[BUILD COPY]      $(pwd)/$BUILD_DIR/${APK_FINAL}"
echo "=========================================================================="
