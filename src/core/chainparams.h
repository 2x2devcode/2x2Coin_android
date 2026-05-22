// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-2015 The Bitcoin Core developers
// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Parâmetros da cadeia de blocos do 2X2Coin
// Baseado em: https://github.com/coinsdevcode/2x2Coin

#pragma once

#include <QString>
#include <QList>
#include <QByteArray>
#include <cstdint>

namespace Coin2x2 {

// ============================================================
// Parâmetros da rede principal (Mainnet)
// ============================================================
struct MainNetParams {
    // Identificação da rede
    static constexpr const char* NETWORK_ID = "main";
    static constexpr const char* CASHADDR_PREFIX = "2x2coin";

    // Porta padrão P2P
    static constexpr uint16_t DEFAULT_PORT = 15190;

    // Prefixos Base58
    static constexpr uint8_t PUBKEY_ADDRESS_PREFIX = 3;   // Endereços começam com '2'
    static constexpr uint8_t SCRIPT_ADDRESS_PREFIX = 90;
    static constexpr uint8_t SECRET_KEY_PREFIX = 128;

    // Prefixos BIP32 (xpub/xprv)
    static constexpr uint8_t EXT_PUBLIC_KEY[4]  = {0x04, 0x88, 0xB2, 0x1E};
    static constexpr uint8_t EXT_SECRET_KEY[4]  = {0x04, 0x88, 0xAD, 0xE4};

    // Parâmetros de consenso
    static constexpr uint32_t LAST_POW_BLOCK = 110000;
    static constexpr uint32_t TARGET_SPACING = 120;       // 2 minutos em segundos
    static constexpr uint32_t TARGET_TIMESPAN = 3600;     // 1 hora
    static constexpr uint32_t COINBASE_MATURITY = 24;
    static constexpr uint32_t STAKE_MIN_AGE = 86400;      // 24 horas
    static constexpr uint32_t STAKE_TIMESTAMP_MASK = 0xf;

    // Bloco gênesis
    static constexpr uint32_t GENESIS_TIME = 1769817600;
    static constexpr uint32_t GENESIS_NONCE = 184621;
    static constexpr uint32_t GENESIS_BITS = 0x1e0fffff;
    static constexpr const char* GENESIS_HASH =
        "00000eea834a06692bc4f56d6f0061631c72fd75431ce9e5d7f3b9d712dc3a9b";
    static constexpr const char* GENESIS_MERKLE =
        "8ec923e8d644631a549ddbd51cd350f597e29ca665979f01a501456bbc77f16b";
    static constexpr const char* GENESIS_TIMESTAMP =
        "A New Beginning for a Lasting Project - Quimera Labs 2026";

    // Mensagem de rede (magic bytes: '2','x','2','C')
    static constexpr uint8_t MESSAGE_START[4] = {0x32, 0x78, 0x32, 0x43};

    // Seeds DNS
    static const QStringList DNS_SEEDS;

    // Emissão de moedas
    static constexpr int64_t PREMINE_AMOUNT = 11000000LL * 100000000LL; // 11M moedas em satoshis
    static constexpr int64_t COIN = 100000000LL;  // 1 moeda = 10^8 satoshis
    static constexpr int64_t TAIL_EMISSION_REWARD = 1000LL * COIN;  // Ano 20+
    static constexpr uint32_t BLOCKS_PER_YEAR = 262800;

    // Recompensa por bloco por ano
    static int64_t getBlockReward(uint32_t nHeight);
};

// ============================================================
// Parâmetros da rede de teste (Testnet)
// ============================================================
struct TestNetParams {
    static constexpr const char* NETWORK_ID = "test";
    static constexpr uint16_t DEFAULT_PORT = 51884;
    static constexpr uint8_t PUBKEY_ADDRESS_PREFIX = 51;
    static constexpr uint8_t SCRIPT_ADDRESS_PREFIX = 50;
    static constexpr uint8_t SECRET_KEY_PREFIX = 239;
    static constexpr uint8_t MESSAGE_START[4] = {0x4c, 0x90, 0x34, 0xfb};
    static constexpr uint32_t LAST_POW_BLOCK = 0x7fffffff;
    static constexpr uint32_t COINBASE_MATURITY = 10;
};

// ============================================================
// Classe principal de parâmetros da cadeia
// ============================================================
class ChainParams {
public:
    enum Network {
        MAIN,
        TESTNET,
        REGTEST
    };

    static ChainParams& instance();

    void setNetwork(Network net);
    Network currentNetwork() const { return m_network; }

    // Getters para parâmetros da rede atual
    uint16_t defaultPort() const;
    uint8_t pubkeyAddressPrefix() const;
    uint8_t scriptAddressPrefix() const;
    uint8_t secretKeyPrefix() const;
    QByteArray extPublicKeyPrefix() const;
    QByteArray extSecretKeyPrefix() const;
    QString cashaddrPrefix() const;
    QString networkId() const;
    QStringList dnsSeeds() const;
    uint32_t lastPowBlock() const;
    uint32_t targetSpacing() const;
    uint32_t coinbaseMaturity() const;
    uint32_t stakeMinAge() const;
    bool isTestnet() const { return m_network == TESTNET; }
    bool isMainnet() const { return m_network == MAIN; }

    // Cálculo de recompensa
    int64_t getBlockReward(uint32_t nHeight) const;

    // Constante da moeda
    static constexpr int64_t COIN = 100000000LL;
    static constexpr int64_t CENT = 1000000LL;
    // Ajustado para evitar estouro de int64_t (21 trilhões * 10^8)
    static constexpr int64_t MAX_MONEY = 2100000000000000000LL;

private:
    ChainParams();
    Network m_network;
};

} // namespace Coin2x2
