// Copyright (c) 2026 - 2X2Coin Project
// Item de lista de transação

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: txItem
    property string txid: ""
    property string address: ""
    property string amount: ""
    property string timestamp: ""
    property bool isReceived: true
    property string status: ""
    property string type: "received"
    property int confirmations: 0

    height: 72
    radius: 12
    color: mouseArea.containsMouse ? "#1A1A2E" : "#111122"
    border.color: "#222233"

    // Borda colorida esquerda
    Rectangle {
        width: 3
        height: parent.height
        anchors.left: parent.left
        radius: 2
        color: isReceived ? "#00D4AA" : "#FF5252"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 12

        // Ícone
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: isReceived ? "#00D4AA22" : "#FF525222"

            Label {
                anchors.centerIn: parent
                text: {
                    switch(type) {
                        case "received": return "↓"
                        case "sent":     return "↑"
                        case "staked":   return "⚡"
                        case "mined":    return "⛏"
                        default:         return "•"
                    }
                }
                font.pixelSize: 18
                font.bold: true
                color: isReceived ? "#00D4AA" : "#FF5252"
            }
        }

        // Informações
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                text: address.length > 20 ?
                      address.substring(0, 10) + "..." + address.substring(address.length - 6) :
                      address
                font.pixelSize: 13
                color: "#FFFFFF"
                font.family: "monospace"
            }

            RowLayout {
                spacing: 6
                Label {
                    text: status
                    font.pixelSize: 11
                    color: confirmations >= 6 ? "#00D4AA" :
                           confirmations > 0 ? "#FFD700" : "#FF8C00"
                }
                Label {
                    text: "•"
                    font.pixelSize: 11
                    color: "#555566"
                }
                Label {
                    text: timestamp
                    font.pixelSize: 11
                    color: "#8899AA"
                }
            }
        }

        // Valor
        Label {
            text: amount
            font.pixelSize: 14
            font.bold: true
            color: isReceived ? "#00D4AA" : "#FF5252"
            horizontalAlignment: Text.AlignRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            // Abrir detalhes da transação
        }
    }
}
