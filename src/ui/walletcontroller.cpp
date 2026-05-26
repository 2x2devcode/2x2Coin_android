// Copyright (c) 2026 - 2X2Coin Project
// Implementação da ponte UI ↔ core 2X2Coin

#include "walletcontroller.h"
#include "../wallet/walletmanager.h"
#include "../network/networkmanager.h"
#include "../core/chainparams.h"
#include "../core/base58.h"
#include <QQmlEngine>
#include <QJSEngine>
#include <QDebug>

namespace Coin2x2 {

WalletController* WalletController::s_instance = nullptr;

WalletController::WalletController(QObject* parent)
    : QObject(parent)
    , m_wallet(nullptr)
    , m_network(nullptr)
{
}

WalletController::~WalletController() {
    lock();
}

void WalletController::setInstance(WalletController* ctrl) {
    s_instance = ctrl;
}

WalletController* WalletController::instance() {
    return s_instance;
}

void WalletController::registerQmlTypes() {
    qmlRegisterSingletonType<WalletController>(
        "Coin2x2", 1, 0, "Wallet",
        [](QQmlEngine*, QJSEngine*) -> QObject* {
            if (s_instance) {
                return s_instance;
            }
            static WalletController fallback;
            return &fallback;
        });
}

void WalletController::bindManagers(WalletManager* wallet, NetworkManager* network) {
    m_wallet = wallet;
    m_network = network;
    connectManagerSignals();
}

void WalletController::connectManagerSignals() {
    if (!m_wallet) {
        return;
    }

    connect(m_wallet, &WalletManager::walletCreated, this,
            [this](const QStringList& words) { Q_EMIT walletCreated(words); });
    connect(m_wallet, &WalletManager::walletStateChanged, this, &WalletController::walletStateChanged);
    connect(m_wallet, &WalletManager::lockStateChanged, this, &WalletController::lockStateChanged);
    connect(m_wallet, &WalletManager::balanceChanged, this, &WalletController::balanceChanged);
    connect(m_wallet, &WalletManager::addressChanged, this, &WalletController::addressChanged);
    connect(m_wallet, &WalletManager::transactionSent, this, &WalletController::transactionSent);
    connect(m_wallet, &WalletManager::transactionFailed, this, &WalletController::transactionFailed);
    connect(m_wallet, &WalletManager::errorOccurred, this, &WalletController::errorOccurred);
    connect(m_wallet, &WalletManager::infoMessage, this, &WalletController::infoMessage);
    connect(m_wallet, &WalletManager::blockHeightChanged, this, &WalletController::blockHeightChanged);

    if (m_network) {
        connect(m_network, &NetworkManager::blockHeightChanged, this,
                [this](int, const QString&) { Q_EMIT blockHeightChanged(); });
    }
}

bool WalletController::hasWallet() const {
    return m_wallet && m_wallet->isInitialized();
}

bool WalletController::isLocked() const {
    return !m_wallet || m_wallet->isLocked();
}

QString WalletController::balance() const {
    if (!m_wallet) {
        return QStringLiteral("0 2X2");
    }
    return m_wallet->formatAmount(m_wallet->totalBalance(), true);
}

QString WalletController::receiveAddress() const {
    return m_wallet ? m_wallet->getReceiveAddress() : QString();
}

QString WalletController::networkLabel() const {
    return ChainParams::instance().isTestnet()
        ? QStringLiteral("Testnet")
        : QStringLiteral("Mainnet");
}

int WalletController::blockHeight() const {
    if (m_network) {
        return m_network->blockHeight();
    }
    return m_wallet ? m_wallet->blockHeight() : 0;
}

bool WalletController::isPoS() const {
    return blockHeight() > static_cast<int>(ChainParams::instance().lastPowBlock());
}

bool WalletController::createWallet(const QString& passphrase) {
    if (!m_wallet) {
        Q_EMIT errorOccurred(QStringLiteral("Carteira não inicializada"));
        return false;
    }
    return m_wallet->createWallet(passphrase);
}

bool WalletController::restoreFromMnemonic(const QString& mnemonic, const QString& passphrase) {
    if (!m_wallet) {
        return false;
    }
    return m_wallet->restoreWallet(mnemonic, passphrase);
}

bool WalletController::unlock(const QString& password) {
    return m_wallet && m_wallet->unlockWallet(password);
}

bool WalletController::lock() {
    if (m_wallet) {
        return m_wallet->lockWallet();
    }
    return true;
}

QStringList WalletController::mnemonicWords() {
    return m_wallet ? m_wallet->getMnemonic() : QStringList();
}

QString WalletController::newReceiveAddress(const QString& label) {
    return m_wallet ? m_wallet->generateNewAddress(label) : QString();
}

bool WalletController::validateAddress(const QString& address) const {
    if (address.isEmpty()) {
        return false;
    }

    const auto& params = ChainParams::instance();
    const uint8_t pkhPrefix = params.pubkeyAddressPrefix();

    if (Base58::isValidAddress(address, pkhPrefix)) {
        return true;
    }

    // Endereços script (P2SH) na mainnet usam prefixo 90
    return Base58::isValidAddress(address, params.scriptAddressPrefix());
}

QVariantList WalletController::addressBook() const {
    QVariantList out;
    if (!m_wallet) {
        return out;
    }

    for (const AddressRecord& rec : m_wallet->getAddresses()) {
        QVariantMap row;
        row[QStringLiteral("address")] = rec.address;
        row[QStringLiteral("label")] = rec.label;
        row[QStringLiteral("balance")] = m_wallet->formatAmount(rec.balance, true);
        row[QStringLiteral("isChange")] = rec.isChange;
        out.append(row);
    }
    return out;
}

QString WalletController::send(const QString& toAddress,
                               const QString& amountCoins,
                               const QString& feeCoins,
                               const QString& comment) {
    if (!m_wallet || m_wallet->isLocked()) {
        Q_EMIT transactionFailed(QStringLiteral("Desbloqueie a carteira antes de enviar"));
        return QString();
    }

    if (!validateAddress(toAddress)) {
        Q_EMIT transactionFailed(QStringLiteral("Endereço inválido para a rede 2X2Coin"));
        return QString();
    }

    const qint64 amountSats = parseCoins(amountCoins);
    if (amountSats <= 0) {
        Q_EMIT transactionFailed(QStringLiteral("Valor inválido"));
        return QString();
    }

    qint64 feeSats = 0;
    if (!feeCoins.isEmpty() && feeCoins != QStringLiteral("0")) {
        feeSats = parseCoins(feeCoins);
    } else {
        feeSats = m_wallet->estimateFee(toAddress, amountSats);
    }

    // Respeita maturidade e spacing do core ao validar saldo disponível
    const qint64 needed = amountSats + feeSats;
    if (needed > m_wallet->balance()) {
        Q_EMIT transactionFailed(QStringLiteral("Saldo insuficiente (inclua a taxa de rede)"));
        return QString();
    }

    return m_wallet->sendCoins(toAddress, amountSats, feeSats, comment);
}

QString WalletController::estimateNetworkFee(const QString& toAddress,
                                             const QString& amountCoins) const {
    if (!m_wallet) {
        return QStringLiteral("0 2X2");
    }
    const qint64 amountSats = parseCoins(amountCoins);
    const qint64 feeSats = m_wallet->estimateFee(toAddress, amountSats);
    return formatCoins(feeSats);
}

QVariantList WalletController::transactionHistory(int limit, int offset) const {
    QVariantList rows;
    if (!m_wallet) {
        return rows;
    }

    for (const TransactionRecord& tx : m_wallet->getTransactions(limit, offset)) {
        QVariantMap row;
        row[QStringLiteral("txid")] = tx.txid;
        row[QStringLiteral("address")] = tx.address;
        row[QStringLiteral("amount")] = tx.formattedAmount();
        row[QStringLiteral("fee")] = tx.formattedFee();
        row[QStringLiteral("confirmations")] = tx.confirmations;
        row[QStringLiteral("type")] = tx.type;
        row[QStringLiteral("status")] = tx.statusText();
        row[QStringLiteral("isReceived")] = tx.amount >= 0;
        rows.append(row);
    }
    return rows;
}

QString WalletController::exportWifForAddress(const QString& address) {
    if (!m_wallet || m_wallet->isLocked()) {
        Q_EMIT errorOccurred(QStringLiteral("Carteira bloqueada"));
        return QString();
    }

    // WalletManager já deriva a chave; reforçamos política de não logar material sensível
    const QString wif = m_wallet->exportPrivateKey(address, QString());
    if (wif.isEmpty()) {
        Q_EMIT errorOccurred(QStringLiteral("Endereço não encontrado na carteira"));
    }
    return wif;
}

QVariantMap WalletController::chainInfo() const {
    const auto& p = ChainParams::instance();
    QVariantMap info;
    info[QStringLiteral("networkId")] = p.networkId();
    info[QStringLiteral("cashaddrPrefix")] = p.cashaddrPrefix();
    info[QStringLiteral("pubkeyPrefix")] = p.pubkeyAddressPrefix();
    info[QStringLiteral("scriptPrefix")] = p.scriptAddressPrefix();
    info[QStringLiteral("secretPrefix")] = p.secretKeyPrefix();
    info[QStringLiteral("defaultPort")] = p.defaultPort();
    info[QStringLiteral("targetSpacing")] = p.targetSpacing();
    info[QStringLiteral("lastPowBlock")] = p.lastPowBlock();
    info[QStringLiteral("coinbaseMaturity")] = p.coinbaseMaturity();
    info[QStringLiteral("stakeMinAge")] = p.stakeMinAge();
    info[QStringLiteral("dnsSeeds")] = p.dnsSeeds();
    info[QStringLiteral("genesisHash")] = QString::fromLatin1(MainNetParams::GENESIS_HASH);
    return info;
}

int WalletController::lastPowBlock() const {
    return static_cast<int>(ChainParams::instance().lastPowBlock());
}

int WalletController::targetSpacingSeconds() const {
    return static_cast<int>(ChainParams::instance().targetSpacing());
}

qint64 WalletController::parseCoins(const QString& amount) const {
    return m_wallet ? m_wallet->parseAmount(amount) : 0;
}

QString WalletController::formatCoins(qint64 satoshis) const {
    return m_wallet ? m_wallet->formatAmount(satoshis, true)
                    : QStringLiteral("0 2X2");
}

} // namespace Coin2x2
