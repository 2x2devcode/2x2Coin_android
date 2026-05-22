// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Carteira Hierárquica Determinística (HD Wallet) para 2X2Coin
// Implementa BIP32, BIP39 (mnemônico) e BIP44 (derivação de caminhos)
// Caminho de derivação: m/44'/60'/0'/0/n (compatível com UTXO coins)

#pragma once

#include <QString>
#include <QStringList>
#include <QByteArray>
#include <QObject>
#include <memory>
#include <vector>
#include <cstdint>

namespace Coin2x2 {

// ============================================================
// Estrutura de chave HD (nó BIP32)
// ============================================================
struct HDNode {
    QByteArray privateKey;   // 32 bytes
    QByteArray publicKey;    // 33 bytes (comprimida)
    QByteArray chainCode;    // 32 bytes
    uint32_t   depth;
    uint32_t   childNumber;
    QByteArray fingerprint;  // 4 bytes

    bool isValid() const {
        return privateKey.size() == 32 && chainCode.size() == 32;
    }
};

// ============================================================
// Gerador de mnemônico BIP39
// ============================================================
class BIP39 {
public:
    // Gera 12 palavras mnemônicas (128 bits de entropia)
    static QStringList generateMnemonic(int wordCount = 12);

    // Valida um mnemônico BIP39
    static bool validateMnemonic(const QStringList& words);

    // Converte mnemônico para seed (512 bits)
    static QByteArray mnemonicToSeed(const QStringList& words,
                                      const QString& passphrase = "");

    // Retorna a lista de palavras BIP39 em inglês
    static const QStringList& wordList();

private:
    static QStringList s_wordList;
    static bool s_wordListLoaded;
    static void loadWordList();
};

// ============================================================
// Carteira HD para 2X2Coin
// ============================================================
class HDWallet : public QObject {
    Q_OBJECT

public:
    explicit HDWallet(QObject* parent = nullptr);
    ~HDWallet();

    // Cria nova carteira com mnemônico gerado aleatoriamente
    bool createNew(const QString& passphrase = "");

    // Restaura carteira a partir de mnemônico existente
    bool restore(const QStringList& mnemonic, const QString& passphrase = "");

    // Carrega carteira de arquivo criptografado
    bool loadFromFile(const QString& filePath, const QString& password);

    // Salva carteira em arquivo criptografado
    bool saveToFile(const QString& filePath, const QString& password) const;

    // Verifica se a carteira está inicializada
    bool isInitialized() const { return m_initialized; }

    // Retorna o mnemônico (apenas após criação/restauração)
    QStringList mnemonic() const { return m_mnemonic; }

    // Deriva endereço de recebimento (BIP44: m/44'/0'/0'/0/index)
    QString deriveReceiveAddress(uint32_t index = 0) const;

    // Deriva endereço de troco (BIP44: m/44'/0'/0'/1/index)
    QString deriveChangeAddress(uint32_t index = 0) const;

    // Deriva chave privada para um índice
    QByteArray derivePrivateKey(uint32_t index = 0, bool change = false) const;

    // Deriva chave pública para um índice
    QByteArray derivePublicKey(uint32_t index = 0, bool change = false) const;

    // Retorna o próximo índice de endereço não utilizado
    uint32_t nextReceiveIndex() const { return m_receiveIndex; }
    uint32_t nextChangeIndex() const  { return m_changeIndex; }

    // Incrementa índices
    void incrementReceiveIndex() { ++m_receiveIndex; }
    void incrementChangeIndex()  { ++m_changeIndex; }

    // Exporta chave pública estendida (xpub)
    QString exportXPub() const;

    // Exporta chave privada estendida (xprv)
    QString exportXPriv() const;

    // Retorna o hash160 de uma chave pública
    static QByteArray hash160(const QByteArray& pubkey);

    // Retorna endereço a partir de chave pública
    static QString pubkeyToAddress(const QByteArray& pubkey, uint8_t prefix = 3);

    // Assina uma mensagem com chave privada
    QByteArray signMessage(const QByteArray& message, uint32_t keyIndex = 0) const;

    // Verifica assinatura
    static bool verifySignature(const QByteArray& message,
                                 const QByteArray& signature,
                                 const QByteArray& pubkey);

Q_SIGNALS:
    void walletCreated();
    void walletLoaded();
    void walletSaved();
    void errorOccurred(const QString& error);

private:
    // Derivação BIP32
    HDNode deriveChildKey(const HDNode& parent, uint32_t index) const;
    HDNode derivePath(const QString& path) const;
    HDNode deriveAccount(uint32_t account = 0) const;

    // Operações criptográficas
    static QByteArray hmacSha512(const QByteArray& key, const QByteArray& data);
    static QByteArray secp256k1PrivToPub(const QByteArray& privkey);
    static QByteArray secp256k1Sign(const QByteArray& privkey, const QByteArray& hash);

    // Estado interno
    bool         m_initialized;
    QStringList  m_mnemonic;
    QByteArray   m_seed;         // 512 bits
    HDNode       m_masterKey;    // Chave mestre BIP32
    uint32_t     m_receiveIndex;
    uint32_t     m_changeIndex;

    // Coin type para 2X2Coin no BIP44 (usando 0 por compatibilidade)
    static constexpr uint32_t COIN_TYPE = 0;
    static constexpr uint32_t HARDENED = 0x80000000;
};

} // namespace Coin2x2
