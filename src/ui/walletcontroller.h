// Copyright (c) 2026 - 2X2Coin Project
// Ponte entre QML (UI) e o núcleo criptográfico / carteira 2X2Coin

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

namespace Coin2x2 {

class WalletManager;
class NetworkManager;

/**
 * WalletController — camada de orquestração exposta ao QML.
 * Encapsula WalletManager + ChainParams + validações de rede 2X2Coin.
 * Chaves privadas transitam apenas em SecureBuffer com wipe no escopo.
 */
class WalletController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool    hasWallet      READ hasWallet      NOTIFY walletStateChanged)
    Q_PROPERTY(bool    isLocked       READ isLocked       NOTIFY lockStateChanged)
    Q_PROPERTY(QString balance       READ balance        NOTIFY balanceChanged)
    Q_PROPERTY(QString receiveAddress READ receiveAddress NOTIFY addressChanged)
    Q_PROPERTY(QString networkLabel   READ networkLabel   NOTIFY networkChanged)
    Q_PROPERTY(int     blockHeight    READ blockHeight    NOTIFY blockHeightChanged)
    Q_PROPERTY(bool    isPoS          READ isPoS          NOTIFY blockHeightChanged)

public:
    explicit WalletController(QObject* parent = nullptr);
    ~WalletController() override;

    static void registerQmlTypes();
    static WalletController* instance();
    static void setInstance(WalletController* ctrl);

    bool hasWallet() const;
    bool isLocked() const;
    QString balance() const;
    QString receiveAddress() const;
    QString networkLabel() const;
    int blockHeight() const;
    bool isPoS() const;

    // Ciclo de vida da carteira
    Q_INVOKABLE bool createWallet(const QString& passphrase = QString());
    Q_INVOKABLE bool restoreFromMnemonic(const QString& mnemonic,
                                         const QString& passphrase = QString());
    Q_INVOKABLE bool unlock(const QString& password);
    Q_INVOKABLE bool lock();
    Q_INVOKABLE QStringList mnemonicWords();

    // Endereços (prefixo PubKeyHash da mainnet = 3 → Base58 começa com '2')
    Q_INVOKABLE QString newReceiveAddress(const QString& label = QString());
    Q_INVOKABLE bool validateAddress(const QString& address) const;
    Q_INVOKABLE QVariantList addressBook() const;

    // Transações e taxas
    Q_INVOKABLE QString send(const QString& toAddress,
                             const QString& amountCoins,
                             const QString& feeCoins = QString(),
                             const QString& comment = QString());
    Q_INVOKABLE QString estimateNetworkFee(const QString& toAddress,
                                           const QString& amountCoins) const;
    Q_INVOKABLE QVariantList transactionHistory(int limit = 50, int offset = 0) const;

    // Exportação segura (WIF com prefixo SECRET_KEY da rede)
    Q_INVOKABLE QString exportWifForAddress(const QString& address);

    // Parâmetros de consenso expostos à UI
    Q_INVOKABLE QVariantMap chainInfo() const;
    Q_INVOKABLE int lastPowBlock() const;
    Q_INVOKABLE int targetSpacingSeconds() const;

    void bindManagers(WalletManager* wallet, NetworkManager* network);

Q_SIGNALS:
    void walletStateChanged();
    void lockStateChanged();
    void balanceChanged();
    void addressChanged();
    void networkChanged();
    void blockHeightChanged();
    void transactionSent(const QString& txid);
    void transactionFailed(const QString& error);
    void errorOccurred(const QString& message);
    void infoMessage(const QString& message);
    void walletCreated(const QStringList& mnemonic);

private:
    void connectManagerSignals();
    qint64 parseCoins(const QString& amount) const;
    QString formatCoins(qint64 satoshis) const;

    WalletManager* m_wallet;
    NetworkManager* m_network;

    static WalletController* s_instance;
};

} // namespace Coin2x2
