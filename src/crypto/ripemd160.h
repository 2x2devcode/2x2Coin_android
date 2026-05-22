#ifndef RIPEMD160_H
#define RIPEMD160_H

#include <stdint.h>
#include <stdlib.h>
#include <openssl/ripemd.h>

class CRIPEMD160 {
private:
    RIPEMD160_CTX ctx;
public:
    static const size_t OUTPUT_SIZE = 20;
    CRIPEMD160() { RIPEMD160_Init(&ctx); }
    CRIPEMD160& Write(const unsigned char* data, size_t len) { RIPEMD160_Update(&ctx, data, len); return *this; }
    void Finalize(unsigned char hash[OUTPUT_SIZE]) { RIPEMD160_Final(hash, &ctx); }
};

#endif
