// Copyright (c) 2026 - 2X2Coin Project
// Aba de histórico de transações 2X2Coin

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: historyTab

    property string filterType: "all"  // all, received, sent, staked
    property string searchText: ""
    property int pageSize: 20
    property int currentOffset: 0

    ListModel { id: txModel }

    Component.onCompleted: loadTransactions()

    function loadTransactions() {
        txModel.clear()
        var txs = app.getTransactions(pageSize, currentOffset)
        for (var i = 0; i < txs.length; i++) {
            var tx = txs[i]
            if (filterType !== "all" && tx.type !== filterType) continue
            if (searchText.length > 0 &&
                !tx.address.toLowerCase().includes(searchText.toLowerCase()) &&
                !tx.txid.toLowerCase().includes(searchText.toLowerCase())) continue
            txModel.append(tx)
        }
    }

    Connections {
        target: app
        function onTransactionReceived(tx) { loadTransactions() }
        function onTransactionSent(txid) { loadTransactions() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Cabeçalho
        PageHeader {
            title: "History"
            subtitle: txModel.count + " transações"
        }

        // Barra de busca
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#1A1A2E"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Buscar por endereço ou TXID..."
                    color: "#FFFFFF"
                    placeholderTextColor: "#555566"
                    font.pixelSize: 13
                    height: 36

                    background: Rectangle {
                        radius: 18
                        color: "#0F0F1A"
                        border.color: searchField.activeFocus ? "#00D4AA" : "#333355"
                    }

                    leftPadding: 12

                    onTextChanged: {
                        searchText = text
                        loadTransactions()
                    }
                }

                // Botão limpar busca
                RoundButton {
                    width: 32
                    height: 32
                    text: "✕"
                    font.pixelSize: 14
                    visible: searchField.text.length > 0
                    Material.background: "transparent"
                    Material.foreground: "#8899AA"
                    onClicked: {
                        searchField.text = ""
                        searchText = ""
                        loadTransactions()
                    }
                }
            }
        }

        // Filtros por tipo
        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: "#0F0F1A"

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                spacing: 8

                Repeater {
                    model: [
                        { id: "all",      label: "All" },
                        { id: "received", label: "Received" },
                        { id: "sent",     label: "Sent" },
                        { id: "staked",   label: "Staking" },
                        { id: "mined",    label: "Mineradas" }
                    ]

                    delegate: Button {
                        height: 32
                        text: modelData.label
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                        flat: filterType !== modelData.id
                        Material.background: filterType === modelData.id ? "#00D4AA22" : "transparent"
                        Material.foreground: filterType === modelData.id ? "#00D4AA" : "#8899AA"
                        background: Rectangle {
                            radius: 16
                            color: filterType === modelData.id ? "#00D4AA22" : "transparent"
                            border.color: filterType === modelData.id ? "#00D4AA" : "#333355"
                            border.width: 1
                        }
                        onClicked: {
                            filterType = modelData.id
                            loadTransactions()
                        }
                    }
                }
            }
        }

        // Lista de transações
        ListView {
            id: txListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: txModel
            spacing: 1

            // Cabeçalho da lista
            header: Rectangle {
                width: txListView.width
                height: txModel.count === 0 ? 0 : 36
                color: "#0F0F1A"
                visible: txModel.count > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Label {
                        text: "Tipo"
                        font.pixelSize: 11
                        color: "#555566"
                        Layout.preferredWidth: 80
                    }
                    Label {
                        text: "Valor"
                        font.pixelSize: 11
                        color: "#555566"
                        Layout.fillWidth: true
                    }
                    Label {
                        text: "Data"
                        font.pixelSize: 11
                        color: "#555566"
                        Layout.preferredWidth: 100
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            delegate: Rectangle {
                width: txListView.width
                height: 72
                color: mouseArea.containsMouse ? "#1A1A2E" : "#0F0F1A"

                // Borda esquerda colorida por tipo
                Rectangle {
                    width: 3
                    height: parent.height
                    color: {
                        switch(model.type) {
                            case "received": return "#00D4AA"
                            case "sent":     return "#FF5252"
                            case "staked":   return "#FFD700"
                            case "mined":    return "#FF8C00"
                            default:         return "#333355"
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    // Ícone do tipo
                    Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: {
                            switch(model.type) {
                                case "received": return "#00D4AA22"
                                case "sent":     return "#FF525222"
                                case "staked":   return "#FFD70022"
                                case "mined":    return "#FF8C0022"
                                default:         return "#33335522"
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: {
                                switch(model.type) {
                                    case "received": return "↓"
                                    case "sent":     return "↑"
                                    case "staked":   return "⚡"
                                    case "mined":    return "⛏"
                                    default:         return "•"
                                }
                            }
                            font.pixelSize: 18
                            font.bold: true
                            color: {
                                switch(model.type) {
                                    case "received": return "#00D4AA"
                                    case "sent":     return "#FF5252"
                                    case "staked":   return "#FFD700"
                                    case "mined":    return "#FF8C00"
                                    default:         return "#8899AA"
                                }
                            }
                        }
                    }

                    // Informações da transação
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Label {
                            text: {
                                switch(model.type) {
                                    case "received": return "Recebido"
                                    case "sent":     return "Enviado"
                                    case "staked":   return "Recompensa de Staking"
                                    case "mined":    return "Recompensa de Mineração"
                                    default:         return "Transação"
                                }
                            }
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Label {
                            text: model.address.length > 0 ?
                                  (model.address.substring(0, 12) + "..." +
                                   model.address.substring(model.address.length - 6)) :
                                  model.txid.substring(0, 16) + "..."
                            font.pixelSize: 12
                            color: "#8899AA"
                            font.family: "monospace"
                        }

                        // Status de confirmações
                        Row {
                            spacing: 4
                            Repeater {
                                model: Math.min(model.confirmations, 6)
                                delegate: Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: "#00D4AA"
                                }
                            }
                            Repeater {
                                model: Math.max(0, 6 - model.confirmations)
                                delegate: Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: "#333355"
                                }
                            }
                        }
                    }

                    // Valor e data
                    ColumnLayout {
                        spacing: 2
                        Layout.preferredWidth: 110

                        Label {
                            text: model.amount
                            font.pixelSize: 14
                            font.bold: true
                            color: model.isReceived ? "#00D4AA" : "#FF5252"
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }

                        Label {
                            text: model.timestamp
                            font.pixelSize: 11
                            color: "#8899AA"
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Separador
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#1A1A2E"
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        txDetailDialog.txData = app.getTransaction(model.txid)
                        txDetailDialog.open()
                    }
                }
            }

            // Mensagem de lista vazia
            Label {
                anchors.centerIn: parent
                text: searchText.length > 0 ?
                      "Nenhuma transação encontrada" :
                      "Nenhuma transação ainda"
                font.pixelSize: 14
                color: "#8899AA"
                visible: txModel.count === 0
            }

            // Botão carregar mais
            footer: Button {
                width: txListView.width
                height: 48
                text: "Carregar mais transações"
                flat: true
                Material.foreground: "#00D4AA"
                visible: txModel.count >= pageSize
                onClicked: {
                    currentOffset += pageSize
                    var moreTxs = app.getTransactions(pageSize, currentOffset)
                    for (var i = 0; i < moreTxs.length; i++) {
                        txModel.append(moreTxs[i])
                    }
                }
            }
        }
    }

    // Diálogo de detalhes da transação
    Dialog {
        id: txDetailDialog
        property var txData: ({})
        title: "Detalhes da Transação"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Close

        ColumnLayout {
            width: parent.width
            spacing: 12

            Repeater {
                model: [
                    { label: "TXID",          key: "txid" },
                    { label: "Tipo",           key: "type" },
                    { label: "Valor",          key: "amount" },
                    { label: "Taxa",           key: "fee" },
                    { label: "Confirmações",   key: "confirmations" },
                    { label: "Data/Hora",      key: "timestamp" },
                    { label: "Status",         key: "status" }
                ]

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: modelData.label + ":"
                        font.pixelSize: 12
                        color: "#8899AA"
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: txDetailDialog.txData[modelData.key] || "-"
                        font.pixelSize: 12
                        color: "#FFFFFF"
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                    }
                }
            }

            Button {
                text: "Ver no Explorador"
                flat: true
                Material.foreground: "#00D4AA"
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    app.openExplorer(txDetailDialog.txData.txid || "")
                    txDetailDialog.close()
                }
            }
        }
    }
}
