// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Implementação do Gerenciador de Rede para 2X2Coin

#include "networkmanager.h"
#include "../core/chainparams.h"
#include <QJsonArray>
#include <QJsonValue>
#include <QHostInfo>
#include <QAuthenticator>
#include <QSslConfiguration>
#include <QDebug>
#include <QRandomGenerator>

namespace Coin2x2 {

NetworkManager* NetworkManager::s_instance = nullptr;

NetworkManager& NetworkManager::instance() {
    if (!s_instance) {
        s_instance = new NetworkManager();
    }
    return *s_instance;
}

NetworkManager::NetworkManager(QObject* parent)
    : QObject(parent)
    , m_connected(false)
    , m_syncing(false)
    , m_peerCount(0)
    , m_blockHeight(0)
    , m_syncProgress(0.0)
    , m_rpcHost("127.0.0.1")
    , m_rpcPort(15190)
    , m_rpcUser("2x2coinrpc")
    , m_rpcPassword("2x2coinpass")
    , m_networkAccess(new QNetworkAccessManager(this))
    , m_pollTimer(new QTimer(this))
    , m_rpcIdCounter(0)
{
    // Configurar polling periódico (a cada 30 segundos)
    connect(m_pollTimer, &QTimer::timeout, this, &NetworkManager::onPollTimer);
    m_pollTimer->setInterval(30000);

    // Conectar sinais de rede
    connect(m_networkAccess, &QNetworkAccessManager::finished,
            this, &NetworkManager::onRpcReplyFinished);
}

NetworkManager::~NetworkManager() {
    m_pollTimer->stop();
}

void NetworkManager::setRpcHost(const QString& host) {
    m_rpcHost = host;
    Q_EMIT rpcConfigChanged();
}

void NetworkManager::setRpcPort(int port) {
    m_rpcPort = port;
    Q_EMIT rpcConfigChanged();
}

void NetworkManager::setRpcCredentials(const QString& user, const QString& password) {
    m_rpcUser = user;
    m_rpcPassword = password;
}

QString NetworkManager::rpcUrl() const {
    return QString("http://%1:%2/").arg(m_rpcHost).arg(m_rpcPort);
}

QNetworkRequest NetworkManager::buildRpcRequest() const {
    QNetworkRequest request{QUrl(rpcUrl())};
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // Autenticação básica
    QString credentials = m_rpcUser + ":" + m_rpcPassword;
    QString encoded = "Basic " + QString(credentials.toUtf8().toBase64());
    request.setRawHeader("Authorization", encoded.toUtf8());

    return request;
}

void NetworkManager::connectToNetwork() {
    qDebug() << "2X2Coin: Conectando à rede...";

    // Tentar descobrir peers via DNS
    discoverPeers();

    // Iniciar polling
    m_pollTimer->start();

    // Fazer primeira consulta
    getBlockCount();
}

void NetworkManager::disconnectFromNetwork() {
    m_pollTimer->stop();
    m_connected = false;
    m_peerCount = 0;
    Q_EMIT connectionStateChanged(false);
    Q_EMIT peerCountChanged(0);
}

void NetworkManager::reconnect() {
    disconnectFromNetwork();
    QTimer::singleShot(2000, this, &NetworkManager::connectToNetwork);
}

void NetworkManager::discoverPeers() {
    QStringList seeds = ChainParams::instance().dnsSeeds();

    for (const QString& seed : seeds) {
        // Verificar se é IP direto ou hostname
        QHostAddress addr(seed);
        if (!addr.isNull()) {
            m_discoveredPeers.append(seed);
        } else {
            // Resolver DNS
            QHostInfo::lookupHost(seed, this, [this, seed](const QHostInfo& info) {
                if (info.error() == QHostInfo::NoError) {
                    for (const QHostAddress& addr : info.addresses()) {
                        QString ip = addr.toString();
                        if (!m_discoveredPeers.contains(ip)) {
                            m_discoveredPeers.append(ip);
                            qDebug() << "2X2Coin: Peer descoberto:" << ip;
                        }
                    }
                }
            });
        }
    }
}

void NetworkManager::rpcCall(const QString& method, const QJsonArray& params,
                              std::function<void(const QJsonObject&)> callback) {
    int id = ++m_rpcIdCounter;

    QJsonObject request;
    request["jsonrpc"] = "1.1";
    request["id"] = id;
    request["method"] = method;
    request["params"] = params;

    QByteArray body = QJsonDocument(request).toJson(QJsonDocument::Compact);

    QNetworkRequest netRequest = buildRpcRequest();
    QNetworkReply* reply = m_networkAccess->post(netRequest, body);

    // Armazenar callback
    if (callback) {
        m_pendingCallbacks[id] = callback;
        // Associar ID ao reply
        reply->setProperty("rpc_id", id);
    }

    connect(reply, &QNetworkReply::errorOccurred, this,
            [this, method](QNetworkReply::NetworkError error) {
        Q_UNUSED(error)
        if (!m_connected) {
            m_connected = false;
            Q_EMIT connectionStateChanged(false);
        }
        Q_EMIT networkError(QString("Erro de rede ao chamar %1").arg(method));
    });
}

void NetworkManager::onRpcReplyFinished(QNetworkReply* reply) {
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        return;
    }

    // Marcar como conectado na primeira resposta bem-sucedida
    if (!m_connected) {
        m_connected = true;
        Q_EMIT connectionStateChanged(true);
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) return;

