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

    // Barra de navegação inferior
    footer: TabBar {
        id: tabBar
        background: Rectangle {
            color: "#1A1A2E"
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#333355"
            }
        }

        TabButton {
            text: "Visão Geral"
            icon.source: "qrc:/assets/icons/home.svg"
            icon.color: tabBar.currentIndex === 0 ? "#00D4AA" : "#888899"
            Material.foreground: tabBar.currentIndex === 0 ? "#00D4AA" : "#888899"
        }
        TabButton {
            text: "Enviar"
            icon.source: "qrc:/assets/icons/send.svg"
            icon.color: tabBar.currentIndex === 1 ? "#00D4AA" : "#888899"
            Material.foreground: tabBar.currentIndex === 1 ? "#00D4AA" : "#888899"
        }
        TabButton {
            text: "Receber"
            icon.source: "qrc:/assets/icons/receive.svg"
            icon.color: tabBar.currentIndex === 2 ? "#00D4AA" : "#888899"
            Material.foreground: tabBar.currentIndex === 2 ? "#00D4AA" : "#888899"
        }
        TabButton {
            text: "Histórico"
            icon.source: "qrc:/assets/icons/history.svg"
            icon.color: tabBar.currentIndex === 3 ? "#00D4AA" : "#888899"
            Material.foreground: tabBar.currentIndex === 3 ? "#00D4AA" : "#888899"
        }
        TabButton {
            text: "Config"
            icon.source: "qrc:/assets/icons/settings.svg"
            icon.color: tabBar.currentIndex === 4 ? "#00D4AA" : "#888899"
            Material.foreground: tabBar.currentIndex === 4 ? "#00D4AA" : "#888899"
        }
    }

    // Conteúdo das abas
    StackLayout {
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        // Aba 1: Visão Geral (Overview)
        OverviewTab {}

        // Aba 2: Enviar
        SendTab {}

        // Aba 3: Receber
        ReceiveTab {}

        // Aba 4: Histórico de Transações
        HistoryTab {}

        // Aba 5: Configurações
        SettingsTab {
            onLockWallet: mainPage.lockWallet()
        }
    }
}
