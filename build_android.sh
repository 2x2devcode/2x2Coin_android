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

# 3. Ensure OpenSSL for Android
if [ ! -d "$OPENSSL_ANDROID" ]; then
    log_info "Downloading OpenSSL for Android..."
    git clone https://github.com/KDAB/android_openssl.git "$OPENSSL_ANDROID" >> "$LOG_FILE" 2>&1
fi

# 4. Configure Build Directory
BUILD_DIR="build-android-arm64-release"
log_info "Cleaning previous build directory..."
rm -rf "$BUILD_DIR" >> "$LOG_FILE" 2>&1
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DIR/android-build/src/main"
cp android/AndroidManifest.xml $BUILD_DIR/android-build/src/main/
cd "$BUILD_DIR"

# 5. Run qmake
log_info "Configuring project with qmake..."
"$QT_PATH/bin/qmake" ../2x2coin-wallet.pro \
    -spec android-clang \
    CONFIG+=release \
    ANDROID_ABIS=arm64-v8a \
    ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" \
    ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT" >> "../$LOG_FILE" 2>&1 || log_error "qmake configuration failed."

# 6. Compile C++
log_info "Compiling native code (C++)..."
make -j$(nproc) >> "../$LOG_FILE" 2>&1 || log_error "C++ compilation failed."

# 7. Prepare Structure for androiddeployqt
log_info "Preparing folder structure for APK..."
mkdir -p android-build/libs/arm64-v8a
SO_FILE=$(find . -name "lib2x2coin-wallet_arm64-v8a.so" | head -n 1)
if [ -n "$SO_FILE" ]; then
    cp "$SO_FILE" android-build/libs/arm64-v8a/lib2x2coin-wallet_arm64-v8a.so
else
    log_error "Native binary (.so) not found!"
fi

# 8. Generate APK using androiddeployqt
log_info "Starting APK generation (androiddeployqt)..."
ANDROID_DEPLOY_QT="$QT_PATH/bin/androiddeployqt"
if [ ! -f "$ANDROID_DEPLOY_QT" ]; then
    ANDROID_DEPLOY_QT="$(dirname $QT_PATH)/gcc_64/bin/androiddeployqt"
fi

DEPLOY_JSON="android-2x2coin-wallet-deployment-settings.json"
log_info "Executing androiddeployqt..."
"$ANDROID_DEPLOY_QT" \
    --input "$DEPLOY_JSON" \
    --output android-build \
    --android-platform android-34 \
    --jdk "$JAVA_HOME" \
    --gradle \
    --release >> "../$LOG_FILE" 2>&1 || log_error "Failed to generate APK with androiddeployqt."

log_success "Build completed successfully!"

# Locate Generated APK
APK_PATH=$(find android-build -name "*.apk" | grep release | head -n 1)
if [ -n "$APK_PATH" ]; then
    cp "$APK_PATH" ../2x2coin-wallet-release.apk
    cp "$APK_PATH" ../$BUILD_DIR/2x2coin-wallet-release.apk
    log_info "APK copied to root: 2x2coin-wallet-release.apk"
else
    log_error "APK generated but not located!"
fi

# ==============================================================================
# ETAPA DE ASSINATURA E ALINHAMENTO DO APK (COM CHECAGEM DE DEPENDÊNCIAS)
# ==============================================================================

echo "[INFO] Verificando dependências de pós-compilação..."

# Função para verificar e instalar pacotes ausentes
verificar_e_instalar() {
    local comando=$1
    local pacote=$2

    if ! command -v "$comando" &> /dev/null; then
        echo "[AVISO] A ferramenta '$comando' não foi encontrada."
        echo "[INFO] Tentando instalar o pacote '$pacote' via apt..."
        
        # Atualiza a lista de pacotes caso necessário e instala
        sudo apt-get update -y && sudo apt-get install -y "$pacote"
        
        # Segunda validação após a tentativa de instalação
        if ! command -v "$comando" &> /dev/null; then
            echo "[ERRO] Não foi possível instalar '$pacote'. Instale-o manualmente."
            exit 1
        fi
        echo "[SUCESSO] '$comando' instalado com sucesso!"
    fi
}

