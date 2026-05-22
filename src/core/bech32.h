#ifndef BECH32_H
#define BECH32_H

#include <stdint.h>
#include <string>
#include <vector>

namespace bech32
{
std::string Encode(const std::string& hrp, const std::vector<uint8_t>& values);
std::pair<std::string, std::vector<uint8_t>> Decode(const std::string& str);
}

#endif
