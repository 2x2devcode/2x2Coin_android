// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Ponto de entrada do aplicativo Android Qt Wallet para 2X2Coin
// Baseado em: https://github.com/coinsdevcode/2x2Coin

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QIcon>
#include <QDebug>
#include <QDir>
#include <QStandardPaths>
#include <QTimer>

#include "ui/applicationcontroller.h"
#include "ui/walletcontroller.h"
#include "wallet/walletmanager.h"
#include "network/networkmanager.h"
#include "core/chainparams.h"
#include <QFile>
#include <QTextStream>
#include <QDateTime>

void myMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    // Descobre a pasta interna protegida do aplicativo no Android
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);

    // Cria a pasta caso ela ainda não exista internamente
    QDir().mkpath(logDir);

    // Define o caminho do arquivo dentro da pasta do app
    QFile outFile(logDir + "/carteira_log.txt");
    if (outFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream ts(&outFile);
        ts << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss ") << msg << Qt::endl;
    }
}

int main(int argc, char *argv[])
{
    // Configurações de DPI e logs
    qInstallMessageHandler(myMessageHandler);

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

    QGuiApplication app(argc, argv);

    // Metadados
    app.setApplicationName("2X2Coin Wallet");
    app.setApplicationVersion("2.0.2");
    app.setOrganizationName("2x2coin.com");
    app.setOrganizationDomain("2x2coin.com");

    qDebug() << "=================================================";
    qDebug() << "  2X2Coin Android Qt Wallet v2.0.2";
    qDebug() << "  Baseado em: https://github.com/coinsdevcode/2x2Coin";
    qDebug() << "  Rede: Mainnet | Porta: 15190";
    qDebug() << "  Consenso: PoW (até bloco 110.000) + PoS";
    qDebug() << "=================================================";

    // Estilo Material Design
    QQuickStyle::setStyle("Material");

    // Inicializar lógica da moeda
    Coin2x2::ChainParams::instance().setNetwork(Coin2x2::ChainParams::MAIN);

    // Controladores
    Coin2x2::ApplicationController controller;
    Coin2x2::ApplicationController::setInstance(&controller);
    Coin2x2::ApplicationController::registerQmlTypes();

    Coin2x2::WalletController walletController;
    Coin2x2::WalletController::setInstance(&walletController);
    Coin2x2::WalletController::registerQmlTypes();

    QQmlApplicationEngine engine;

    // DEFINIÇÃO ÚNICA DA URL (Corrigida para compatibilidade)
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

    // Conexão de segurança para detectar falha no carregamento do QML
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    qDebug() << "2X2Coin Wallet iniciado com sucesso";
    return app.exec();
}
