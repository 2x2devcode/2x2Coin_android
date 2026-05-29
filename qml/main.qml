// Copyright (c) 2026 - 2X2Coin Project
// Distributed under the MIT software license
//
// Interface principal do 2X2Coin Android Qt Wallet

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "pages"
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 390
    height: 844
    title: "2X2Coin Wallet"

    AppTheme { id: theme }

    // Material 3-inspired palette rendered by the native QML engine.
    Material.theme: Material.Dark
    Material.accent: theme.neonGreen
    Material.primary: theme.electricBlue
    Material.background: theme.background
    color: theme.background

    // Propriedades globais
    property bool isFirstRun: !app.hasWallet
    property string currentTheme: "dark"

    // Stack de navegação principal
    StackView {
        id: stackView
        anchors.fill: parent

        // Tela inicial baseada no estado da wallet
        Component.onCompleted: {
            if (app.hasWallet) {
                stackView.push(lockScreenPage)
            } else {
                stackView.push(welcomePage)
            }
        }
    }

    // ============================================================
    // Páginas do aplicativo
    // ============================================================

    Component {
        id: welcomePage
        WelcomePage {
            onCreateWallet: stackView.push(createWalletPage)
            onRestoreWallet: stackView.push(restoreWalletPage)
        }
    }

    Component {
        id: createWalletPage
        CreateWalletPage {
            onWalletCreated: {
                stackView.clear()
                stackView.push(mainPage)
            }
            onBack: stackView.pop()
        }
    }

    Component {
        id: restoreWalletPage
        RestoreWalletPage {
            onWalletRestored: {
                stackView.clear()
                stackView.push(mainPage)
            }
            onBack: stackView.pop()
        }
    }

    Component {
        id: lockScreenPage
        LockScreenPage {
            onUnlocked: {
                stackView.clear()
                stackView.push(mainPage)
            }
        }
    }

    Component {
        id: mainPage
        MainPage {
            onLockWallet: {
                stackView.clear()
                stackView.push(lockScreenPage)
            }
        }
    }

    // ============================================================
    // Conexões com o controlador
    // ============================================================
    Connections {
        target: app

        function onWalletCreated(mnemonic) {
            // Navegar para página de backup do mnemônico
        }

        function onWalletLocked() {
            stackView.clear()
            stackView.push(lockScreenPage)
        }

        function onTransactionReceived(tx) {
            notificationBar.show(
                "Transação Recebida",
                "+" + tx.amount + " 2X2"
            )
        }

        function onErrorOccurred(error) {
            errorDialog.message = error
            errorDialog.open()
        }

        function onInfoMessage(message) {
            snackbar.show(message)
        }
    }

    // ============================================================
    // Componentes globais de UI
    // ============================================================

    // Barra de notificação
    NotificationBar {
        id: notificationBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 100
    }

    // Snackbar para mensagens rápidas
    Snackbar {
        id: snackbar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100
    }

    // Dialog de erro
    Dialog {
        id: errorDialog
        property string message: ""
        title: "Erro"
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok

        Label {
            text: errorDialog.message
            wrapMode: Text.WordWrap
            width: parent.width
            color: "#FF5252"
        }
    }
}
