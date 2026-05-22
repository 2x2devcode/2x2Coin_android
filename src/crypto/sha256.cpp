#include "sha256.h"
#include "sha512.h"
#include "ripemd160.h"
#include "hmac_sha256.h"
#include "hmac_sha512.h"
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <openssl/pkcs5.h>

namespace Coin2x2 {
namespace Crypto {

QByteArray sha256(const QByteArray& data) {
    unsigned char hash[32];
    CSHA256().Write((const unsigned char*)data.data(), data.size()).Finalize(hash);
    return QByteArray((const char*)hash, 32);
}

QByteArray hash256(const QByteArray& data) {
    return sha256(sha256(data));
}

QByteArray ripemd160(const QByteArray& data) {
    unsigned char hash[20];
    CRIPEMD160().Write((const unsigned char*)data.data(), data.size()).Finalize(hash);
    return QByteArray((const char*)hash, 20);
}

QByteArray hash160(const QByteArray& data) {
    return ripemd160(sha256(data));
}

QByteArray sha512(const QByteArray& data) {
    unsigned char hash[64];
    CSHA512().Write((const unsigned char*)data.data(), data.size()).Finalize(hash);
    return QByteArray((const char*)hash, 64);
}

QByteArray hmacSha256(const QByteArray& key, const QByteArray& data) {
    unsigned char hash[32];
    CHMAC_SHA256((const unsigned char*)key.data(), key.size())
        .Write((const unsigned char*)data.data(), data.size())
        .Finalize(hash);
    return QByteArray((const char*)hash, 32);
}

QByteArray hmacSha512(const QByteArray& key, const QByteArray& data) {
    unsigned char hash[64];
    CHMAC_SHA512((const unsigned char*)key.data(), key.size())
        .Write((const unsigned char*)data.data(), data.size())
        .Finalize(hash);
    return QByteArray((const char*)hash, 64);
}

QByteArray pbkdf2HmacSha512(const QByteArray& password, const QByteArray& salt, int iterations, int keyLength) {
    QByteArray result(keyLength, 0);
    PKCS5_PBKDF2_HMAC((const char*)password.data(), password.size(),
                      (const unsigned char*)salt.data(), salt.size(),
                      iterations, EVP_sha512(), keyLength, (unsigned char*)result.data());
    return result;
}

} // namespace Crypto
} // namespace Coin2x2
