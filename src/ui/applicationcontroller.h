// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Controlador principal da aplicação - ponte entre C++ e QML

#pragma once

#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include "../wallet/walletmanager.h"
#include "../network/networkmanager.h"

namespace Coin2x2 {

class ApplicationController : public QObject {
    Q_OBJECT

    // Propriedades expostas ao QML
    Q_PROPERTY(QString  appVersion    READ appVersion    CONSTANT)
    Q_PROPERTY(QString  coinName      READ coinName      CONSTANT)
    Q_PROPERTY(QString  coinTicker    READ coinTicker    CONSTANT)
    Q_PROPERTY(QString  networkName   READ networkName   NOTIFY networkChanged)
    Q_PROPERTY(bool     hasWallet     READ hasWallet     NOTIFY walletStateChanged)
    Q_PROPERTY(bool     isLocked      READ isLocked      NOTIFY lockStateChanged)
    Q_PROPERTY(bool     isConnected   READ isConnected   NOTIFY connectionStateChanged)
    Q_PROPERTY(bool     isSyncing     READ isSyncing     NOTIFY syncStateChanged)
    Q_PROPERTY(int      blockHeight   READ blockHeight   NOTIFY blockHeightChanged)
    Q_PROPERTY(int      peerCount     READ peerCount     NOTIFY peerCountChanged)
    Q_PROPERTY(QString  balance       READ balance       NOTIFY balanceChanged)
    Q_PROPERTY(QString  unconfBalance READ unconfBalance NOTIFY balanceChanged)
    Q_PROPERTY(QString  stakeBalance  READ stakeBalance  NOTIFY balanceChanged)
    Q_PROPERTY(QString  totalBalance  READ totalBalance  NOTIFY balanceChanged)
    Q_PROPERTY(QString  receiveAddress READ receiveAddress NOTIFY addressChanged)
    Q_PROPERTY(bool     isPoS         READ isPoS         NOTIFY blockHeightChanged)
    Q_PROPERTY(bool     stakingEnabled READ stakingEnabled NOTIFY stakingChanged)
    Q_PROPERTY(QString  currentPage   READ currentPage   WRITE setCurrentPage NOTIFY pageChanged)

public:
    explicit ApplicationController(QObject* parent = nullptr);
    ~ApplicationController();

    // Registrar tipos QML
    static void registerQmlTypes();

    // Inicializar e conectar ao QML engine
    void initialize(QQmlApplicationEngine* engine);

    // Getters
    QString appVersion() const  { return "2.0.2"; }
    QString coinName() const    { return "2x2Coin"; }
    QString coinTicker() const  { return "2X2"; }
    QString networkName() const;
    bool hasWallet() const;
    bool isLocked() const;
    bool isConnected() const;
    bool isSyncing() const;
    int blockHeight() const;
    int peerCount() const;
    QString balance() const;
    QString unconfBalance() const;
    QString stakeBalance() const;
    QString totalBalance() const;
    QString receiveAddress() const;
    bool isPoS() const;
    bool stakingEnabled() const;
    QString currentPage() const { return m_currentPage; }
    void setCurrentPage(const QString& page);
    Q_PROPERTY(QVariantMap settings READ settings NOTIFY settingsChanged)
 
     // public
    QVariantMap settings() const {
      QVariantMap s;
      s["darkTheme"] = true;
      s["notifications"] = true;
      s["biometric"] = false;
      s["testnet"] = false;
      return s;
    }


    // ============================================================
    // Métodos invocáveis do QML
    // ============================================================

    // Wallet
    Q_INVOKABLE bool createNewWallet(const QString& passphrase = "");
    Q_INVOKABLE bool restoreWallet(const QString& mnemonic, const QString& passphrase = "");
    Q_INVOKABLE bool unlockWallet(const QString& password);
    Q_INVOKABLE bool lockWallet();
    Q_INVOKABLE bool changePassword(const QString& oldPass, const QString& newPass);
    Q_INVOKABLE QStringList getMnemonic();
    Q_INVOKABLE bool verifyMnemonic(const QString& mnemonic);

