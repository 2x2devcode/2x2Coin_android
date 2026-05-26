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

# Inclusão da libxcb-cursor0 para evitar quebras de plataforma do Qt6
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

# Ajustado: Agora apontando diretamente para o /root/android-sdk
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

# ==============================================================================
# NOVA ETAPA: Validação Crítica do AndroidManifest.xml antes de criar pastas
# ==============================================================================
EXPECTED_MANIFEST="$PROJECT_ROOT/android/AndroidManifest.xml"
log_info "Verificando integridade do Manifesto Android..."

if [ -f "$EXPECTED_MANIFEST" ]; then
    log_success "AndroidManifest.xml ENCONTRADO em: $EXPECTED_MANIFEST"
else
    echo -e "${RED}[ERROR]${NC} AndroidManifest.xml NÃO FOI ENCONTRADO!"
    echo "Caminho esperado: $EXPECTED_MANIFEST"
    echo "Buscando pelo arquivo no projeto para ajudar a diagnosticar..."
    FOUND_MANIFESTS=$(find "$PROJECT_ROOT" -name "AndroidManifest.xml" 2>/dev/null)
    
    if [ -n "$FOUND_MANIFESTS" ]; then
        echo "O arquivo existe, mas está no local errado:"
        echo "$FOUND_MANIFESTS"
        echo "Ajuste a propriedade ANDROID_PACKAGE_SOURCE_DIR no seu arquivo .pro"
    else
        echo "O arquivo realmente sumiu da estrutura. Sem ele o qmake gerará um pacote sem o ecossistema Java."
    fi
    exit 1
fi
# ==============================================================================

# 4. Configure Build Directory
BUILD_DIR="build-android-arm64-release"

log_info "4 of 10 Cleaning previous build directory..."
rm -rf "$BUILD_DIR" >> "$LOG_FILE" 2>&1
mkdir -p "$BUILD_DIR"

# Força a criação da pasta interna de build do Android e injeta o Manifesto correto
mkdir -p "$BUILD_DIR/android-build"
cp "$EXPECTED_MANIFEST" "$BUILD_DIR/android-build/AndroidManifest.xml"

cd "$BUILD_DIR" || exit 1

# ==============================================================================
# 5. Run qmake (Corrigido com Injeção Direta de Variáveis de Ambiente)
# ==============================================================================
log_info "5 of 10 Configuring project with qmake..."

# Obtém o caminho absoluto e limpo da pasta OPENSSL e do projeto
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

# 7. Prepare androiddeployqt structure (Ajustado para proteger o esqueleto Java do Qt)
log_info "7 of 10 Preparing deployment structure..."

# Garante que o diretório gerado pelo qmake receba o binário sem sobrescrever a árvore
mkdir -p android-build/libs/arm64-v8a

SO_ORIGINAL=$(find . -maxdepth 3 -name "lib2x2coin-wallet*.so" | grep -v "android-build" | head -n 1)

if [ -n "$SO_ORIGINAL" ] && [ -f "$SO_ORIGINAL" ]; then
    log_info "Native binary located at: $SO_ORIGINAL"
    cp "$SO_ORIGINAL" android-build/libs/arm64-v8a/lib2x2coin-wallet_arm64-v8a.so
    log_success "Binary successfully positioned for androiddeployqt."
else
    log_error "Native binary was not generated."
fi

KEYSTORE_NAME="android-build/debug.keystore"

log_info "Expected keystore path: $KEYSTORE_NAME"

# Check if keystore exists
if [ ! -f "$KEYSTORE_NAME" ]; then
    log_info "Debug keystore not found. Creating..."
    mkdir -p "$(dirname "$KEYSTORE_NAME")"

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

# Validate keystore creation
if [ -f "$KEYSTORE_NAME" ]; then
    REAL_PATH=$(realpath "$KEYSTORE_NAME")
    log_info "Keystore successfully found: $REAL_PATH"
