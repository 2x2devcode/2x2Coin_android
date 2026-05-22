#ifndef SHA512_H
#define SHA512_H

#include <stdint.h>
#include <stdlib.h>
#include <openssl/sha.h>

class CSHA512 {
private:
    SHA512_CTX ctx;
public:
    static const size_t OUTPUT_SIZE = 64;
    CSHA512() { SHA512_Init(&ctx); }
    CSHA512& Write(const unsigned char* data, size_t len) { SHA512_Update(&ctx, data, len); return *this; }
    void Finalize(unsigned char hash[OUTPUT_SIZE]) { SHA512_Final(hash, &ctx); }
};

#endif
