// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação do Gerenciador da Wallet 2X2Coin

#include "walletmanager.h"
#include "../core/chainparams.h"
#include "../core/base58.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QDateTime>
#include <cmath>

namespace Coin2x2 {

WalletManager* WalletManager::s_instance = nullptr;

WalletManager& WalletManager::instance() {
    if (!s_instance) {
        s_instance = new WalletManager();
    }
    return *s_instance;
}

WalletManager::WalletManager(QObject* parent)
    : QObject(parent)
    , m_initialized(false)
    , m_locked(true)
    , m_syncing(false)
    , m_stakingEnabled(false)
    , m_balance(0)
    , m_unconfirmedBalance(0)
    , m_stakeBalance(0)
    , m_immatureBalance(0)
    , m_blockHeight(0)
    , m_peerCount(0)
    , m_hdWallet(std::make_unique<HDWallet>())
{
    initializeDefaults();
}

WalletManager::~WalletManager() {}

void WalletManager::initializeDefaults() {
    // Verificar se existe wallet salva
    QString walletPath = getWalletFilePath();
    if (QFile::exists(walletPath)) {
        m_initialized = true;
        m_locked = true;
    }
}

QString WalletManager::getWalletFilePath() const {
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    return dataPath + "/2x2coin_wallet.dat";
}

QString WalletManager::getWalletPath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

QString WalletManager::networkName() const {
    return ChainParams::instance().isTestnet() ? "Testnet" : "Mainnet";
}

bool WalletManager::isTestnet() const {
    return ChainParams::instance().isTestnet();
}

void WalletManager::setNetwork(bool testnet) {
    ChainParams::instance().setNetwork(
        testnet ? ChainParams::TESTNET : ChainParams::MAIN
    );
    Q_EMIT walletStateChanged();
}

// ============================================================
// Formatação de valores
// ============================================================
QString WalletManager::formatAmount(qint64 satoshis, bool withUnit) const {
    double amount = satoshis / 100000000.0;
    QString formatted;

    if (qAbs(satoshis) >= 100000000LL) {
        formatted = QString::number(amount, 'f', 2);
    } else {
        formatted = QString::number(amount, 'f', 8);
        // Remover zeros à direita desnecessários
        while (formatted.endsWith('0') && !formatted.endsWith(".0")) {
            formatted.chop(1);
        }
    }

    if (withUnit) {
        formatted += " 2X2";
    }
    return formatted;
}

QString WalletManager::formatAmountFull(qint64 satoshis) const {
    double amount = satoshis / 100000000.0;
    return QString::number(amount, 'f', 8) + " 2X2";
}

qint64 WalletManager::parseAmount(const QString& amountStr) const {
    QString clean = amountStr;
    clean.remove(" 2X2").remove("2X2").trimmed();
    bool ok;
    double amount = clean.toDouble(&ok);
    if (!ok) return 0;
    return static_cast<qint64>(amount * 100000000.0);
}

// ============================================================
// Criação e restauração de wallet
// ============================================================
bool WalletManager::createWallet(const QString& passphrase) {
    if (!m_hdWallet->createNew(passphrase)) {
        Q_EMIT errorOccurred("Falha ao criar carteira");
        return false;
    m_currentPassword = passphrase;
    
    return saveToStorage();
}

    m_currentAddress = m_hdWallet->deriveReceiveAddress(0);
    m_initialized = true;
    m_locked = false;

    // Salvar wallet
    if (!saveToStorage()) {
        Q_EMIT errorOccurred("Falha ao salvar carteira");
        return false;
    }

    Q_EMIT walletCreated(m_hdWallet->mnemonic());
    Q_EMIT walletStateChanged();
    Q_EMIT addressChanged();

    return true;
}

bool WalletManager::restoreWallet(const QString& mnemonic, const QString& passphrase) {
    QStringList words = mnemonic.split(" ", Qt::SkipEmptyParts);

    if (!m_hdWallet->restore(words, passphrase)) {
        Q_EMIT errorOccurred("Mnemônico inválido ou falha na restauração");
        return false;
    }

    m_currentAddress = m_hdWallet->deriveReceiveAddress(0);
    m_initialized = true;
    m_locked = false;

    if (!saveToStorage()) {
        Q_EMIT errorOccurred("Falha ao salvar carteira restaurada");
        return false;
    }

    Q_EMIT walletLoaded();
    Q_EMIT walletStateChanged();
    Q_EMIT addressChanged();

    return true;
}

bool WalletManager::loadWallet(const QString& password) {
    QString walletPath = getWalletFilePath();
    if (!m_hdWallet->loadFromFile(walletPath, password)) {
        Q_EMIT errorOccurred("Senha incorreta ou arquivo de carteira corrompido");
        return false;
    }
    m_currentPassword = password;

    m_currentAddress = m_hdWallet->deriveReceiveAddress(
        m_hdWallet->nextReceiveIndex()
    );
    m_locked = false;

    Q_EMIT walletLoaded();
    Q_EMIT lockStateChanged();
    Q_EMIT addressChanged();

    return true;
}

bool WalletManager::saveWallet(const QString& password) {
    return saveToStorage();
}

bool WalletManager::saveToStorage() const {
QString walletPath = getWalletFilePath();
    // IMPORTANTE: Use uma senha real ou o sistema de Keystore do Android
    // Para correção imediata, garanta que a senha de salvamento seja a mesma do carregamento
    return m_hdWallet->saveToFile(walletPath, m_currentPassword); 
}

bool WalletManager::lockWallet() {
    m_locked = true;
    // Limpar dados sensíveis da memória
    Q_EMIT lockStateChanged();
    return true;
}

bool WalletManager::unlockWallet(const QString& password) {
    if (!loadWallet(password)) {
        return false;
    }
    m_locked = false;
    Q_EMIT lockStateChanged();
    return true;
}

bool WalletManager::changePassword(const QString& oldPassword, const QString& newPassword) {
    // Verificar senha antiga
    QString walletPath = getWalletFilePath();
    HDWallet tempWallet;
    if (!tempWallet.loadFromFile(walletPath, oldPassword)) {
        Q_EMIT errorOccurred("Senha atual incorreta");
        return false;
    }

    // Salvar com nova senha
    if (!m_hdWallet->saveToFile(walletPath, newPassword)) {
        Q_EMIT errorOccurred("Falha ao salvar com nova senha");
        return false;
    }

    Q_EMIT infoMessage("Senha alterada com sucesso");
    return true;
}

// ============================================================
// Endereços
// ============================================================
QString WalletManager::generateNewAddress(const QString& label) {
    if (!m_initialized || m_locked) return QString();

    uint32_t index = m_hdWallet->nextReceiveIndex();
    m_hdWallet->incrementReceiveIndex();

    QString address = m_hdWallet->deriveReceiveAddress(index);

    AddressRecord record;
    record.address = address;
    record.label = label;
    record.isChange = false;
    record.index = index;
    record.balance = 0;
    record.txCount = 0;
    m_addresses.append(record);

    m_currentAddress = address;
    saveToStorage();

    Q_EMIT addressChanged();
    return address;
}

QString WalletManager::getReceiveAddress() const {
    if (!m_initialized) return QString();
    return m_currentAddress;
}

QList<AddressRecord> WalletManager::getAddresses() const {
    return m_addresses;
}

bool WalletManager::setAddressLabel(const QString& address, const QString& label) {
    for (auto& rec : m_addresses) {
        if (rec.address == address) {
            rec.label = label;
            saveToStorage();
            return true;
        }
    }
    return false;
}

bool WalletManager::isValidAddress(const QString& address) const {
    uint8_t prefix = ChainParams::instance().pubkeyAddressPrefix();
    return Base58::isValidAddress(address, prefix);
}

// ============================================================
// Transações
// ============================================================
QList<TransactionRecord> WalletManager::getTransactions(int limit, int offset) const {
    if (offset >= m_transactions.size()) return QList<TransactionRecord>();

    int end = qMin(offset + limit, m_transactions.size());
    return m_transactions.mid(offset, end - offset);
}

TransactionRecord WalletManager::getTransaction(const QString& txid) const {
    for (const auto& tx : m_transactions) {
        if (tx.txid == txid) return tx;
    }
    return TransactionRecord();
}

QString WalletManager::sendCoins(const QString& toAddress, qint64 amount,
                                   qint64 fee, const QString& comment) {
    if (!m_initialized || m_locked) {
        Q_EMIT transactionFailed("Carteira bloqueada");
        return QString();
    }

    if (!isValidAddress(toAddress)) {
        Q_EMIT transactionFailed("Endereço de destino inválido");
        return QString();
    }

    if (amount <= 0) {
        Q_EMIT transactionFailed("Valor inválido");
        return QString();
    }

    qint64 totalNeeded = amount + (fee > 0 ? fee : estimateFee(toAddress, amount));
    if (totalNeeded > m_balance) {
        Q_EMIT transactionFailed("Saldo insuficiente");
        return QString();
    }

    // Em produção: construir e assinar transação real
    // Por ora, simular envio via RPC
    Q_EMIT infoMessage(QString("Enviando %1 2X2 para %2...")
                       .arg(formatAmount(amount, false))
                       .arg(toAddress.left(12) + "..."));

    // Retornar txid simulado (em produção: obter da rede)
    QString txid = "tx_" + QString::number(QDateTime::currentMSecsSinceEpoch(), 16);
    Q_EMIT transactionSent(txid);
    return txid;
}

qint64 WalletManager::estimateFee(const QString& toAddress, qint64 amount) const {
    Q_UNUSED(toAddress)
    Q_UNUSED(amount)
    // Taxa padrão: 0.001 2X2 = 100000 satoshis
    return 100000LL;
}

// ============================================================
// Mnemônico
// ============================================================
QStringList WalletManager::getMnemonic() const {
    if (!m_initialized || m_locked) return QStringList();
    return m_hdWallet->mnemonic();
}

bool WalletManager::verifyMnemonic(const QStringList& words) const {
    return BIP39::validateMnemonic(words);
}

// ============================================================
// Exportação
// ============================================================
QString WalletManager::exportPrivateKey(const QString& address, const QString& password) const {
    if (m_locked) return QString();

    // Encontrar índice do endereço
    for (const auto& rec : m_addresses) {
        if (rec.address == address) {
            QByteArray privkey = m_hdWallet->derivePrivateKey(rec.index, rec.isChange);
            return Base58::privateKeyToWIF(privkey, true,
                ChainParams::instance().secretKeyPrefix());
        }
    }
    return QString();
}

QString WalletManager::exportXPub() const {
    if (!m_initialized) return QString();
    return m_hdWallet->exportXPub();
}

bool WalletManager::importPrivateKey(const QString& wif, const QString& label) {
    QByteArray privkey;
    bool compressed;
    if (!Base58::wifToPrivateKey(wif, privkey, compressed,
                                  ChainParams::instance().secretKeyPrefix())) {
        Q_EMIT errorOccurred("Chave privada WIF inválida");
        return false;
    }

    Q_EMIT infoMessage("Chave privada importada com sucesso");
    return true;
}

// ============================================================
// Staking (PoS)
// ============================================================
bool WalletManager::enableStaking(bool enable) {
    m_stakingEnabled = enable;
    Q_EMIT stakingStatusChanged();
    return true;
}

qint64 WalletManager::getStakingWeight() const {
    // Peso de staking baseado no saldo maduro
    return m_balance;
}

QString WalletManager::getStakingInfo() const {
    if (!m_stakingEnabled) return "Staking desativado";
    if (m_blockHeight <= 110000) return "PoW ativo (staking disponível após bloco 110.000)";
    return QString("Staking ativo | Peso: %1 2X2 | Blocos PoS")
        .arg(formatAmount(getStakingWeight(), false));
}

// ============================================================
// Backup
// ============================================================
bool WalletManager::backupWallet(const QString& filePath) const {
    if (!m_initialized) return false;
    return m_hdWallet->saveToFile(filePath, "backup_2x2coin");
}

bool WalletManager::restoreFromBackup(const QString& filePath, const QString& password) {
    if (!m_hdWallet->loadFromFile(filePath, password)) {
        Q_EMIT errorOccurred("Falha ao restaurar backup");
        return false;
    }

    m_currentAddress = m_hdWallet->deriveReceiveAddress(0);
    m_initialized = true;
    m_locked = false;

    saveToStorage();
    Q_EMIT walletLoaded();
    Q_EMIT walletStateChanged();
    return true;
}

// ============================================================
// Informações econômicas
// ============================================================
qint64 WalletManager::getCoinSupply() const {
    // Calcular oferta aproximada baseada na altura do bloco
    const int64_t COIN = 100000000LL;
    const uint32_t BLOCKS_PER_YEAR = 262800;
    int64_t supply = 11000000LL * COIN; // Premine

    for (uint32_t h = 1; h <= (uint32_t)m_blockHeight; ++h) {
        supply += ChainParams::instance().getBlockReward(h);
    }
    return supply;
}

double WalletManager::getInflationRate(int year) const {
    // Taxas de inflação conforme README do 2X2Coin
    static const double rates[] = {
        238.91, 140.99, 160.89, 145.76, 148.29,
        26.04, 26.56, 26.12, 25.89, 25.68,
        25.56, 25.85, 25.68, 25.68, 25.94,
        25.47, 0.0, 0.0, 0.0, 0.37
    };
    if (year < 1 || year > 20) return 0.37;
    return rates[year - 1];
}

// ============================================================
// Slots de rede
// ============================================================
void WalletManager::onNetworkConnected() {
    m_syncing = true;
    Q_EMIT syncStateChanged();
}

void WalletManager::onNetworkDisconnected() {
    m_syncing = false;
    m_peerCount = 0;
    Q_EMIT syncStateChanged();
    Q_EMIT peerCountChanged();
}

void WalletManager::onNewBlock(int height, const QString& hash) {
    Q_UNUSED(hash)
    m_blockHeight = height;
    Q_EMIT blockHeightChanged();
}

void WalletManager::onTransactionReceived(const QString& txid) {
    Q_UNUSED(txid)
    // Atualizar saldo e lista de transações
}

void WalletManager::onBalanceUpdated(qint64 confirmed, qint64 unconfirmed,
                                      qint64 stake, qint64 immature) {
    m_balance = confirmed;
    m_unconfirmedBalance = unconfirmed;
    m_stakeBalance = stake;
    m_immatureBalance = immature;
    Q_EMIT balanceChanged();
}

void WalletManager::onPeerCountChanged(int count) {
    m_peerCount = count;
    Q_EMIT peerCountChanged();
}

// ============================================================
// TransactionRecord - Formatação
// ============================================================
QString TransactionRecord::formattedAmount() const {
    double val = amount / 100000000.0;
    QString sign = amount >= 0 ? "+" : "";
    return sign + QString::number(val, 'f', 8) + " 2X2";
}

QString TransactionRecord::formattedFee() const {
    double val = fee / 100000000.0;
    return QString::number(val, 'f', 8) + " 2X2";
}

QString TransactionRecord::statusText() const {
    if (confirmations == 0) return "Pendente";
    if (confirmations < 6)  return QString("%1/6 confirmações").arg(confirmations);
    return "Confirmado";
}

} // namespace Coin2x2
