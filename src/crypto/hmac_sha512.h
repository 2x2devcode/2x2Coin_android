#ifndef HMAC_SHA512_H
#define HMAC_SHA512_H

#include "sha512.h"

class CHMAC_SHA512 {
private:
    CSHA512 outer, inner;
public:
    static const size_t OUTPUT_SIZE = 64;
    CHMAC_SHA512(const unsigned char* key, size_t keylen);
    CHMAC_SHA512& Write(const unsigned char* data, size_t len) { inner.Write(data, len); return *this; }
    void Finalize(unsigned char hash[OUTPUT_SIZE]);
};

#endif
