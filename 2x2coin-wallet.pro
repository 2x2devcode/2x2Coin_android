######################################################################
# 2X2Coin Android Qt Wallet — Qt 6 + arm64-v8a + OpenSSL
######################################################################

TEMPLATE = app
TARGET = 2x2coin-wallet

QT += core gui quick quickcontrols2

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
    CONFIG += android_install
    QMAKE_CXXFLAGS += -Wno-deprecated-declarations
    DEFINES += OPENSSL_SUPPRESS_DEPRECATED
    
  # SDK — use 34 para Android 15; sobrescreva com ANDROID_TARGET_SDK=34 no ambiente
    ANDROID_MIN_SDK_VERSION = 23
    isEmpty(ANDROID_TARGET_SDK) {
        ANDROID_TARGET_SDK_VERSION = 34
    } else {
        ANDROID_TARGET_SDK_VERSION = $$ANDROID_TARGET_SDK
    }
    ANDROID_ABIS = arm64-v8a
    
  # Raiz: env OPENSSL_ANDROID, variável qmake, ou pastas padrão
    OPENSSL_ROOT = $$(OPENSSL_ANDROID)
    isEmpty(OPENSSL_ROOT): OPENSSL_ROOT = $$OPENSSL_ANDROID
    isEmpty(OPENSSL_ROOT): OPENSSL_ROOT = $$(HOME)/openssl-android
    isEmpty(OPENSSL_ROOT): OPENSSL_ROOT = $$PWD/third_party/android_openssl

    ANDROID_ABI = arm64-v8a
    OPENSSL_ARCH_PATH =
    OPENSSL_CRYPTO_SO =
    OPENSSL_SSL_SO =
    OPENSSL_CRYPTO_LIB =
    OPENSSL_SSL_LIB =

    # 1) KDAB / Qt 6.5+ — ssl_3/arm64-v8a/libcrypto_3.so
    kdab_ssl3 = $$OPENSSL_ROOT/ssl_3/$$ANDROID_ABI
    exists($$kdab_ssl3/libcrypto_3.so) {
        OPENSSL_ARCH_PATH = $$kdab_ssl3
        OPENSSL_CRYPTO_SO = $$OPENSSL_ARCH_PATH/libcrypto_3.so
        OPENSSL_SSL_SO = $$OPENSSL_ARCH_PATH/libssl_3.so
        OPENSSL_CRYPTO_LIB = $$OPENSSL_ARCH_PATH/libcrypto.a
        OPENSSL_SSL_LIB = $$OPENSSL_ARCH_PATH/libssl.a
    }

  # 2) KDAB legado — ssl_1.1/...
    isEmpty(OPENSSL_ARCH_PATH) {
        kdab_ssl11 = $$OPENSSL_ROOT/ssl_1.1/$$ANDROID_ABI
        exists($$kdab_ssl11/libcrypto_1_1.so) {
            OPENSSL_ARCH_PATH = $$kdab_ssl11
            OPENSSL_CRYPTO_SO = $$OPENSSL_ARCH_PATH/libcrypto_1_1.so
            OPENSSL_SSL_SO = $$OPENSSL_ARCH_PATH/libssl_1_1.so
            OPENSSL_CRYPTO_LIB = $$OPENSSL_ARCH_PATH/libcrypto.a
            OPENSSL_SSL_LIB = $$OPENSSL_ARCH_PATH/libssl.a
        }
    }

    # 3) Layout manual: $ROOT/arm64-v8a/libcrypto.so
    isEmpty(OPENSSL_ARCH_PATH) {
        manual = $$OPENSSL_ROOT/$$ANDROID_ABI
        exists($$manual/libcrypto.so) {
            OPENSSL_ARCH_PATH = $$manual
            OPENSSL_CRYPTO_SO = $$OPENSSL_ARCH_PATH/libcrypto.so
            OPENSSL_SSL_SO = $$OPENSSL_ARCH_PATH/libssl.so
            OPENSSL_CRYPTO_LIB = $$OPENSSL_ARCH_PATH/libcrypto.a
            OPENSSL_SSL_LIB = $$OPENSSL_ARCH_PATH/libssl.a
            isEmpty(OPENSSL_CRYPTO_LIB): OPENSSL_CRYPTO_LIB = -lcrypto
            isEmpty(OPENSSL_SSL_LIB): OPENSSL_SSL_LIB = -lssl
        }
    }

    !isEmpty(OPENSSL_ARCH_PATH) {
        message("OpenSSL root: $$OPENSSL_ROOT")
        message("OpenSSL arch: $$OPENSSL_ARCH_PATH")

        DEFINES += HAVE_OPENSSL
        ANDROID_EXTRA_LIBS += $$OPENSSL_CRYPTO_SO $$OPENSSL_SSL_SO
        
        # KDAB: headers em ssl_3/include (arm64-v8a/include e symlink — pode falhar apos git clone)
        OPENSSL_INCLUDE =
        exists($$OPENSSL_ROOT/ssl_3/include/openssl/evp.h) {
            OPENSSL_INCLUDE = $$OPENSSL_ROOT/ssl_3/include
        }
        isEmpty(OPENSSL_INCLUDE) {
            exists($$OPENSSL_ROOT/ssl_1.1/include/openssl/evp.h) {
                OPENSSL_INCLUDE = $$OPENSSL_ROOT/ssl_1.1/include
            }
        }
        isEmpty(OPENSSL_INCLUDE) {
            OPENSSL_INCLUDE = $$OPENSSL_ARCH_PATH/include
        }
        message("OpenSSL include: $$OPENSSL_INCLUDE")
        INCLUDEPATH += $$OPENSSL_ARCH_PATH/include
        DEPENDPATH += $$OPENSSL_ARCH_PATH/include
        QMAKE_CXXFLAGS += -I$$OPENSSL_ARCH_PATH/include

        exists($$OPENSSL_ARCH_PATH/libcrypto.a) {
            LIBS += $$OPENSSL_ARCH_PATH/libcrypto.a $$OPENSSL_ARCH_PATH/libssl.a
        } else {
            LIBS += -L$$OPENSSL_ARCH_PATH -lcrypto -lssl
        }
    } else {
        error("OpenSSL Android nao encontrado. OPENSSL_ROOT=$$OPENSSL_ROOT \
Clone: git clone https://github.com/KDAB/android_openssl.git $$HOME/openssl-android \
Depois: export OPENSSL_ANDROID=$$HOME/openssl-android \
Esperado: $$OPENSSL_ROOT/ssl_3/arm64-v8a/libcrypto_3.so")
    }
} else {
    DEFINES += HAVE_OPENSSL
    LIBS += -lssl -lcrypto
}
