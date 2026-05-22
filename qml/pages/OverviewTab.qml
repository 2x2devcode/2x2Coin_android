// Copyright (c) 2026 - 2X2Coin Project
// Aba de visão geral da wallet 2X2Coin

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: overviewTab

    // Atualizar dados ao entrar na aba
    Component.onCompleted: refreshData()

    function refreshData() {
        transactionModel.clear()
        var txs = app.getTransactions(10, 0)
        for (var i = 0; i < txs.length; i++) {
            transactionModel.append(txs[i])
        }
    }

    // Modelo de transações recentes
    ListModel {
        id: transactionModel
    }

    // Conexões para atualização automática
    Connections {
        target: app
        function onBalanceChanged() {
            refreshData()
        }
        function onTransactionReceived(tx) {
            refreshData()
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: parent.width
            spacing: 0

            // ============================================================
            // Cabeçalho com logo e status de rede
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#1A1A2E"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    // Logo 2X2Coin
                    Image {
                        source: "qrc:/assets/images/logo_2x2coin.png"
                        width: 32
                        height: 32
                        fillMode: Image.PreserveAspectFit
                    }

                    Label {
                        text: "2X2Coin Wallet"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#FFFFFF"
                        Layout.fillWidth: true
                        leftPadding: 8
                    }

                    // Indicador de conexão
                    Row {
                        spacing: 4

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: app.isConnected ? "#00D4AA" : "#FF5252"
                            anchors.verticalCenter: parent.verticalCenter

                            SequentialAnimation on opacity {
                                running: app.isSyncing
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }

                        Label {
                            text: app.isConnected ?
                                  (app.isSyncing ? "Sincronizando..." :
                                   app.peerCount + " peers") : "Desconectado"
                            font.pixelSize: 11
                            color: app.isConnected ? "#00D4AA" : "#FF5252"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ============================================================
            // Card de Saldo Principal
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 16
                height: 200
                radius: 20
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#1A3A5C" }
                    GradientStop { position: 0.5; color: "#0D2B4A" }
                    GradientStop { position: 1.0; color: "#162040" }
                }

                // Borda sutil
                border.color: "#00D4AA"
                border.width: 1

                // Efeito de brilho no topo
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#00D4AA"
                    opacity: 0.5
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    // Rede e bloco
                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: app.networkName
                            font.pixelSize: 12
                            color: "#00D4AA"
                            background: Rectangle {
                                color: "#00D4AA22"
                                radius: 4
                            }
                            leftPadding: 6
                            rightPadding: 6
                            topPadding: 2
                            bottomPadding: 2
                        }

                        Label {
                            text: app.isPoS ? "⚡ PoS" : "⛏ PoW"
                            font.pixelSize: 12
                            color: app.isPoS ? "#FFD700" : "#FF8C00"
                            leftPadding: 8
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: "Bloco #" + app.blockHeight
                            font.pixelSize: 11
                            color: "#8899AA"
                        }
                    }

                    // Saldo principal
                    Label {
                        text: "Saldo Disponível"
                        font.pixelSize: 13
                        color: "#8899AA"
                        Layout.topMargin: 8
                    }

                    Label {
                        id: balanceLabel
                        text: app.balance
                        font.pixelSize: 32
                        font.bold: true
                        color: "#FFFFFF"
                        Layout.fillWidth: true

                        // Animação ao atualizar
                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation {
                                    target: balanceLabel
                                    property: "opacity"
                                    to: 0.5
                                    duration: 100
                                }
                                NumberAnimation {
                                    target: balanceLabel
                                    property: "opacity"
                                    to: 1.0
                                    duration: 200
                                }
                            }
                        }
                    }

                    // Saldos secundários
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            spacing: 2
                            Label {
                                text: "Não confirmado"
                                font.pixelSize: 11
                                color: "#8899AA"
                            }
                            Label {
                                text: app.unconfBalance
                                font.pixelSize: 13
                                color: "#FFB300"
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            visible: app.isPoS
                            Label {
                                text: "Staking"
                                font.pixelSize: 11
                                color: "#8899AA"
                            }
                            Label {
                                text: app.stakeBalance
                                font.pixelSize: 13
                                color: "#00D4AA"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: 2
                            Label {
                                text: "Total"
                                font.pixelSize: 11
                                color: "#8899AA"
                            }
                            Label {
                                text: app.totalBalance
                                font.pixelSize: 13
                                color: "#FFFFFF"
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // ============================================================
            // Botões de ação rápida
            // ============================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 8
                spacing: 12

                // Botão Enviar
                Button {
                    Layout.fillWidth: true
                    height: 50
                    text: "↑  Enviar"
                    font.pixelSize: 15
                    font.bold: true
                    Material.background: "#00D4AA"
                    Material.foreground: "#0F0F1A"
                    onClicked: {
                        // Navegar para aba de envio
                        var tabBar = parent.parent.parent.parent.footer
                        if (tabBar) tabBar.currentIndex = 1
                    }
                }

                // Botão Receber
                Button {
                    Layout.fillWidth: true
                    height: 50
                    text: "↓  Receber"
                    font.pixelSize: 15
                    font.bold: true
                    Material.background: "transparent"
                    Material.foreground: "#00D4AA"
                    flat: false
                    background: Rectangle {
                        radius: 4
                        color: "transparent"
                        border.color: "#00D4AA"
                        border.width: 2
                    }
                    onClicked: {
                        var tabBar = parent.parent.parent.parent.footer
                        if (tabBar) tabBar.currentIndex = 2
                    }
                }
            }

            // ============================================================
            // Informações de Staking (PoS)
            // ============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 8
                height: 60
                radius: 12
                color: "#1A2A1A"
                border.color: app.stakingEnabled ? "#00D4AA" : "#333355"
                border.width: 1
                visible: app.isPoS

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Ícone de staking
                    Label {
                        text: app.stakingEnabled ? "⚡" : "💤"
                        font.pixelSize: 24
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: app.stakingEnabled ? "Staking Ativo" : "Staking Inativo"
                            font.pixelSize: 14
                            font.bold: true
                            color: app.stakingEnabled ? "#00D4AA" : "#8899AA"
                        }
                        Label {
                            text: app.getStakingInfo()
                            font.pixelSize: 11
                            color: "#8899AA"
                        }
                    }

                    Switch {
                        checked: app.stakingEnabled
                        Material.accent: "#00D4AA"
                        onToggled: app.setStakingEnabled(checked)
                    }
                }
            }

            // ============================================================
            // Recent Transactions
            // ============================================================
            Label {
                text: "Recent Transactions"
                font.pixelSize: 16
                font.bold: true
                color: "#FFFFFF"
                Layout.leftMargin: 16
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            // Lista de transações
            Repeater {
                model: transactionModel

                delegate: TransactionListItem {
                    width: overviewTab.width - 32
                    x: 16
                    txid: model.txid
                    address: model.address
                    amount: model.amount
                    timestamp: model.timestamp
                    isReceived: model.isReceived
                    status: model.status
                    type: model.type
                    confirmations: model.confirmations
                }
            }

            // Mensagem quando não há transações
            Item {
                Layout.fillWidth: true
                height: 120
                visible: transactionModel.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: "📭"
                        font.pixelSize: 40
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Nenhuma transação ainda"
                        font.pixelSize: 14
                        color: "#8899AA"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Ver todas as transações
            Button {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 16
                text: "View All as Transações"
                flat: true
                Material.foreground: "#00D4AA"
                visible: transactionModel.count > 0
                onClicked: {
                    var tabBar = parent.parent.parent.footer
                    if (tabBar) tabBar.currentIndex = 3
                }
            }

            // Espaçamento final
            Item { height: 20 }
        }
    }
}
