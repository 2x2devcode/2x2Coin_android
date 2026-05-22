#ifndef HMAC_SHA256_H
#define HMAC_SHA256_H

#include "sha256.h"

class CHMAC_SHA256 {
private:
    Coin2x2::Crypto::CSHA256 outer, inner;
public:
    static const size_t OUTPUT_SIZE = 32;
    CHMAC_SHA256(const unsigned char* key, size_t keylen);
    CHMAC_SHA256& Write(const unsigned char* data, size_t len) { inner.Write(data, len); return *this; }
    void Finalize(unsigned char hash[OUTPUT_SIZE]);
};

#endif
