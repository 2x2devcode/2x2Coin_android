// Copyright (c) 2026 - 2X2Coin Project
// Wrapper para operações secp256k1 (chaves privadas/públicas Bitcoin-compatíveis)

#pragma once
#include <QByteArray>
#include <QString>

namespace Coin2x2 {
namespace Crypto {

// ============================================================
// Operações com chaves secp256k1
// ============================================================

// Verificar se uma chave privada é válida
bool isValidPrivateKey(const QByteArray& privkey);

// Derivar chave pública a partir da chave privada
// compressed = true para chave pública comprimida (33 bytes)
// compressed = false para chave pública não comprimida (65 bytes)
QByteArray privateKeyToPublicKey(const QByteArray& privkey, bool compressed = true);

// Derivar endereço P2PKH a partir da chave pública
// prefix = byte de versão (3 para 2X2Coin mainnet)
QByteArray publicKeyToAddress(const QByteArray& pubkey, uint8_t prefix);

// Adição de chave privada (para derivação BIP32)
// result = (privkey + tweak) mod n
bool privateKeyAdd(QByteArray& privkey, const QByteArray& tweak);

// Adição de ponto de chave pública (para derivação BIP32)
// result = pubkey + tweak*G
bool publicKeyAdd(QByteArray& pubkey, const QByteArray& tweak);

// Assinar dados com chave privada (ECDSA)
QByteArray sign(const QByteArray& hash, const QByteArray& privkey);

// Verificar assinatura ECDSA
bool verify(const QByteArray& hash, const QByteArray& signature, const QByteArray& pubkey);

// Gerar chave privada aleatória segura
QByteArray generatePrivateKey();

// Serializar ponto de chave pública (comprimido)
QByteArray serializePublicKey(const QByteArray& pubkey);

} // namespace Crypto
} // namespace Coin2x2
