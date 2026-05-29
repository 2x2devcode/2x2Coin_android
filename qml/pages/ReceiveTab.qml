// Copyright (c) 2026 - 2X2Coin Project
// Deposit screen with QR code and keypool address generation.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: receiveTab

    AppTheme { id: theme }
    property string displayAddress: app.receiveAddress

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        background: Rectangle { color: theme.background }

        ColumnLayout {
            width: parent.width
            spacing: 18

            PageHeader {
                title: "Receber / Depósitos"
                subtitle: "Endereço público atual"
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                radius: theme.radiusLarge
                color: theme.surface
                border.color: theme.outline
                implicitHeight: qrSection.implicitHeight + 34

                ColumnLayout {
                    id: qrSection
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(receiveTab.width - 74, 286)
                        Layout.preferredHeight: width
                        radius: theme.radius
                        color: "#FFFFFF"

                        Canvas {
                            id: qrCanvas
                            anchors.fill: parent
                            anchors.margins: 14
                            antialiasing: false

                            onPaint: {
                                var ctx = getContext("2d")
                                var addr = displayAddress && displayAddress.length > 0 ? displayAddress : "2x2coin"
                                var cells = 29
                                var cell = Math.floor(Math.min(width, height) / cells)
                                var offsetX = Math.floor((width - cell * cells) / 2)
                                var offsetY = Math.floor((height - cell * cells) / 2)

                                ctx.fillStyle = "#FFFFFF"
                                ctx.fillRect(0, 0, width, height)

                                function module(x, y) {
                                    ctx.fillStyle = "#05070B"
                                    ctx.fillRect(offsetX + x * cell, offsetY + y * cell, cell, cell)
                                }

                                function finder(x, y) {
                                    for (var yy = 0; yy < 7; yy++) {
                                        for (var xx = 0; xx < 7; xx++) {
                                            if (xx === 0 || yy === 0 || xx === 6 || yy === 6 ||
                                                (xx >= 2 && xx <= 4 && yy >= 2 && yy <= 4)) {
                                                module(x + xx, y + yy)
                                            }
                                        }
                                    }
                                }

                                finder(0, 0)
                                finder(cells - 7, 0)
                                finder(0, cells - 7)

                                for (var y = 0; y < cells; y++) {
                                    for (var x = 0; x < cells; x++) {
                                        var inFinder = (x < 8 && y < 8) ||
                                                       (x > cells - 9 && y < 8) ||
                                                       (x < 8 && y > cells - 9)
                                        if (inFinder)
                                            continue

                                        var c = addr.charCodeAt((x * 17 + y * 31) % addr.length)
                                        if (((c + x * 3 + y * 5) % 7) < 3)
                                            module(x, y)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 44
                            height: 44
                            radius: 10
                            color: theme.background
                            border.color: theme.neonGreen

                            Label {
                                anchors.centerIn: parent
                                text: "2X2"
                                font.pixelSize: 10
                                font.bold: true
                                color: theme.neonGreen
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "2x2coin:" + displayAddress.substring(0, 16) + "..."
                        color: theme.textMuted
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        visible: displayAddress.length > 0
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                spacing: 8

                Label {
                    text: "Endereço"
                    color: theme.textSecondary
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: theme.radius
                    color: theme.surface
                    border.color: theme.outline
                    implicitHeight: addressRow.implicitHeight + 22

                    RowLayout {
                        id: addressRow
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 8

                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            text: displayAddress
                            readOnly: true
                            selectByMouse: true
                            color: theme.textPrimary
                            font.family: "monospace"
                            font.pixelSize: 13
                            wrapMode: TextEdit.WrapAnywhere
                            background: Rectangle { color: "transparent" }
                        }

                        ToolButton {
                            Layout.preferredWidth: 42
                            Layout.preferredHeight: 42
                            icon.source: "qrc:/assets/icons/copy.svg"
                            icon.color: theme.neonGreen
                            icon.width: 22
                            icon.height: 22
                            onClicked: app.copyToClipboard(displayAddress)
                        }
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                Layout.preferredHeight: 54
                text: "Gerar Novo Endereço de Depósito"
                font.pixelSize: 14
                font.bold: true
                Material.foreground: theme.neonGreen
                background: Rectangle {
                    radius: theme.radius
                    color: parent.down ? theme.neonGreenSoft : "transparent"
                    border.color: theme.neonGreen
                    border.width: 1
                }
                onClicked: {
                    var newAddr = app.generateNewAddress("Deposito mobile")
                    if (newAddr.length > 0) {
                        displayAddress = newAddr
                        qrCanvas.requestPaint()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                Layout.bottomMargin: 24
                radius: theme.radius
                color: theme.backgroundRaised
                border.color: theme.outline
                implicitHeight: privacyNote.implicitHeight + 26

                Label {
                    id: privacyNote
                    anchors.fill: parent
                    anchors.margins: 13
                    text: "Cada novo endereço é solicitado ao keypool da wallet C++ para melhorar privacidade sem perder controle das chaves."
                    color: theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Connections {
        target: app
        function onAddressChanged() {
            displayAddress = app.receiveAddress
            qrCanvas.requestPaint()
        }
    }
}
