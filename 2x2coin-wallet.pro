######################################################################
# 2X2Coin Android Qt Wallet
######################################################################

QT += core gui qml quick quickcontrols2 network svg
android: lessThan(QT_MAJOR_VERSION, 6): QT += androidextras

# O nome do TARGET deve ser simples para evitar problemas no Android
TARGET = 2x2coin-wallet
TEMPLATE = app
CONFIG += c++17 qtquickcompiler

# Versão do aplicativo
VERSION = 2.0.2
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

    ANDROID_EXTRA_LIBS += /root/openssl-android1/no-asm/ssl_3/arm64-v8a/libcrypto.so \
                      /root/openssl-android1/no-asm/ssl_3/arm64-v8a/libssl.so

# Arquivos fonte C++
SOURCES += \
    src/main.cpp \
    src/core/chainparams.cpp \
    src/core/uint256.cpp \
    src/core/base58.cpp \
    src/core/bech32.cpp \
    src/crypto/sha256.cpp \
    src/crypto/hmac_sha256.cpp \
    src/crypto/hmac_sha512.cpp \
    src/crypto/secp256k1_wrapper.cpp \
    src/wallet/walletmanager.cpp \
    src/wallet/hdwallet.cpp \
    src/network/networkmanager.cpp \
    src/ui/applicationcontroller.cpp \
    src/utils/settings.cpp

# Arquivos de cabeçalho
HEADERS += \
    src/core/chainparams.h \
    src/core/uint256.h \
    src/core/base58.h \
    src/core/bech32.h \
    src/crypto/sha256.h \
    src/crypto/sha512.h \
    src/crypto/ripemd160.h \
    src/crypto/hmac_sha256.h \
    src/crypto/hmac_sha512.h \
    src/crypto/secp256k1_wrapper.h \
    src/wallet/walletmanager.h \
    src/wallet/hdwallet.h \
    src/network/networkmanager.h \
    src/ui/applicationcontroller.h \
    src/utils/settings.h

# Recursos
RESOURCES += \
    qml/qml.qrc \
    assets/assets.qrc

# Configurações Android
android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    ANDROID_MIN_SDK_VERSION = 23
    ANDROID_TARGET_SDK_VERSION = 34

    # Caminho do OpenSSL (KDAB Structure)
    OPENSSL_ROOT = $$(OPENSSL_ANDROID)
    isEmpty(OPENSSL_ROOT): OPENSSL_ROOT = /root/openssl-android

    OPENSSL_ARCH_PATH = $$OPENSSL_ROOT/arm64-v8a
    
    INCLUDEPATH += $$OPENSSL_ARCH_PATH/include
    DEPENDPATH += $$OPENSSL_ARCH_PATH/include
    
    LIBS += -L$$OPENSSL_ARCH_PATH -lssl -lcrypto

    
    # Forçar inclusão para o compilador
    QMAKE_CXXFLAGS += -I$$OPENSSL_ARCH_PATH/include
} else {
    LIBS += -lssl -lcrypto
}

INCLUDEPATH += src src/core src/crypto src/wallet src/network src/ui src/utils
