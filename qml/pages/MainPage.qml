// Copyright (c) 2026 - 2X2Coin Project
// Página principal do dashboard da wallet 2X2Coin

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Page {
    id: mainPage
    signal lockWallet()

    AppTheme { id: theme }

    // Barra de navegação inferior
    footer: TabBar {
        id: tabBar
        background: Rectangle {
            color: theme.backgroundRaised
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: theme.outline
            }
        }

        TabButton {
            text: "Saldo"
            icon.source: "qrc:/assets/icons/home.svg"
            icon.color: tabBar.currentIndex === 0 ? theme.neonGreen : theme.textMuted
            Material.foreground: tabBar.currentIndex === 0 ? theme.neonGreen : theme.textMuted
        }
        TabButton {
            text: "Enviar"
            icon.source: "qrc:/assets/icons/send.svg"
            icon.color: tabBar.currentIndex === 1 ? theme.neonGreen : theme.textMuted
            Material.foreground: tabBar.currentIndex === 1 ? theme.neonGreen : theme.textMuted
        }
        TabButton {
            text: "Receber"
            icon.source: "qrc:/assets/icons/receive.svg"
            icon.color: tabBar.currentIndex === 2 ? theme.neonGreen : theme.textMuted
            Material.foreground: tabBar.currentIndex === 2 ? theme.neonGreen : theme.textMuted
        }
        TabButton {
            text: "Ajustes"
            icon.source: "qrc:/assets/icons/settings.svg"
            icon.color: tabBar.currentIndex === 3 ? theme.neonGreen : theme.textMuted
            Material.foreground: tabBar.currentIndex === 3 ? theme.neonGreen : theme.textMuted
        }
    }

    // Conteúdo das abas
    StackLayout {
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        // Aba 1: Visão Geral (Overview)
        OverviewTab {
            onOpenSend: tabBar.currentIndex = 1
            onOpenReceive: tabBar.currentIndex = 2
            onOpenSettings: tabBar.currentIndex = 3
        }

        // Aba 2: Enviar
        SendTab {}

        // Aba 3: Receber
        ReceiveTab {}

        // Aba 4: Configurações
        SettingsTab {
            onLockWallet: mainPage.lockWallet()
        }
    }
}
