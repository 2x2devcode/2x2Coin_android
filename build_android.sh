#!/bin/bash

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
log_info "Checking operating system..."
if ! grep -q "22.04" /etc/os-release; then
    log_info "Warning: This script is optimized for Ubuntu 22.04. Your system might be incompatible."
else
    log_success "Ubuntu 22.04 detected."
fi

# 2. Install Dependencies if necessary
log_info "Checking and installing system dependencies..."
DEPS="build-essential cmake git curl wget zip unzip openjdk-17-jdk libssl-dev python3-pip"
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

# Path Configurations
export QT_PATH="${QT_ANDROID_PATH:-$HOME/Qt/6.5.3/android_arm64_v8a}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/android-sdk}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$ANDROID_SDK_ROOT/ndk/25.2.9519653}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export OPENSSL_ANDROID="${OPENSSL_ANDROID:-$HOME/openssl-android}"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
ALT_OPENSSL="$PROJECT_ROOT/third_party/android_openssl"

# Resolve OpenSSL path (KDAB layout: ssl_3/arm64-v8a/libcrypto_3.so)
resolve_openssl_root() {
    local root="$1"
    [ -f "$root/ssl_3/arm64-v8a/libcrypto_3.so" ] && echo "$root" && return 0
    [ -f "$root/ssl_1.1/arm64-v8a/libcrypto_1_1.so" ] && echo "$root" && return 0
    [ -f "$root/arm64-v8a/libcrypto.so" ] && echo "$root" && return 0
    return 1
}

# 3. Ensure OpenSSL for Android (KDAB prebuilt)
if ! resolve_openssl_root "$OPENSSL_ANDROID" >/dev/null 2>&1; then
    if [ -d "$OPENSSL_ANDROID" ]; then
        log_info "Pasta $OPENSSL_ANDROID existe mas sem libs — re-clonando KDAB android_openssl..."
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
    log_error "OpenSSL libs missing under OPENSSL_ANDROID=$OPENSSL_ANDROID \
Expected: ssl_3/arm64-v8a/libcrypto_3.so (run: ls -la \$OPENSSL_ANDROID/ssl_3/arm64-v8a/)"
fi

if [ ! -f "$OPENSSL_ANDROID/ssl_3/include/openssl/evp.h" ] \
   && [ ! -f "$OPENSSL_ANDROID/ssl_1.1/include/openssl/evp.h" ]; then
    log_error "OpenSSL headers missing. Expected: \$OPENSSL_ANDROID/ssl_3/include/openssl/evp.h"
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

# 3b. Generate placeholder image assets (logo, splash, launcher icon)
log_info "Generating image assets..."
if command -v python3 >/dev/null 2>&1; then
    python3 scripts/generate_assets.py >> "$LOG_FILE" 2>&1 || log_info "Asset script skipped (non-fatal)."
elif command -v python >/dev/null 2>&1; then
    python scripts/generate_assets.py >> "$LOG_FILE" 2>&1 || log_info "Asset script skipped (non-fatal)."
else
    log_info "Python not found; ensure assets/images/*.png and android/res/drawable/ic_launcher.png exist."
fi

# ==============================================================================
# 4. Configure Build Directory (CORRIGIDO: Limpeza limpa sem intervenção manual)
# ==============================================================================
BUILD_DIR="build-android-arm64-release"
log_info "Cleaning previous build directory..."
rm -rf "$BUILD_DIR" >> "$LOG_FILE" 2>&1
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 5. Run qmake
log_info "Configuring project with qmake..."
"$QT_PATH/bin/qmake" ../2x2coin-wallet.pro \
    -spec android-clang \
    CONFIG+=release \
    ANDROID_ABIS=arm64-v8a \
    OPENSSL_ANDROID="$OPENSSL_ANDROID" \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" >> "../$LOG_FILE" 2>&1 || log_error "qmake configuration failed."

# 6. Compile C++
log_info "Compiling native code (C++)..."
make -j$(nproc) >> "../$LOG_FILE" 2>&1 || log_error "C++ compilation failed."

# ==============================================================================
# 7. Prepare Structure for androiddeployqt (CORRIGIDO: Injeção forçada do binário)
# ==============================================================================
log_info "Preparing folder structure and injecting native binary..."

# Cria explicitamente a árvore esperada pela ferramenta de deployment
mkdir -p android-build/libs/arm64-v8a

# Localiza dinamicamente o .so gerado pelo Makefile do C++
SO_ORIGINAL=$(find . -maxdepth 3 -name "lib2x2coin-wallet*.so" | grep -v "android-build" | head -n 1)

if [ -n "$SO_ORIGINAL" ] && [ -f "$SO_ORIGINAL" ]; then
    log_info "Native binary located at: $SO_ORIGINAL"
    # Copia e renomeia para o formato estrito exigido pelo arquivo .json do Qt
    cp "$SO_ORIGINAL" android-build/libs/arm64-v8a/lib2x2coin-wallet_arm64-v8a.so
    log_success "Binary successfully positioned for androiddeployqt."
else
    log_error "Native binary (lib2x2coin-wallet.so) was not generated by 'make'. Check build.log for compilation errors."
fi

# ==============================================================================
# 8. Generate APK using androiddeployqt
# ==============================================================================
log_info "Starting APK generation (androiddeployqt)..."
ANDROID_DEPLOY_QT="$QT_PATH/bin/androiddeployqt"
if