else
    log_error "Keystore file was not found after creation attempt."
    exit 1
fi

# ==============================================================================
# 8. Generate APK (Trecho Corrigido para Android 15 / API 35)
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

# ------------------------------------------------------------------------------
# CORREÇÃO FORÇADA: Injeta o manifesto na pasta de build e corrige o JSON capenga
# ------------------------------------------------------------------------------
log_info "Forçando alinhamento do AndroidManifest no esqueleto do build..."
mkdir -p android-build

# Busca o Manifesto original limpo que está na pasta do seu projeto
MANIFEST_FONTE="$PROJECT_ROOT/android/AndroidManifest.xml"

if [ -f "$MANIFEST_FONTE" ]; then
    cp /root/2x2Coin_android/android/AndroidManifest.xml $BUILD_DIR/android-build/AndroidManifest.xml
    log_success "Manifesto copiado com sucesso para android-build/"
else
    log_error "Manifesto original nao encontrado em $MANIFEST_FONTE"
fi

# Corrige a linha do JSON para apontar para a pasta atual absoluta do build
ABS_BUILD_DIR=$(realpath "android-build")
sed -i "s|\"android-package-source-directory\": \".*\"|\"android-package-source-directory\": \"$ABS_BUILD_DIR\"|g" "$DEPLOY_JSON"
# ------------------------------------------------------------------------------

ABS_OUTPUT=$(realpath "android-build")

log_info "Executing tool: $ANDROID_DEPLOY_QT"
"$ANDROID_DEPLOY_QT" \
    --input "$DEPLOY_JSON" \
    --output "$ABS_OUTPUT" \
    --android-platform android-35 \
    --jdk "$JAVA_HOME" \
    --gradle \
    --release \
    >> "../$LOG_FILE" 2>&1 || log_error "androiddeployqt failed."

log_success "Build completed successfully!"
# ==============================================================================

APK_PATH=$(find android-build -name "*.apk" | grep release | head -n 1)

if [ -n "$APK_PATH" ]; then
    cp "$APK_PATH" ../2x2coin-wallet-release.apk
    log_info "APK copied to root: 2x2coin-wallet-release.apk"
else
    log_error "APK generated but not located!"
fi

cd ..

# 9. APK Signing and Alignment
echo "[INFO] 9 of 10 Checking signing dependencies..."

check_and_install() {
    local command_name=$1
    local package_name=$2

    if ! command -v "$command_name" &> /dev/null; then
        echo "[WARNING] Tool '$command_name' was not found. Installing '$package_name'..."
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

if [ -z "$APK_RAW" ] || [ ! -f "$APK_RAW" ]; then
    echo "[ERROR] Raw APK not found!"
    exit 1
fi

echo "[INFO] Applying zipalign..."
rm -f "$APK_FINAL"
zipalign -v 4 "$APK_RAW" "$APK_FINAL"

if [ $? -ne 0 ]; then
    echo "[ERROR] zipalign failed."
    exit 1
fi

echo "[INFO] Signing APK with apksigner..."
apksigner sign --ks "$KEYSTORE_NAME" --ks-pass pass:android "$APK_FINAL"

if [ $? -ne 0 ]; then
    echo "[ERROR] APK signing failed."
    exit 1
fi

# 10. Copy Final APK
echo "[INFO] 10 of 10 Copying signed APK..."
cp "$APK_FINAL" "$BUILD_DIR/${APK_FINAL}"

if [ $? -eq 0 ]; then
    echo "=========================================================================="
    echo "[SUCCESS] Process completed successfully!"
    echo "[ROOT LOCATION]  $(pwd)/${APK_FINAL}"
    echo "[BUILD COPY]     $(pwd)/$BUILD_DIR/${APK_FINAL}"
    echo "=========================================================================="
else
    echo "[ERROR] Failed to copy APK to $BUILD_DIR"
    exit 1
fi
