// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Gerenciador principal da carteira 2X2Coin para Android

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QList>
#include <QDateTime>
#include <memory>
#include "hdwallet.h"

namespace Coin2x2 {

// ============================================================
// Estrutura de transação
// ============================================================
struct TransactionRecord {
    QString txid;
    QString address;
    QString label;
    qint64  amount;       // em satoshis (negativo = enviado)
    qint64  fee;          // em satoshis
    int     confirmations;
    QDateTime timestamp;
    bool    isCoinbase;
    bool    isStake;
    QString type;         // "received", "sent", "staked", "mined"

    // Formata o valor para exibição
    QString formattedAmount() const;
    QString formattedFee() const;
    QString statusText() const;
};

// ============================================================
// Estrutura de endereço
// ============================================================
struct AddressRecord {
    QString address;
    QString label;
    bool    isChange;
    uint32_t index;
    qint64  balance;      // saldo associado em satoshis
    int     txCount;
};

// ============================================================
// Gerenciador da Wallet 2X2Coin
// ============================================================
class WalletManager : public QObject {
    Q_OBJECT

    // Propriedades expostas ao QML
    Q_PROPERTY(qint64  balance         READ balance         NOTIFY balanceChanged)
    Q_PROPERTY(qint64  unconfirmedBalance READ unconfirmedBalance NOTIFY balanceChanged)
    Q_PROPERTY(qint64  stakeBalance    READ stakeBalance    NOTIFY balanceChanged)
    Q_PROPERTY(qint64  immatureBalance READ immatureBalance NOTIFY balanceChanged)
    Q_PROPERTY(QString currentAddress  READ currentAddress  NOTIFY addressChanged)
    Q_PROPERTY(bool    isLocked        READ isLocked        NOTIFY lockStateChanged)
    Q_PROPERTY(bool    isInitialized   READ isInitialized   NOTIFY walletStateChanged)
    Q_PROPERTY(bool    isSyncing       READ isSyncing       NOTIFY syncStateChanged)
    Q_PROPERTY(int     blockHeight     READ blockHeight     NOTIFY blockHeightChanged)
    Q_PROPERTY(int     peerCount       READ peerCount       NOTIFY peerCountChanged)
    Q_PROPERTY(QString networkName     READ networkName     CONSTANT)
    Q_PROPERTY(bool    isPoS           READ isPoS           NOTIFY blockHeightChanged)

public:
    explicit WalletManager(QObject* parent = nullptr);
    ~WalletManager();

    // Singleton
    static WalletManager& instance();

    // Estado da wallet
    bool isInitialized() const { return m_initialized; }
    bool isLocked() const { return m_locked; }
    bool isSyncing() const { return m_syncing; }

    // Saldos
    qint64 balance() const { return m_balance; }
    qint64 unconfirmedBalance() const { return m_unconfirmedBalance; }
    qint64 stakeBalance() const { return m_stakeBalance; }
    qint64 immatureBalance() const { return m_immatureBalance; }
    qint64 totalBalance() const {
        return m_balance + m_unconfirmedBalance + m_stakeBalance;
    }

    // Rede
    int blockHeight() const { return m_blockHeight; }
    int peerCount() const { return m_peerCount; }
    QString networkName() const;
    bool isPoS() const { return m_blockHeight > 110000; }

    // Endereço atual
    QString currentAddress() const { return m_currentAddress; }

    // Formatação de valores
    Q_INVOKABLE QString formatAmount(qint64 satoshis, bool withUnit = true) const;
    Q_INVOKABLE QString formatAmountFull(qint64 satoshis) const;
    Q_INVOKABLE qint64 parseAmount(const QString& amountStr) const;

    // Operações da wallet
    Q_INVOKABLE bool createWallet(const QString& passphrase = "");
    Q_INVOKABLE bool restoreWallet(const QString& mnemonic, const QString& passphrase = "");
    Q_INVOKABLE bool loadWallet(const QString& password);
    Q_INVOKABLE bool saveWallet(const QString& password);
    Q_INVOKABLE bool lockWallet();
    Q_INVOKABLE bool unlockWallet(const QString& password);
    Q_INVOKABLE bool changePassword(const QString& oldPassword, const QString& newPassword);