    QJsonObject response = doc.object();

    // Verificar erro RPC
    if (!response["error"].isNull() && !response["error"].isUndefined()) {
        QJsonObject error = response["error"].toObject();
        Q_EMIT rpcError(error["code"].toInt(), error["message"].toString());
        return;
    }

    // Executar callback
    int id = reply->property("rpc_id").toInt();
    if (m_pendingCallbacks.contains(id)) {
        QJsonObject result = response["result"].toObject();
        m_pendingCallbacks[id](result);
        m_pendingCallbacks.remove(id);
    }
}

void NetworkManager::getBlockCount() {
    rpcCall("getblockcount", QJsonArray(), [this](const QJsonObject& result) {
        int height = result.isEmpty() ? 0 : result.begin()->toInt();
        if (height != m_blockHeight) {
            m_blockHeight = height;
            Q_EMIT blockHeightChanged(height, "");
        }
    });
}

void NetworkManager::getBlockInfo(int height) {
    QJsonArray params;
    params.append(height);

    rpcCall("getblockhash", params, [this, height](const QJsonObject& hashResult) {
        QString hash = hashResult.isEmpty() ? "" : hashResult.begin()->toString();

        QJsonArray params2;
        params2.append(hash);
        params2.append(true);

        rpcCall("getblock", params2, [this](const QJsonObject& blockResult) {
            BlockInfo info;
            info.height = blockResult["height"].toInt();
            info.hash   = blockResult["hash"].toString();
            info.time   = blockResult["time"].toInt();
            info.bits   = blockResult["bits"].toString().toUInt(nullptr, 16);
            info.nonce  = blockResult["nonce"].toInt();
            info.txCount = blockResult["tx"].toArray().size();
            info.isPoS  = blockResult["flags"].toString().contains("proof-of-stake");
            info.difficulty = blockResult["difficulty"].toDouble();
            Q_EMIT blockInfoReceived(info);
        });
    });
}

void NetworkManager::getBalance(const QString& address) {
    // Usar listunspent para calcular saldo
    QJsonArray params;
    params.append(0);      // minconf
    params.append(999999); // maxconf
    QJsonArray addrs;
    addrs.append(address);
    params.append(addrs);

    rpcCall("listunspent", params, [this, address](const QJsonObject& result) {
        Q_UNUSED(result)
        // Processar UTXOs e calcular saldo
        qint64 confirmed = 0;
        qint64 unconfirmed = 0;
        Q_EMIT balanceReceived(address, confirmed, unconfirmed);
    });
}

void NetworkManager::getTransaction(const QString& txid) {
    QJsonArray params;
    params.append(txid);
    params.append(true);

    rpcCall("getrawtransaction", params, [this](const QJsonObject& result) {
        Q_EMIT transactionReceived(result);
    });
}

void NetworkManager::getPeerInfo() {
    rpcCall("getpeerinfo", QJsonArray(), [this](const QJsonObject& result) {
        Q_UNUSED(result)
        QList<PeerInfo> peers;
        // Parsear informações dos peers
        Q_EMIT peerInfoReceived(peers);
    });
}

void NetworkManager::getNetworkInfo() {
    rpcCall("getnetworkinfo", QJsonArray(), [this](const QJsonObject& result) {
        m_peerCount = result["connections"].toInt();
        Q_EMIT networkInfoReceived(result);
        Q_EMIT peerCountChanged(m_peerCount);
    });
}

void NetworkManager::getMempoolInfo() {
    rpcCall("getmempoolinfo", QJsonArray(), [this](const QJsonObject& result) {
        Q_UNUSED(result)
    });
}

void NetworkManager::sendRawTransaction(const QString& rawTx) {
    QJsonArray params;
    params.append(rawTx);

    rpcCall("sendrawtransaction", params, [this](const QJsonObject& result) {
        QString txid = result.isEmpty() ? "" : result.begin()->toString();
        Q_EMIT rawTransactionSent(txid);
    });
}

void NetworkManager::broadcastTransaction(const QByteArray& txData) {
    sendRawTransaction(QString(txData.toHex()));
}

void NetworkManager::estimateFee(int targetBlocks) {
    QJsonArray params;
    params.append(targetBlocks);

    rpcCall("estimatefee", params, [this](const QJsonObject& result) {
        double feePerKb = result.isEmpty() ? 0.001 : result.begin()->toDouble();
        qint64 feePerKbSatoshis = static_cast<qint64>(feePerKb * 100000000.0);
        Q_EMIT feeEstimateReceived(feePerKbSatoshis);
    });
}

void NetworkManager::getStakingInfo() {
    rpcCall("getstakinginfo", QJsonArray(), [this](const QJsonObject& result) {
        Q_EMIT stakingInfoReceived(result);
    });
}

void NetworkManager::onPollTimer() {
    if (!m_connected) {
        connectToNetwork();
        return;
    }

    getBlockCount();
    getNetworkInfo();
}

void NetworkManager::onDnsLookupFinished() {
    // Processado via lambda em discoverPeers()
}

QString NetworkManager::getExplorerUrl(const QString& txid) const {
    return QString("%1/tx/%2").arg(EXPLORER_BASE).arg(txid);
}

QString NetworkManager::getAddressExplorerUrl(const QString& address) const {
    return QString("%1/address/%2").arg(EXPLORER_BASE).arg(address);
}

} // namespace Coin2x2
