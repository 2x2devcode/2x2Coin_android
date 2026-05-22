// Copyright (c) 2026 - 2X2Coin Project
// Aba de recebimento de 2X2Coin com QR Code

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: receiveTab

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: parent.width
            spacing: 0

            // Cabeçalho
            PageHeader {
                title: "Receive 2X2Coin"
                subtitle: "Compartilhe seu endereço"
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 16
                spacing: 16

                // Card do QR Code
                Rectangle {
                    Layout.fillWidth: true
                    height: 320
                    radius: 20
                    color: "#1A1A2E"
                    border.color: "#333355"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Label {
                            text: "QR Code do Endereço"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // QR Code gerado via canvas
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 200
                            height: 200
                            color: "#FFFFFF"
                            radius: 8

                            // Placeholder para QR Code
                            // Em produção: usar biblioteca QR como qzxing
                            Canvas {
                                id: qrCanvas
                                anchors.fill: parent
                                anchors.margins: 8

                                property string address: app.receiveAddress

                                onAddressChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fillRect(0, 0, width, height)

                                    // Desenhar padrão de QR simplificado (visual)
                                    ctx.fillStyle = "#000000"

                                    // Cantos do QR Code
                                    var cornerSize = width * 0.25
                                    // Canto superior esquerdo
                                    ctx.fillRect(0, 0, cornerSize, cornerSize)
                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fillRect(4, 4, cornerSize - 8, cornerSize - 8)
                                    ctx.fillStyle = "#000000"
                                    ctx.fillRect(8, 8, cornerSize - 16, cornerSize - 16)

                                    // Canto superior direito
                                    ctx.fillStyle = "#000000"
                                    ctx.fillRect(width - cornerSize, 0, cornerSize, cornerSize)
                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fillRect(width - cornerSize + 4, 4, cornerSize - 8, cornerSize - 8)
                                    ctx.fillStyle = "#000000"
                                    ctx.fillRect(width - cornerSize + 8, 8, cornerSize - 16, cornerSize - 16)

                                    // Canto inferior esquerdo
                                    ctx.fillStyle = "#000000"
                                    ctx.fillRect(0, height - cornerSize, cornerSize, cornerSize)
                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fillRect(4, height - cornerSize + 4, cornerSize - 8, cornerSize - 8)
                                    ctx.fillStyle = "#000000"
                                    ctx.fillRect(8, height - cornerSize + 8, cornerSize - 16, cornerSize - 16)

                                    // Padrão de dados central (visual)
                                    ctx.fillStyle = "#000000"
                                    var cellSize = 4
                                    var dataArea = width - cornerSize * 2 - 16
                                    var startX = cornerSize + 8
                                    var startY = cornerSize + 8

                                    // Gerar padrão baseado no endereço
                                    var addr = address || "2x2coin"
                                    for (var i = 0; i < dataArea / cellSize; i++) {
                                        for (var j = 0; j < dataArea / cellSize; j++) {
                                            var charCode = addr.charCodeAt((i * j) % addr.length)
                                            if ((charCode + i + j) % 3 !== 0) {
                                                ctx.fillRect(
                                                    startX + i * cellSize,
                                                    startY + j * cellSize,
                                                    cellSize - 1, cellSize - 1
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            // Logo 2X2Coin no centro do QR
                            Rectangle {
                                anchors.centerIn: parent
                                width: 36
                                height: 36
                                radius: 4
                                color: "#00D4AA"

                                Label {
                                    anchors.centerIn: parent
                                    text: "2X2"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: "#0F0F1A"
                                }
                            }
                        }

                        // URI 2X2Coin
                        Label {
                            text: "2x2coin:" + app.receiveAddress.substring(0, 12) + "..."
                            font.pixelSize: 11
                            color: "#8899AA"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Endereço completo
                Rectangle {
                    Layout.fillWidth: true
                    height: 70
                    radius: 12
                    color: "#1A1A2E"
                    border.color: "#333355"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "Endereço de Recebimento"
                                font.pixelSize: 11
                                color: "#8899AA"
                            }

                            Label {
                                text: app.receiveAddress
                                font.pixelSize: 13
                                color: "#FFFFFF"
                                font.family: "monospace"
                                wrapMode: Text.WrapAnywhere
                                Layout.fillWidth: true
                            }
                        }

                        // Botão copiar
                        RoundButton {
                            width: 40
                            height: 40
                            text: "📋"
                            font.pixelSize: 18
                            Material.background: "#00D4AA22"
                            Material.foreground: "#00D4AA"
                            onClicked: {
                                app.copyToClipboard(app.receiveAddress)
                            }
                        }
                    }
                }

                // Campo de valor a solicitar (opcional)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Solicitar Valor Específico (opcional)"
                        font.pixelSize: 13
                        color: "#8899AA"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: requestAmountField
                            Layout.fillWidth: true
                            placeholderText: "0.00000000"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            color: "#FFFFFF"
                            placeholderTextColor: "#555566"
                            font.pixelSize: 16

                            background: Rectangle {
                                radius: 8
                                color: "#1A1A2E"
                                border.color: requestAmountField.activeFocus ? "#00D4AA" : "#333355"
                                border.width: requestAmountField.activeFocus ? 2 : 1
                            }

                            onTextChanged: qrCanvas.requestPaint()
                        }

                        Label {
                            text: "2X2"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#00D4AA"
                        }
                    }
                }

                // Campo de label (opcional)
                TextField {
                    id: labelField
                    Layout.fillWidth: true
                    placeholderText: "Descrição (opcional)"
                    color: "#FFFFFF"
                    placeholderTextColor: "#555566"
                    font.pixelSize: 14

                    background: Rectangle {
                        radius: 8
                        color: "#1A1A2E"
                        border.color: labelField.activeFocus ? "#00D4AA" : "#333355"
                        border.width: labelField.activeFocus ? 2 : 1
                    }
                }

                // Botões de ação
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Gerar novo endereço
                    Button {
                        Layout.fillWidth: true
                        height: 50
                        text: "⊕  Novo Endereço"
                        font.pixelSize: 14
                        flat: false
                        Material.background: "transparent"
                        Material.foreground: "#00D4AA"
                        background: Rectangle {
                            radius: 4
                            color: "transparent"
                            border.color: "#00D4AA"
                            border.width: 2
                        }
                        onClicked: {
                            var label = labelField.text
                            var newAddr = app.generateNewAddress(label)
                            if (newAddr.length > 0) {
                                qrCanvas.address = newAddr
                                qrCanvas.requestPaint()
                            }
                        }
                    }

                    // Compartilhar
                    Button {
                        Layout.fillWidth: true
                        height: 50
                        text: "↗  Compartilhar"
                        font.pixelSize: 14
                        Material.background: "#00D4AA"
                        Material.foreground: "#0F0F1A"
                        onClicked: {
                            var uri = app.generateQRCodeUrl(
                                app.receiveAddress,
                                requestAmountField.text.length > 0 ?
                                    app.coinsToSatoshis(parseFloat(requestAmountField.text)) : 0
                            )
                            app.copyToClipboard(uri)
                        }
                    }
                }

                // Informação sobre endereços
                Rectangle {
                    Layout.fillWidth: true
                    height: infoLayout.implicitHeight + 16
                    radius: 8
                    color: "#0D2030"
                    border.color: "#1A3A5C"

                    RowLayout {
                        id: infoLayout
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Label {
                            text: "ℹ"
                            font.pixelSize: 16
                            color: "#4488BB"
                        }

                        Label {
                            text: "Endereços 2X2Coin começam com o prefixo '2'. " +
                                  "Cada transação usa um novo endereço para maior privacidade."
                            font.pixelSize: 12
                            color: "#8899AA"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }
}