    // Endereços
    Q_INVOKABLE QString generateNewAddress(const QString& label = "");
    Q_INVOKABLE QString getReceiveAddress() const;
    Q_INVOKABLE QList<AddressRecord> getAddresses() const;
    Q_INVOKABLE bool setAddressLabel(const QString& address, const QString& label);
    Q_INVOKABLE bool isValidAddress(const QString& address) const;

    // Transações
    Q_INVOKABLE QList<TransactionRecord> getTransactions(int limit = 50, int offset = 0) const;
    Q_INVOKABLE TransactionRecord getTransaction(const QString& txid) const;
    Q_INVOKABLE QString sendCoins(const QString& toAddress, qint64 amount,
                                   qint64 fee = 0, const QString& comment = "");
    Q_INVOKABLE qint64 estimateFee(const QString& toAddress, qint64 amount) const;

    // Mnemônico
    Q_INVOKABLE QStringList getMnemonic() const;
    Q_INVOKABLE bool verifyMnemonic(const QStringList& words) const;

    // Exportação
    Q_INVOKABLE QString exportPrivateKey(const QString& address, const QString& password) const;
    Q_INVOKABLE QString exportXPub() const;
    Q_INVOKABLE bool importPrivateKey(const QString& wif, const QString& label = "");

    // Staking (PoS)
    Q_INVOKABLE bool enableStaking(bool enable);
    Q_INVOKABLE bool isStakingEnabled() const { return m_stakingEnabled; }
    Q_INVOKABLE qint64 getStakingWeight() const;
    Q_INVOKABLE QString getStakingInfo() const;

    // Backup
    Q_INVOKABLE bool backupWallet(const QString& filePath) const;
    Q_INVOKABLE bool restoreFromBackup(const QString& filePath, const QString& password);

    // Configurações
    Q_INVOKABLE void setNetwork(bool testnet);
    Q_INVOKABLE bool isTestnet() const;

    // Utilitários
    Q_INVOKABLE QString getWalletPath() const;
    Q_INVOKABLE qint64 getCoinSupply() const;
    Q_INVOKABLE int getLastPowBlock() const { return 110000; }
    Q_INVOKABLE double getInflationRate(int year) const;

Q_SIGNALS:
    void walletCreated(const QStringList& mnemonic);
    void walletLoaded();
    void walletSaved();
    void walletStateChanged();
    void lockStateChanged();
    void balanceChanged();
    void addressChanged();
    void transactionReceived(const TransactionRecord& tx);
    void transactionSent(const QString& txid);
    void transactionFailed(const QString& error);
    void syncStateChanged();
    void blockHeightChanged();
    void peerCountChanged();
    void stakingStatusChanged();
    void errorOccurred(const QString& error);
    void infoMessage(const QString& message);

public Q_SLOTS:
    void onNetworkConnected();
    void onNetworkDisconnected();
    void onNewBlock(int height, const QString& hash);
    void onTransactionReceived(const QString& txid);
    void onBalanceUpdated(qint64 confirmed, qint64 unconfirmed, qint64 stake, qint64 immature);
    void onPeerCountChanged(int count);

private:
    void initializeDefaults();
    QString getWalletFilePath() const;
    bool saveToStorage() const;
    bool loadFromStorage();

    // Estado
    bool    m_initialized;
    bool    m_locked;
    bool    m_syncing;
    bool    m_stakingEnabled;

    // Saldos (em satoshis)
    qint64  m_balance;
    qint64  m_unconfirmedBalance;
    qint64  m_stakeBalance;
    qint64  m_immatureBalance;

    // Rede
    int     m_blockHeight;
    int     m_peerCount;

    // Endereços e transações
    QString m_currentAddress;
    QList<AddressRecord>    m_addresses;
    QList<TransactionRecord> m_transactions;

    // Carteira HD
    std::unique_ptr<HDWallet> m_hdWallet; 

    mutable QString m_currentPassword; 
    // Singleton 
    static WalletManager* s_instance;
};

} // namespace Coin2x2
