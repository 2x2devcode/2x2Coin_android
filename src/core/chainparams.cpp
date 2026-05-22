// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação dos parâmetros da cadeia 2X2Coin
// Baseado em: https://github.com/coinsdevcode/2x2Coin/src/chainparams.cpp

#include "chainparams.h"
#include <stdexcept>

namespace Coin2x2 {

// Seeds DNS da rede principal
const QStringList MainNetParams::DNS_SEEDS = {
    "seed.2x2coin.com",
    "seed1.2x2coin.com",
    "seed2.2x2coin.com",
    "161.97.176.125",
    "77.237.232.84",
    "75.119.137.26",
    "149.102.139.53",
    "144.91.107.244",
    "38.242.236.173"
};

// ============================================================
// Cálculo de recompensa por bloco do 2X2Coin
// Baseado na lógica de main.cpp do repositório original
// Schedule de emissão conforme README.md
// ============================================================
int64_t MainNetParams::getBlockReward(uint32_t nHeight) {
    const int64_t COIN = 100000000LL;

    // Blocos por ano: 262800 (2 min/bloco * 60 * 24 * 365 / 2)
    const uint32_t BLOCKS_PER_YEAR = 262800;

    // Ano 1: 100 moedas por bloco
    if (nHeight <= BLOCKS_PER_YEAR) {
        return 100 * COIN;
    }
    // Ano 2: 200 moedas por bloco
    else if (nHeight <= 2 * BLOCKS_PER_YEAR) {
        return 200 * COIN;
    }
    // Ano 3: 550 moedas por bloco
    else if (nHeight <= 3 * BLOCKS_PER_YEAR) {
        return 550 * COIN;
    }
    // Ano 4: 1300 moedas por bloco
    else if (nHeight <= 4 * BLOCKS_PER_YEAR) {
        return 1300 * COIN;
    }
    // Ano 5: 3250 moedas por bloco
    else if (nHeight <= 5 * BLOCKS_PER_YEAR) {
        return 3250 * COIN;
    }
    // Ano 6: 3500 moedas por bloco
    else if (nHeight <= 6 * BLOCKS_PER_YEAR) {
        return 3500 * COIN;
    }
    // Ano 7: 4500 moedas por bloco
    else if (nHeight <= 7 * BLOCKS_PER_YEAR) {
        return 4500 * COIN;
    }
    // Ano 8: 5600 moedas por bloco
    else if (nHeight <= 8 * BLOCKS_PER_YEAR) {
        return 5600 * COIN;
    }
    // Ano 9: 7000 moedas por bloco
    else if (nHeight <= 9 * BLOCKS_PER_YEAR) {
        return 7000 * COIN;
    }
    // Ano 10: 8800 moedas por bloco
    else if (nHeight <= 10 * BLOCKS_PER_YEAR) {
        return 8800 * COIN;
    }
    // Ano 11: 8800 moedas por bloco
    else if (nHeight <= 11 * BLOCKS_PER_YEAR) {
        return 8800 * COIN;
    }
    // Ano 12: 7000 moedas por bloco
    else if (nHeight <= 12 * BLOCKS_PER_YEAR) {
        return 7000 * COIN;
    }
    // Ano 13: 11000 moedas por bloco
    else if (nHeight <= 13 * BLOCKS_PER_YEAR) {
        return 11000 * COIN;
    }
    // Ano 14: 14080 moedas por bloco
    else if (nHeight <= 14 * BLOCKS_PER_YEAR) {
        return 14080 * COIN;
    }
    // Ano 15: 18000 moedas por bloco
    else if (nHeight <= 15 * BLOCKS_PER_YEAR) {
        return 18000 * COIN;
    }
    // Ano 16: 55000 moedas por bloco
    else if (nHeight <= 16 * BLOCKS_PER_YEAR) {
        return 55000 * COIN;
    }
    // Ano 20+: Tail emission de 1000 moedas por bloco
    else {
        return 1000 * COIN;
    }
}

// ============================================================
// ChainParams - Implementação
// ============================================================
ChainParams& ChainParams::instance() {
    static ChainParams params;
    return params;
}

ChainParams::ChainParams() : m_network(MAIN) {}

void ChainParams::setNetwork(Network net) {
    m_network = net;
}

uint16_t ChainParams::defaultPort() const {
    switch (m_network) {
        case MAIN:    return MainNetParams::DEFAULT_PORT;
        case TESTNET: return TestNetParams::DEFAULT_PORT;
        default:      return 18444;
    }
}

uint8_t ChainParams::pubkeyAddressPrefix() const {
    switch (m_network) {
        case MAIN:    return MainNetParams::PUBKEY_ADDRESS_PREFIX;
        case TESTNET: return TestNetParams::PUBKEY_ADDRESS_PREFIX;
        default:      return 111;
    }
}

uint8_t ChainParams::scriptAddressPrefix() const {
    switch (m_network) {
        case MAIN:    return MainNetParams::SCRIPT_ADDRESS_PREFIX;
        case TESTNET: return TestNetParams::SCRIPT_ADDRESS_PREFIX;
        default:      return 196;
    }
}

uint8_t ChainParams::secretKeyPrefix() const {
    switch (m_network) {
        case MAIN:    return MainNetParams::SECRET_KEY_PREFIX;
        case TESTNET: return TestNetParams::SECRET_KEY_PREFIX;
        default:      return 239;
    }
}

QByteArray ChainParams::extPublicKeyPrefix() const {
    if (m_network == MAIN) {
        return QByteArray("\x04\x88\xB2\x1E", 4);
    }
    return QByteArray("\x04\x35\x87\xCF", 4);
}

QByteArray ChainParams::extSecretKeyPrefix() const {
    if (m_network == MAIN) {
        return QByteArray("\x04\x88\xAD\xE4", 4);
    }
    return QByteArray("\x04\x35\x83\x94", 4);
}

QString ChainParams::cashaddrPrefix() const {
    if (m_network == MAIN) {
        return QString("2x2coin");
    }
    return QString("2x2test");
}

QString ChainParams::networkId() const {
    switch (m_network) {
        case MAIN:    return "main";
        case TESTNET: return "test";
        default:      return "regtest";
    }
}

QStringList ChainParams::dnsSeeds() const {
    if (m_network == MAIN) {
        return MainNetParams::DNS_SEEDS;
    }
    return QStringList();
}

uint32_t ChainParams::lastPowBlock() const {
    if (m_network == TESTNET) return TestNetParams::LAST_POW_BLOCK;
    return MainNetParams::LAST_POW_BLOCK;
}

uint32_t ChainParams::targetSpacing() const {
    return MainNetParams::TARGET_SPACING;
}

uint32_t ChainParams::coinbaseMaturity() const {
    if (m_network == TESTNET) return TestNetParams::COINBASE_MATURITY;
    return MainNetParams::COINBASE_MATURITY;
}

uint32_t ChainParams::stakeMinAge() const {
    return MainNetParams::STAKE_MIN_AGE;
}

int64_t ChainParams::getBlockReward(uint32_t nHeight) const {
    return MainNetParams::getBlockReward(nHeight);
}

} // namespace Coin2x2