# Executa a checagem para cada uma das ferramentas necessárias
verificar_e_instalar "keytool" "default-jdk-headless"
verificar_e_instalar "zipalign" "zipalign"
verificar_e_instalar "apksigner" "apksigner"

echo "[INFO] Todas as dependências de assinatura estão prontas."
echo "[INFO] Iniciando processo de pós-compilação..."

# Configuração de Variáveis (Ajustadas para consistência)
TARGET_NAME="2x2coin-wallet"
APK_BRUTO="${TARGET_NAME}-release.apk"
APK_FINAL="${TARGET_NAME}.apk"
KEYSTORE_NAME="debug.keystore"
APK_RELEASE_DIR="$BUILD_DIR"

# Verificar se a variável BUILD_DIR foi definida e se a pasta existe
if [ -z "$APK_RELEASE_DIR" ]; then
    echo "[ERRO] A variável \$BUILD_DIR está vazia. Certifique-se de defini-la no início do script."
    exit 1
fi

# 1. Localizar o APK bruto gerado
# Tenta primeiro o padrão definido, caso não ache, busca dinamicamente por arquivos -unsigned ou -release
if [ ! -f "$APK_BRUTO" ]; then
    APK_BRUTO=$(ls *-unsigned.apk 2>/dev/null | head -n 1)
    if [ -z "$APK_BRUTO" ]; then
        APK_BRUTO=$(ls *release.apk 2>/dev/null | head -n 1)
    fi
fi

if [ -z "$APK_BRUTO" ] || [ ! -f "$APK_BRUTO" ]; then
    echo "[ERRO] APK bruto para alinhar não foi encontrado na pasta atual!"
    exit 1
fi

# 2. Gerar a Keystore de teste se ela ainda não existir na raiz atual
if [ ! -f "$KEYSTORE_NAME" ]; then
    echo "[INFO] Criando chave de assinatura temporária ($KEYSTORE_NAME)..."
    keytool -genkey -v \
      -keystore "$KEYSTORE_NAME" \
      -storepass android \
      -alias androiddebugkey \
      -keypass android \
      -keyalg RSA \
      -keysize 2048 \
      -validity 10000 \
      -dname "CN=Android Debug,O=Android,C=US"
fi

echo "[INFO] Aplicando zipalign no arquivo: $APK_BRUTO"

# 3. Remove o APK final antigo local se existir para não dar erro no zipalign
rm -f "$APK_FINAL"

# 4. Executa o Alinhamento (Gera o arquivo final otimizado)
zipalign -v 4 "$APK_BRUTO" "$APK_FINAL"

if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao executar o zipalign."
    exit 1
fi

echo "[INFO] Assinando o APK final com apksigner..."

# 5. Assina o APK já alinhado (Crucial para o Android 15)
apksigner sign --ks "$KEYSTORE_NAME" --ks-pass pass:android "$APK_FINAL"

if [ $? -ne 0 ]; then
    echo "[ERRO] Falha ao assinar o APK com o apksigner."
    exit 1
fi

# ==============================================================================
# ETAPA DE COPIA DO ARQUIVO PARA A PASTA DE DESTINO ($BUILD_DIR)
# ==============================================================================
echo "[INFO] Copiando o arquivo assinado para a pasta de destino..."

cp "$APK_FINAL" "$BUILD_DIR/${APK_FINAL}"

if [ $? -eq 0 ]; then
    echo "=========================================================================="
    echo "[SUCESSO] Processo concluído! O aplicativo foi alinhado, assinado e movido."
    echo "[LOCAL ORIGINAL] $(pwd)/${APK_FINAL}"
    echo "[CÓPIA DESTINO]  "$BUILD_DIR/${APK_FINAL}"
    echo "=========================================================================="
else
    echo "[ERRO] Falha ao copiar o arquivo final para a pasta $BUILD_DIR"
    exit 1
fi
