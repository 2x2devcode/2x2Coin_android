######################################################################
# 2X2Coin Android Qt Wallet — Qt 6 + arm64-v8a + OpenSSL
# Core: https://github.com/coinsdevcode/2x2Coin
# UI:   https://github.com/2x2devcode/2x2Coin_android
######################################################################

QT += core gui qml quick quickcontrols2 network svg

TARGET = 2x2coin-wallet
TEMPLATE = app
CONFIG += c++17 qtquickcompiler

VERSION = 2.0.2
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

# -------------------------------------------------------------------
# Fontes C++
# -------------------------------------------------------------------
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
    src/ui/walletcontroller.cpp \
    src/utils/settings.cpp

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
    src/ui/walletcontroller.h \
    src/utils/settings.h \
    src/utils/secure_buffer.h
    
RESOURCES += \
    qml/qml.qrc \
    assets/assets.qrc

INCLUDEPATH += \
    $$PWD/src \
    $$PWD/src/core \
    $$PWD/src/crypto \
    $$PWD/src/wallet \
    $$PWD/src/network \
    $$PWD/src/ui \
    $$PWD/src/utils

# -------------------------------------------------------------------
# Android (Ubuntu 22.04: export OPENSSL_ANDROID=$HOME/openssl-android)
# -------------------------------------------------------------------
android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    
  # SDK — use 35 para Android 15; sobrescreva com ANDROID_TARGET_SDK=35 no ambiente
    ANDROID_MIN_SDK_VERSION = 23
    isEmpty(ANDROID_TARGET_SDK) {
        ANDROID_TARGET_SDK_VERSION = 35
    } else {
        ANDROID_TARGET_SDK_VERSION = $$ANDROID_TARGET_SDK
    }

    ANDROID_ABIS = arm64-v8a
    
  # OpenSSL pré-compilado para NDK (KDAB android_openssl ou build manual)
    OPENSSL_ROOT = $$(OPENSSL_ANDROID)
    isEmpty(OPENSSL_ROOT): OPENSSL_ROOT = $$(HOME)/openssl-android

  # Suporta layout KDAB: $OPENSSL_ANDROID/arm64-v8a/{lib,include}
    ANDROID_ABI = arm64-v8a
    OPENSSL_ARCH_PATH = $$OPENSSL_ROOT/$$ANDROID_ABI

    !exists($$OPENSSL_ARCH_PATH/libcrypto.so) {
        OPENSSL_ARCH_PATH = $$OPENSSL_ROOT/ssl_$$ANDROID_ABI
    }

    exists($$OPENSSL_ARCH_PATH/libcrypto.so) {
        message("OpenSSL Android: $$OPENSSL_ARCH_PATH")
        DEFINES += HAVE_OPENSSL

         ANDROID_EXTRA_LIBS += \
            $$OPENSSL_ARCH_PATH/libcrypto.so \
            $$OPENSSL_ARCH_PATH/libssl.so

        INCLUDEPATH += $$OPENSSL_ARCH_PATH/include
        DEPENDPATH += $$OPENSSL_ARCH_PATH/include
        LIBS += -L$$OPENSSL_ARCH_PATH -lssl -lcrypto
        QMAKE_CXXFLAGS += -I$$OPENSSL_ARCH_PATH/include
    } else {
        error("OpenSSL para Android nao encontrado em $$OPENSSL_ARCH_PATH. \
Defina OPENSSL_ANDROID (ex.: export OPENSSL_ANDROID=$$HOME/openssl-android) \
e garanta libcrypto.so e libssl.so em arm64-v8a/.")
    }

  # Evita crash na inicializacao por .so ausente no APK
    android:contains(ANDROID_EXTRA_LIBS, libcrypto.so) {
        message("ANDROID_EXTRA_LIBS: $$ANDROID_EXTRA_LIBS")
    }
} else {
    DEFINES += HAVE_OPENSSL
    LIBS += -lssl -lcrypto
}
