// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação do Controlador da Aplicação 2X2Coin

#include "applicationcontroller.h"
#include "../core/chainparams.h"
#include <QQmlContext>
#include <QClipboard>
#include <QGuiApplication>
#include <QDesktopServices>
#include <QUrl>
#include <QDebug>
#include <QCoreApplication>
#include <QJniObject>
#include <QtCore/qnativeinterface.h>
#include <QGuiApplication>

namespace Coin2x2 {

static ApplicationController* g_appInstance = nullptr;
void ApplicationController::setInstance(ApplicationController* instance) {
    g_appInstance = instance;
}
ApplicationController* ApplicationController::instance() {
    return g_appInstance;
}

ApplicationController::ApplicationController(QObject* parent)
    : QObject(parent)
    , m_wallet(&WalletManager::instance())
    , m_network(&NetworkManager::instance())
    , m_currentPage("splash")
{
    connectSignals();
}

ApplicationController::~ApplicationController() {}

void ApplicationController::registerQmlTypes() {
    qmlRegisterSingletonType<ApplicationController>(
        "Coin2x2", 1, 0, "App",
        [](QQmlEngine*, QJSEngine*) -> QObject* {
            if (g_appInstance) {
                return g_appInstance;
            }
            static ApplicationController fallback;
            return &fallback;    
        }
    );
}

void ApplicationController::initialize(QQmlApplicationEngine* engine) {
    engine->rootContext()->setContextProperty("app", this);
    engine->rootContext()->setContextProperty("wallet", m_wallet);
    engine->rootContext()->setContextProperty("network", m_network);
}

void ApplicationController::connectSignals() {
    // Wallet signals
    connect(m_wallet, &WalletManager::walletCreated, this,
            [this](const QStringList& mnemonic) {
        Q_EMIT walletCreated(mnemonic);
        Q_EMIT walletStateChanged();
        Q_EMIT lockStateChanged();
    });

    connect(m_wallet, &WalletManager::walletLoaded, this, [this]() {
        Q_EMIT walletRestored();
        Q_EMIT walletStateChanged();
    });

    connect(m_wallet, &WalletManager::lockStateChanged, this, [this]() {
        Q_EMIT lockStateChanged();
        if (m_wallet->isLocked()) {
            Q_EMIT walletLocked();
        } else {
            Q_EMIT walletUnlocked();
        }
    });

    connect(m_wallet, &WalletManager::balanceChanged, this,
            &ApplicationController::balanceChanged);

    connect(m_wallet, &WalletManager::addressChanged, this,
            &ApplicationController::addressChanged);

    connect(m_wallet, &WalletManager::transactionSent, this,
            &ApplicationController::transactionSent);

    connect(m_wallet, &WalletManager::transactionFailed, this,
            &ApplicationController::transactionFailed);

    connect(m_wallet, &WalletManager::errorOccurred, this,
            &ApplicationController::errorOccurred);

    connect(m_wallet, &WalletManager::infoMessage, this,
            &ApplicationController::infoMessage);

    connect(m_wallet, &WalletManager::stakingStatusChanged, this,
            &ApplicationController::stakingChanged);

    // Network signals
    connect(m_network, &NetworkManager::connectionStateChanged, this,
            [this](bool) { Q_EMIT connectionStateChanged(); });

    connect(m_network, &NetworkManager::blockHeightChanged, this,
            [this](int, const QString&) { Q_EMIT blockHeightChanged(); });

    connect(m_network, &NetworkManager::peerCountChanged, this,
            [this](int) { Q_EMIT peerCountChanged(); });

    connect(m_network, &NetworkManager::syncStateChanged, this,
            [this](bool) { Q_EMIT syncStateChanged(); });

    // Repassar informações de bloco para a wallet
    connect(m_network, &NetworkManager::blockHeightChanged, m_wallet,
            &WalletManager::onNewBlock);

    connect(m_network, &NetworkManager::peerCountChanged, m_wallet,
            &WalletManager::onPeerCountChanged);
}

// ============================================================
// Getters
// ============================================================
QString ApplicationController::networkName() const {
    return m_wallet->networkName();
}

bool ApplicationController::hasWallet() const {
    return m_wallet->isInitialized();
}

bool ApplicationController::isLocked() const {
    return m_wallet->isLocked();
}

bool ApplicationController::isConnected() const {
    return m_network->isConnected();
}

bool ApplicationController::isSyncing() const {
    return m_network->isSyncing();
}

int ApplicationController::blockHeight() const {
    return m_network->blockHeight();
}

int ApplicationController::peerCount() const {
    return m_network->peerCount();
}

QString ApplicationController::balance() const {
    return m_wallet->formatAmount(m_wallet->balance(), true);
}

QString ApplicationController::unconfBalance() const {
    return m_wallet->formatAmount(m_wallet->unconfirmedBalance(), true);
}

QString ApplicationController::stakeBalance() const {
    return m_wallet->formatAmount(m_wallet->stakeBalance(), true);
}

QString ApplicationController::totalBalance() const {
    return m_wallet->formatAmount(m_wallet->totalBalance(), true);
}

QString ApplicationController::receiveAddress() const {
    return m_wallet->getReceiveAddress();
}

bool ApplicationController::isPoS() const {
    return m_network->blockHeight() > 110000;
}

bool ApplicationController::stakingEnabled() const {
    return m_wallet->isStakingEnabled();
}

void ApplicationController::setCurrentPage(const QString& page) {
    if (m_currentPage != page) {
        m_currentPage = page;
        Q_EMIT pageChanged();
    }
}

// ============================================================
// Wallet
// ============================================================
bool ApplicationController::createNewWallet(const QString& passphrase) {
    return m_wallet->createWallet(passphrase);
}

bool ApplicationController::restoreWallet(const QString& mnemonic, const QString& passphrase) {
    return m_wallet->restoreWallet(mnemonic, passphrase);
}

bool ApplicationController::unlockWallet(const QString& password) {
    return m_wallet->unlockWallet(password);
}

bool ApplicationController::lockWallet() {
    return m_wallet->lockWallet();
}

bool ApplicationController::changePassword(const QString& oldPass, const QString& newPass) {
    return m_wallet->changePassword(oldPass, newPass);
}

QStringList ApplicationController::getMnemonic() {
    return m_wallet->getMnemonic();
}

bool ApplicationController::verifyMnemonic(const QString& mnemonic) {
    QStringList words = mnemonic.split(" ", Qt::SkipEmptyParts);
    return m_wallet->verifyMnemonic(words);
}

// ============================================================
// Endereços
// ============================================================
QString ApplicationController::generateNewAddress(const QString& label) {
    return m_wallet->generateNewAddress(label);
}

QString ApplicationController::getReceiveAddress() {
    return m_wallet->getReceiveAddress();
}

QVariantList ApplicationController::getAddresses() {
    QVariantList result;
    for (const auto& rec : m_wallet->getAddresses()) {
        QVariantMap map;
        map["address"] = rec.address;
        map["label"]   = rec.label;
        map["isChange"] = rec.isChange;
        map["index"]   = rec.index;
        map["balance"] = m_wallet->formatAmount(rec.balance, true);
        map["txCount"] = rec.txCount;
        result.append(map);
    }
    return result;
}

bool ApplicationController::isValidAddress(const QString& address) {
    return m_wallet->isValidAddress(address);
}

bool ApplicationController::setAddressLabel(const QString& address, const QString& label) {
    return m_wallet->setAddressLabel(address, label);
}

// ============================================================
// Transações
// ============================================================
QVariantList ApplicationController::getTransactions(int limit, int offset) {
    QVariantList result;
    for (const auto& tx : m_wallet->getTransactions(limit, offset)) {
        QVariantMap map;
        map["txid"]          = tx.txid;
        map["address"]       = tx.address;
        map["label"]         = tx.label;
        map["amount"]        = tx.formattedAmount();
        map["amountRaw"]     = tx.amount;
        map["fee"]           = tx.formattedFee();
        map["confirmations"] = tx.confirmations;
        map["timestamp"]     = tx.timestamp.toString("dd/MM/yyyy HH:mm");
        map["timestampRaw"]  = tx.timestamp.toSecsSinceEpoch();
        map["isCoinbase"]    = tx.isCoinbase;
        map["isStake"]       = tx.isStake;
        map["type"]          = tx.type;
        map["status"]        = tx.statusText();
        map["isReceived"]    = tx.amount >= 0;
        result.append(map);
    }
    return result;
}

QVariantMap ApplicationController::getTransaction(const QString& txid) {
    TransactionRecord tx = m_wallet->getTransaction(txid);
    QVariantMap map;
    map["txid"]          = tx.txid;
    map["address"]       = tx.address;
    map["amount"]        = tx.formattedAmount();
    map["fee"]           = tx.formattedFee();
    map["confirmations"] = tx.confirmations;
    map["timestamp"]     = tx.timestamp.toString("dd/MM/yyyy HH:mm:ss");
    map["type"]          = tx.type;
    map["status"]        = tx.statusText();
    map["explorerUrl"]   = m_network->getExplorerUrl(tx.txid);
    return map;
}

QString ApplicationController::sendCoins(const QString& toAddress, const QString& amount,
                                          const QString& fee, const QString& comment) {
    qint64 amountSats = m_wallet->parseAmount(amount);
    qint64 feeSats = fee == "0" ? 0 : m_wallet->parseAmount(fee);
    return m_wallet->sendCoins(toAddress, amountSats, feeSats, comment);
}

QString ApplicationController::estimateFee(const QString& toAddress, const QString& amount) {
    qint64 amountSats = m_wallet->parseAmount(amount);
    qint64 feeSats = m_wallet->estimateFee(toAddress, amountSats);
    return m_wallet->formatAmount(feeSats, true);
}

// ============================================================
// Formatação
// ============================================================
QString ApplicationController::formatAmount(double amount, bool withUnit) {
    qint64 satoshis = static_cast<qint64>(amount * 100000000.0);
    return m_wallet->formatAmount(satoshis, withUnit);
}

QString ApplicationController::formatSatoshis(qint64 satoshis, bool withUnit) {
    return m_wallet->formatAmount(satoshis, withUnit);
}

double ApplicationController::satoshisToCoins(qint64 satoshis) {
    return satoshis / 100000000.0;
}

qint64 ApplicationController::coinsToSatoshis(double coins) {
    return static_cast<qint64>(coins * 100000000.0);
}

// ============================================================
// Backup e exportação
// ============================================================
bool ApplicationController::backupWallet(const QString& path) {
    return m_wallet->backupWallet(path);
}

bool ApplicationController::restoreFromBackup(const QString& path, const QString& password) {
    return m_wallet->restoreFromBackup(path, password);
}

QString ApplicationController::exportPrivateKey(const QString& address, const QString& password) {
    return m_wallet->exportPrivateKey(address, password);
}

QString ApplicationController::exportXPub() {
    return m_wallet->exportXPub();
}

bool ApplicationController::importPrivateKey(const QString& wif, const QString& label) {
    return m_wallet->importPrivateKey(wif, label);
}

// ============================================================
// Staking
// ============================================================
bool ApplicationController::setStakingEnabled(bool enabled) {
    return m_wallet->enableStaking(enabled);
}

QString ApplicationController::getStakingInfo() {
    return m_wallet->getStakingInfo();
}

QString ApplicationController::getStakingWeight() {
    return m_wallet->formatAmount(m_wallet->getStakingWeight(), true);
}

// ============================================================
// Rede
// ============================================================
void ApplicationController::connectToNetwork() {
    m_network->connectToNetwork();
}

void ApplicationController::disconnectFromNetwork() {
    m_network->disconnectFromNetwork();
}

QString ApplicationController::getExplorerUrl(const QString& txid) {
    return m_network->getExplorerUrl(txid);
}

QString ApplicationController::getAddressExplorerUrl(const QString& address) {
    return m_network->getAddressExplorerUrl(address);
}

void ApplicationController::openExplorer(const QString& txid) {
    QDesktopServices::openUrl(QUrl(getExplorerUrl(txid)));
}

void ApplicationController::setTestnet(bool testnet) {
    m_wallet->setNetwork(testnet);
    Q_EMIT networkChanged();
}

bool ApplicationController::isTestnet() {
    return m_wallet->isTestnet();
}

void ApplicationController::setRpcConfig(const QString& host, int port,
                                          const QString& user, const QString& password) {
    m_network->setRpcHost(host);
    m_network->setRpcPort(port);
    m_network->setRpcCredentials(user, password);
}

// ============================================================
// Informações da moeda
// ============================================================
QVariantList ApplicationController::getEmissionSchedule() {
    QVariantList schedule;

    struct YearData {
        int year;
        qint64 initialSupply;
        int64_t blockReward;
        qint64 annualEmission;
        double inflation;
    };

    // Dados do README.md do 2X2Coin
    QList<YearData> data = {
        {1,  11000000LL,    100,    26280000LL,  238.91},
        {2,  37280000LL,    200,    52560000LL,  140.99},
        {3,  89840000LL,    550,    144540000LL, 160.89},
        {4,  234380000LL,   1300,   341640000LL, 145.76},
        {5,  576020000LL,   3250,   854100000LL, 148.29},
        {6,  3532520000LL,  3500,   2102400000LL, 26.04},
        {7,  3532520000LL,  4500,   1182600000LL, 26.56},
        {8,  5634920000LL,  5600,   1471680000LL, 26.12},
        {9,  7106600000LL,  7000,   1899600000LL, 25.89},
        {10, 8946200000LL,  8800,   2312640000LL, 25.68},
        {11, 8564920000LL,  8800,   2890800000LL, 25.56},
        {12, 7106600000LL,  7000,   2312640000LL, 25.85},
        {13, 3532920000LL,  11000,  2890800000LL, 25.68},
        {14, 8846200000LL,  14080,  3700224000LL, 25.68},
        {15, 3570264000LL,  18000,  7358400000LL, 25.94},
        {16, 56744264000LL, 55000,  14454000000LL, 25.47},
        {20, 71198264000LL, 1000,   262800000LL,  0.37},
    };

    for (const auto& d : data) {
        QVariantMap map;
        map["year"]           = d.year;
        map["initialSupply"]  = QString::number(d.initialSupply);
        map["blockReward"]    = QString::number(d.blockReward);
        map["annualEmission"] = QString::number(d.annualEmission);
        map["inflation"]      = QString::number(d.inflation, 'f', 2) + "%";
        schedule.append(map);
    }

    return schedule;
}

int ApplicationController::getLastPowBlock() {
    return 110000;
}

double ApplicationController::getInflationRate(int year) {
    return m_wallet->getInflationRate(year);
}

QString ApplicationController::getGenesisHash() {
    return "00000eea834a06692bc4f56d6f0061631c72fd75431ce9e5d7f3b9d712dc3a9b";
}

QStringList ApplicationController::getDnsSeeds() {
    return ChainParams::instance().dnsSeeds();
}

// ============================================================
// QR Code
// ============================================================
QString ApplicationController::generateQRCodeUrl(const QString& address, qint64 amount) {
    QString uri = "2x2coin:" + address;
    if (amount > 0) {
        double coins = amount / 100000000.0;
        uri += "?amount=" + QString::number(coins, 'f', 8);
    }
    return uri;
}

QString ApplicationController::parseQRCode(const QString& qrData) {
    // Parsear URI 2x2coin:ADDRESS?amount=X
    if (qrData.startsWith("2x2coin:")) {
        QString rest = qrData.mid(8);
        int queryPos = rest.indexOf('?');
        if (queryPos >= 0) {
            return rest.left(queryPos);
        }
        return rest;
    }
    // Pode ser apenas um endereço
    return qrData;
}

// ============================================================
// Clipboard
// ============================================================
void ApplicationController::copyToClipboard(const QString& text) {
    QGuiApplication::clipboard()->setText(text);
    Q_EMIT infoMessage("Copiado para a área de transferência");
}

QString ApplicationController::pasteFromClipboard() {
    return QGuiApplication::clipboard()->text();
}

// ============================================================
// Biometria (Android)
// ============================================================
bool ApplicationController::isBiometricAvailable() {
#ifdef Q_OS_ANDROID
    // Atualizado para o padrão do Qt 6.5
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    // Verificar disponibilidade de biometria via JNI
    return true; // Simplificado
#else
    return false;
#endif
}

void ApplicationController::authenticateWithBiometric() {
#ifdef Q_OS_ANDROID
    // CORREÇÃO: Resgatando a activity para uso dentro desta função
    QJniObject activity = QNativeInterface::QAndroidApplication::context();

    if (activity.isValid()) {
        // Chamar autenticação biométrica via JNI
        QJniObject::callStaticMethod<void>(
            "com/coin2x2/wallet/BiometricHelper",
            "authenticate",
            "(Landroid/app/Activity;)V",
            activity.object()
        );
    }
#else
    Q_EMIT biometricResult(false);
#endif
}

// ============================================================
// Notificações
// ============================================================
void ApplicationController::showNotification(const QString& title, const QString& message) {
#ifdef Q_OS_ANDROID
    QJniObject jTitle = QJniObject::fromString(title);
    QJniObject jMessage = QJniObject::fromString(message);
    
    // CORREÇÃO: Atualizado de queryActivity() para o padrão do Qt 6.5
    QJniObject activity = QNativeInterface::QAndroidApplication::context();

    if (activity.isValid()) {
        QJniObject::callStaticMethod<void>(
            "com/coin2x2/wallet/NotificationHelper",
            "showNotification",
            "(Landroid/app/Activity;Ljava/lang/String;Ljava/lang/String;)V",
            activity.object(),
            jTitle.object(),
            jMessage.object()
        );
    }
#else
    qDebug() << "Notificação:" << title << "-" << message;
#endif
}

} // namespace Coin2x2
