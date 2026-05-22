#ifndef SHA256_H
#define SHA256_H

#include <stdint.h>
#include <stdlib.h>
#include <openssl/sha.h>
#include <QByteArray>

namespace Coin2x2 {
namespace Crypto {

class CSHA256 {
private:
    SHA256_CTX ctx;
public:
    static const size_t OUTPUT_SIZE = 32;
    CSHA256() { SHA256_Init(&ctx); }
    CSHA256& Write(const unsigned char* data, size_t len) { SHA256_Update(&ctx, data, len); return *this; }
    void Finalize(unsigned char hash[OUTPUT_SIZE]) { SHA256_Final(hash, &ctx); }
};

// Funções utilitárias QByteArray
QByteArray sha256(const QByteArray& data);
QByteArray hash256(const QByteArray& data);
QByteArray ripemd160(const QByteArray& data);
QByteArray hash160(const QByteArray& data);
QByteArray sha512(const QByteArray& data);
QByteArray hmacSha256(const QByteArray& key, const QByteArray& data);
QByteArray hmacSha512(const QByteArray& key, const QByteArray& data);
QByteArray pbkdf2HmacSha512(const QByteArray& password, const QByteArray& salt, int iterations = 2048, int keyLength = 64);

} // namespace Crypto
} // namespace Coin2x2

#endif
