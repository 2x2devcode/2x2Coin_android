#include "settings.h"
#include <QSettings>

namespace Coin2x2 {

AppSettings::AppSettings(QObject *parent) : QObject(parent) {
    load();
}

void AppSettings::load() {
    QSettings s;
    m_darkTheme = s.value("darkTheme", true).toBool();
    m_notifications = s.value("notifications", true).toBool();
    m_biometric = s.value("biometric", false).toBool();
    m_testnet = s.value("testnet", false).toBool();
    m_language = s.value("language", "pt_BR").toString();
    m_currency = s.value("currency", "USD").toString();
    m_rpcHost = s.value("rpcHost", "seed.2x2coin.com").toString();
    m_rpcPort = s.value("rpcPort", 15190).toInt();
}

void AppSettings::save() {
    QSettings s;
    s.setValue("darkTheme", m_darkTheme);
    s.setValue("notifications", m_notifications);
    s.setValue("biometric", m_biometric);
    s.setValue("testnet", m_testnet);
    s.setValue("language", m_language);
    s.setValue("currency", m_currency);
    s.setValue("rpcHost", m_rpcHost);
    s.setValue("rpcPort", m_rpcPort);
}

void AppSettings::reset() {
    m_darkTheme = true;
    m_notifications = true;
    m_biometric = false;
    m_testnet = false;
    m_language = "pt_BR";
    m_currency = "USD";
    m_rpcHost = "seed.2x2coin.com";
    m_rpcPort = 15190;
    save();
    emit themeChanged();
    emit settingsChanged();
    emit networkChanged();
    emit rpcChanged();
}

// Getters e Setters
bool AppSettings::darkTheme() const { return m_darkTheme; }
void AppSettings::setDarkTheme(bool v) { if(m_darkTheme != v) { m_darkTheme = v; emit themeChanged(); } }

bool AppSettings::notifications() const { return m_notifications; }
void AppSettings::setNotifications(bool v) { if(m_notifications != v) { m_notifications = v; emit settingsChanged(); } }

bool AppSettings::biometric() const { return m_biometric; }
void AppSettings::setBiometric(bool v) { if(m_biometric != v) { m_biometric = v; emit settingsChanged(); } }

bool AppSettings::testnet() const { return m_testnet; }
void AppSettings::setTestnet(bool v) { if(m_testnet != v) { m_testnet = v; emit networkChanged(); } }

QString AppSettings::language() const { return m_language; }
void AppSettings::setLanguage(const QString &v) { if(m_language != v) { m_language = v; emit settingsChanged(); } }

QString AppSettings::currency() const { return m_currency; }
void AppSettings::setCurrency(const QString &v) { if(m_currency != v) { m_currency = v; emit settingsChanged(); } }

QString AppSettings::rpcHost() const { return m_rpcHost; }
void AppSettings::setRpcHost(const QString &v) { if(m_rpcHost != v) { m_rpcHost = v; emit rpcChanged(); } }

int AppSettings::rpcPort() const { return m_rpcPort; }
void AppSettings::setRpcPort(int v) { if(m_rpcPort != v) { m_rpcPort = v; emit rpcChanged(); } }

} // namespace Coin2x2
