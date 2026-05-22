#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QString>
#include <QSettings>

namespace Coin2x2 {

class AppSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY themeChanged)
    Q_PROPERTY(bool notifications READ notifications WRITE setNotifications NOTIFY settingsChanged)
    Q_PROPERTY(bool biometric READ biometric WRITE setBiometric NOTIFY settingsChanged)
    Q_PROPERTY(bool testnet READ testnet WRITE setTestnet NOTIFY networkChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY settingsChanged)
    Q_PROPERTY(QString currency READ currency WRITE setCurrency NOTIFY settingsChanged)
    Q_PROPERTY(QString rpcHost READ rpcHost WRITE setRpcHost NOTIFY rpcChanged)
    Q_PROPERTY(int rpcPort READ rpcPort WRITE setRpcPort NOTIFY rpcChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    Q_INVOKABLE void load();
    Q_INVOKABLE void save();
    Q_INVOKABLE void reset();

    bool darkTheme() const;
    void setDarkTheme(bool v);

    bool notifications() const;
    void setNotifications(bool v);

    bool biometric() const;
    void setBiometric(bool v);

    bool testnet() const;
    void setTestnet(bool v);

    QString language() const;
    void setLanguage(const QString &v);

    QString currency() const;
    void setCurrency(const QString &v);

    QString rpcHost() const;
    void setRpcHost(const QString &v);

    int rpcPort() const;
    void setRpcPort(int v);

signals:
    void themeChanged();
    void settingsChanged();
    void networkChanged();
    void rpcChanged();

private:
    bool m_darkTheme;
    bool m_notifications;
    bool m_biometric;
    bool m_testnet;
    QString m_language;
    QString m_currency;
    QString m_rpcHost;
    int m_rpcPort;
};

} // namespace Coin2x2

#endif
