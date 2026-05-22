// Copyright (c) 2009-2010 Satoshi Nakamoto
// Copyright (c) 2009-2015 The Bitcoin Core developers
// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Codificação Base58Check para endereços 2X2Coin
// Prefixo PUBKEY_ADDRESS = 3 → endereços começam com '2'

#pragma once

#include <QString>
#include <QByteArray>
#include <vector>
#include <cstdint>

namespace Coin2x2 {

class Base58 {
public:
    // Codifica bytes para string Base58
    static QString encode(const QByteArray& data);

    // Decodifica string Base58 para bytes
    // Retorna false se inválido
    static bool decode(const QString& str, QByteArray& out);

    // Codifica com checksum (Base58Check)
    static QString encodeCheck(const QByteArray& data);

    // Decodifica Base58Check e verifica checksum
    // Retorna false se checksum inválido
    static bool decodeCheck(const QString& str, QByteArray& out);

    // Gera endereço P2PKH para 2X2Coin a partir de hash160
    // Usa prefixo 3 (mainnet) ou 51 (testnet)
    static QString pubkeyHashToAddress(const QByteArray& hash160, uint8_t prefix = 3);

    // Gera endereço P2SH para 2X2Coin
    static QString scriptHashToAddress(const QByteArray& hash160, uint8_t prefix = 90);

    // Codifica chave privada em WIF (Wallet Import Format)
    static QString privateKeyToWIF(const QByteArray& privkey, bool compressed = true,
                                   uint8_t prefix = 128);

    // Decodifica WIF para chave privada
    static bool wifToPrivateKey(const QString& wif, QByteArray& privkey,
                                bool& compressed, uint8_t prefix = 128);

    // Valida endereço 2X2Coin
    static bool isValidAddress(const QString& address, uint8_t prefix = 3);

private:
    static const QString BASE58_CHARS;
    static QByteArray sha256d(const QByteArray& data);
};

} // namespace Coin2x2
