// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Gerenciador de rede para comunicação com nós 2X2Coin
// Suporta conexão P2P e JSON-RPC com o daemon 2x2coind

#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTcpSocket>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QTimer>
#include <QJsonObject>
#include <QJsonDocument>
#include <memory>

namespace Coin2x2 {

// ============================================================
// Informações de um peer da rede
// ============================================================
struct PeerInfo {
    QString address;
    uint16_t port;
    int version;
    QString subversion;
    int64_t startingHeight;
    bool connected;
    qint64 bytesReceived;
    qint64 bytesSent;
};

// ============================================================
// Informações do bloco atual
// ============================================================
struct BlockInfo {
    int height;
    QString hash;
    uint32_t time;
    uint32_t bits;
    uint32_t nonce;
    int txCount;
    bool isPoS;
    double difficulty;
};

// ============================================================
// Gerenciador de Rede 2X2Coin
// ============================================================
class NetworkManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isConnected   READ isConnected   NOTIFY connectionStateChanged)
    Q_PROPERTY(int  peerCount     READ peerCount     NOTIFY peerCountChanged)
    Q_PROPERTY(int  blockHeight   READ blockHeight   NOTIFY blockHeightChanged)
    Q_PROPERTY(bool isSyncing     READ isSyncing     NOTIFY syncStateChanged)
    Q_PROPERTY(double syncProgress READ syncProgress NOTIFY syncProgressChanged)
    Q_PROPERTY(QString rpcHost    READ rpcHost       WRITE setRpcHost    NOTIFY rpcConfigChanged)
    Q_PROPERTY(int    rpcPort     READ rpcPort       WRITE setRpcPort    NOTIFY rpcConfigChanged)

public:
    explicit NetworkManager(QObject* parent = nullptr);
    ~NetworkManager();

    static NetworkManager& instance();

    // Estado da conexão
    bool isConnected() const { return m_connected; }
    bool isSyncing() const { return m_syncing; }
    int peerCount() const { return m_peerCount; }
    int blockHeight() const { return m_blockHeight; }
    double syncProgress() const { return m_syncProgress; }

    // Configuração RPC
    QString rpcHost() const { return m_rpcHost; }
    int rpcPort() const { return m_rpcPort; }
    void setRpcHost(const QString& host);
    void setRpcPort(int port);
    void setRpcCredentials(const QString& user, const QString& password);

    // Conexão
    Q_INVOKABLE void connectToNetwork();
    Q_INVOKABLE void disconnectFromNetwork();
    Q_INVOKABLE void reconnect();

    // Consultas de blockchain
    Q_INVOKABLE void getBlockCount();
    Q_INVOKABLE void getBlockInfo(int height);
    Q_INVOKABLE void getBalance(const QString& address);
    Q_INVOKABLE void getTransaction(const QString& txid);
    Q_INVOKABLE void getPeerInfo();
    Q_INVOKABLE void getNetworkInfo();
    Q_INVOKABLE void getMempoolInfo();

    // Envio de transação
    Q_INVOKABLE void sendRawTransaction(const QString& rawTx);
    Q_INVOKABLE void broadcastTransaction(const QByteArray& txData);

    // Estimativa de taxa
    Q_INVOKABLE void estimateFee(int targetBlocks = 6);

    // Informações de staking
    Q_INVOKABLE void getStakingInfo();

    // DNS Seeds - descoberta de peers
    Q_INVOKABLE void discoverPeers();

    // Utilitários
    Q_INVOKABLE QString getExplorerUrl(const QString& txid) const;
    Q_INVOKABLE QString getAddressExplorerUrl(const QString& address) const;

Q_SIGNALS:
    void connectionStateChanged(bool connected);
    void peerCountChanged(int count);
    void blockHeightChanged(int height, const QString& hash);
    void syncStateChanged(bool syncing);
    void syncProgressChanged(double progress);
    void rpcConfigChanged();

    // Dados recebidos
    void blockInfoReceived(const BlockInfo& info);
    void balanceReceived(const QString& address, qint64 confirmed, qint64 unconfirmed);
    void transactionReceived(const QJsonObject& txData);
    void peerInfoReceived(const QList<PeerInfo>& peers);
    void networkInfoReceived(const QJsonObject& info);
    void feeEstimateReceived(qint64 feePerKb);
    void stakingInfoReceived(const QJsonObject& info);
    void rawTransactionSent(const QString& txid);

    // Erros
    void networkError(const QString& error);
    void rpcError(int code, const QString& message);

private Q_SLOTS:
    void onPollTimer();
    void onRpcReplyFinished(QNetworkReply* reply);
    void onDnsLookupFinished();

private:
    // Chamada RPC genérica
    void rpcCall(const QString& method, const QJsonArray& params,
                 std::function<void(const QJsonObject&)> callback);

    // Construir URL RPC
    QString rpcUrl() const;
    QNetworkRequest buildRpcRequest() const;

    // Parsear respostas
    void parseBlockCountResponse(const QJsonObject& result);
    void parseBlockInfoResponse(const QJsonObject& result);
    void parsePeerInfoResponse(const QJsonArray& result);
    void parseNetworkInfoResponse(const QJsonObject& result);

    // Estado
    bool    m_connected;
    bool    m_syncing;
    int     m_peerCount;
    int     m_blockHeight;
    double  m_syncProgress;

    // Configuração RPC
    QString m_rpcHost;
    int     m_rpcPort;
    QString m_rpcUser;
    QString m_rpcPassword;

    // Rede
    QNetworkAccessManager* m_networkAccess;
    QTimer* m_pollTimer;

    // Callbacks pendentes
    QMap<int, std::function<void(const QJsonObject&)>> m_pendingCallbacks;
    int m_rpcIdCounter;

    // Peers descobertos
    QStringList m_discoveredPeers;

    // Singleton
    static NetworkManager* s_instance;

    // URLs do explorador
    static constexpr const char* EXPLORER_BASE = "https://newexplorer.2x2coin.com";
};

} // namespace Coin2x2
