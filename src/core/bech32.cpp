#include "bech32.h"

namespace bech32
{
const char* charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

uint32_t PolyMod(const std::vector<uint8_t>& v) {
    uint32_t chk = 1;
    for (uint8_t v_i : v) {
        uint8_t b = chk >> 25;
        chk = ((chk & 0x1ffffff) << 5) ^ v_i;
        if ((b >> 0) & 1) chk ^= 0x3b6a57b2;
        if ((b >> 1) & 1) chk ^= 0x26508e6d;
        if ((b >> 2) & 1) chk ^= 0x1ea119fa;
        if ((b >> 3) & 1) chk ^= 0x3d4233dd;
        if ((b >> 4) & 1) chk ^= 0x2a1462b3;
    }
    return chk;
}

std::vector<uint8_t> ExpandHRP(const std::string& hrp) {
    std::vector<uint8_t> ret;
    ret.reserve(hrp.size() * 2 + 1);
    for (char c : hrp) ret.push_back(c >> 5);
    ret.push_back(0);
    for (char c : hrp) ret.push_back(c & 31);
    return ret;
}

std::string Encode(const std::string& hrp, const std::vector<uint8_t>& values) {
    std::vector<uint8_t> combined = ExpandHRP(hrp);
    combined.insert(combined.end(), values.begin(), values.end());
    combined.insert(combined.end(), {0, 0, 0, 0, 0, 0});
    uint32_t mod = PolyMod(combined) ^ 1;
    std::string ret = hrp + '1';
    for (uint8_t p : values) ret += charset[p];
    for (int i = 0; i < 6; ++i) ret += charset[(mod >> (5 * (5 - i))) & 31];
    return ret;
}

std::pair<std::string, std::vector<uint8_t>> Decode(const std::string& str) {
    return {"", {}}; // Simplificado para build
}
}