    // Endereços
    Q_INVOKABLE QString generateNewAddress(const QString& label = "");
    Q_INVOKABLE QString getReceiveAddress();
    Q_INVOKABLE QVariantList getAddresses();
    Q_INVOKABLE bool isValidAddress(const QString& address);
    Q_INVOKABLE bool setAddressLabel(const QString& address, const QString& label);

    // Transações
    Q_INVOKABLE QVariantList getTransactions(int limit = 50, int offset = 0);
    Q_INVOKABLE QVariantMap getTransaction(const QString& txid);
    Q_INVOKABLE QString sendCoins(const QString& toAddress, const QString& amount,
                                   const QString& fee = "0", const QString& comment = "");
    Q_INVOKABLE QString estimateFee(const QString& toAddress, const QString& amount);

    // Formatação
    Q_INVOKABLE QString formatAmount(double amount, bool withUnit = true);
    Q_INVOKABLE QString formatSatoshis(qint64 satoshis, bool withUnit = true);
    Q_INVOKABLE double satoshisToCoins(qint64 satoshis);
    Q_INVOKABLE qint64 coinsToSatoshis(double coins);

    // Backup
    Q_INVOKABLE bool backupWallet(const QString& path);
    Q_INVOKABLE bool restoreFromBackup(const QString& path, const QString& password);

    // Exportação
    Q_INVOKABLE QString exportPrivateKey(const QString& address, const QString& password);
    Q_INVOKABLE QString exportXPub();
    Q_INVOKABLE bool importPrivateKey(const QString& wif, const QString& label = "");

    // Staking
    Q_INVOKABLE bool setStakingEnabled(bool enabled);
    Q_INVOKABLE QString getStakingInfo();
    Q_INVOKABLE QString getStakingWeight();

    // Rede
    Q_INVOKABLE void connectToNetwork();
    Q_INVOKABLE void disconnectFromNetwork();
    Q_INVOKABLE QString getExplorerUrl(const QString& txid);
    Q_INVOKABLE QString getAddressExplorerUrl(const QString& address);
    Q_INVOKABLE void openExplorer(const QString& txid);

    // Configurações
    Q_INVOKABLE void setTestnet(bool testnet);
    Q_INVOKABLE bool isTestnet();
    Q_INVOKABLE void setRpcConfig(const QString& host, int port,
                                   const QString& user, const QString& password);

    // Informações da moeda
    Q_INVOKABLE QVariantList getEmissionSchedule();
    Q_INVOKABLE int getLastPowBlock();
    Q_INVOKABLE double getInflationRate(int year);
    Q_INVOKABLE QString getGenesisHash();
    Q_INVOKABLE QStringList getDnsSeeds();

    // QR Code
    Q_INVOKABLE QString generateQRCodeUrl(const QString& address, qint64 amount = 0);
    Q_INVOKABLE QString parseQRCode(const QString& qrData);

    // Clipboard
    Q_INVOKABLE void copyToClipboard(const QString& text);
    Q_INVOKABLE QString pasteFromClipboard();

    // Biometria
    Q_INVOKABLE bool isBiometricAvailable();
    Q_INVOKABLE void authenticateWithBiometric();

    // Notificações
    Q_INVOKABLE void showNotification(const QString& title, const QString& message);

Q_SIGNALS:
    void networkChanged();
    void walletStateChanged();
    void lockStateChanged();
    void connectionStateChanged();
    void syncStateChanged();
    void blockHeightChanged();
    void peerCountChanged();
    void balanceChanged();
    void addressChanged();
    void stakingChanged();
    void pageChanged();
    void settingsChanged();

    // Eventos da wallet
    void walletCreated(const QStringList& mnemonic);
    void walletRestored();
    void walletUnlocked();
    void walletLocked();
    void transactionReceived(const QVariantMap& tx);
    void transactionSent(const QString& txid);
    void transactionFailed(const QString& error);
    void errorOccurred(const QString& error);
    void infoMessage(const QString& message);
    void biometricResult(bool success);

private:
    void connectSignals();

    WalletManager* m_wallet;
    NetworkManager* m_network;
    QString m_currentPage;
};

} // namespace Coin2x2
