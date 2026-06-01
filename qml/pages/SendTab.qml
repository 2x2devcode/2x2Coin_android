import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Page {
    id: sendPage

    AppTheme { id: theme }
    readonly property bool canConfirm: addressField.text.trim().length > 10 && amountField.text.trim().length > 0

    background: Rectangle { color: theme.background }

    header: PageHeader {
        title: "Enviar 2x2Coin"
        subtitle: "Transferência na rede descentralizada"
        showBack: false
    }

    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.height + 40
        clip: true

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: theme.pageMargin
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                radius: theme.radiusLarge
                color: theme.surface
                border.color: theme.outline
                implicitHeight: balanceRow.implicitHeight + 28

                RowLayout {
                    id: balanceRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: theme.neonGreenSoft
                        border.color: theme.neonGreen

                        Label {
                            anchors.centerIn: parent
                            text: "2X2"
                            color: theme.neonGreen
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: "Saldo disponível"; color: theme.textSecondary; font.pixelSize: 12 }
                        Label {
                            text: app.balance
                            color: theme.textPrimary
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Endereço de Destino"; color: theme.textSecondary; font.pixelSize: 13; font.bold: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        radius: theme.radius
                        color: theme.surface
                        border.color: addressField.activeFocus ? theme.electricBlue : theme.outline
                        border.width: addressField.activeFocus ? 2 : 1

                        TextField {
                            id: addressField
                            anchors.left: parent.left
                            anchors.right: scanButton.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 14
                            anchors.rightMargin: 4
                            placeholderText: "Cole ou digite o endereço 2x2Coin"
                            placeholderTextColor: theme.textMuted
                            color: theme.textPrimary
                            font.pixelSize: 14
                            background: Rectangle { color: "transparent" }
                        }

                        ToolButton {
                            id: scanButton
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 6
                            width: 46
                            height: 46
                            icon.source: "qrc:/assets/icons/qr.svg"
                            icon.color: theme.neonGreen
                            icon.width: 22
                            icon.height: 22
                            flat: true
                            onClicked: qrScanDialog.open()
                        }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: "Quantidade"; color: theme.textSecondary; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextField {
                            id: amountField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            placeholderText: "0.00000000"
                            placeholderTextColor: theme.textMuted
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            color: theme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                            background: Rectangle {
                                radius: theme.radius
                                color: theme.surface
                                border.color: amountField.activeFocus ? theme.electricBlue : theme.outline
                                border.width: amountField.activeFocus ? 2 : 1
                            }
                        }
                        Button {
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 58
                            text: "Máximo"
                            font.bold: true
                            Material.foreground: theme.neonGreen
                            background: Rectangle {
                                radius: theme.radius
                                color: parent.down ? theme.neonGreenSoft : "transparent"
                                border.color: theme.neonGreen
                                border.width: 1
                            }
                            onClicked: amountField.text = app.balance.replace(" 2X2", "").replace("2X2", "").trim()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: theme.radius
                color: theme.backgroundRaised
                border.color: theme.outline
                implicitHeight: feeLayout.implicitHeight + 24

                RowLayout {
                    id: feeLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Label {
                        text: "Taxa estimada"
                        color: theme.textSecondary
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Label {
                        text: canConfirm ? app.estimateFee(addressField.text.trim(), amountField.text.trim()) : "0.0001 2X2"
                        color: theme.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "Confirmar Transação"
                font.bold: true
                enabled: canConfirm
                Material.foreground: enabled ? theme.textPrimary : theme.textMuted
                background: Rectangle {
                    radius: theme.radius
                    color: parent.enabled ? theme.electricBlue : theme.slate
                }
                onClicked: confirmDialog.open()
            }
        }
    }

    Dialog {
        id: confirmDialog
        title: "Confirmar Transação"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 12

            Label {
                text: "Você está enviando"
                color: theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: amountField.text + " 2X2"
                color: theme.textPrimary
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.outline
            }

            ColumnLayout {
                spacing: 4
                Label { text: "Destino:"; color: theme.textSecondary; font.pixelSize: 12 }
                Label {
                    text: addressField.text
                    color: theme.textPrimary
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Label { text: "Taxa:"; color: theme.textSecondary; font.pixelSize: 12; Layout.fillWidth: true }
                Label { text: app.estimateFee(addressField.text.trim(), amountField.text.trim()); color: theme.textPrimary; font.pixelSize: 12 }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "Enviar"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.background: theme.electricBlue
                Material.foreground: theme.textPrimary
            }
        }

        onAccepted: {
            var txid = app.sendCoins(addressField.text.trim(), amountField.text.trim())
            if (txid.length > 0) {
                successDialog.txid = txid
                successDialog.open()
                addressField.text = ""
                amountField.text = ""
            } else {
                app.showNotification("2x2Coin Wallet", "Erro ao enviar moedas. Verifique saldo e endereço.")
            }
        }
    }

    Dialog {
        id: successDialog
        property string txid: ""
        title: "Transação Enviada"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Ok

        ColumnLayout {
            width: parent.width
            spacing: 16
            
            Rectangle {
                width: 60; height: 60; radius: 30; color: theme.neonGreenSoft
                Layout.alignment: Qt.AlignHCenter
                Label {
                    anchors.centerIn: parent
                    text: "OK"
                    color: theme.neonGreen
                    font.bold: true
                }
            }

            Label {
                text: "A transação foi transmitida para a rede 2x2Coin."
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                color: theme.textPrimary
            }

            Button {
                text: "Abrir no Explorer"
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Material.foreground: theme.electricBlue
                onClicked: app.openExplorer(successDialog.txid)
            }
        }
    }

    Dialog {
        id: qrScanDialog
        title: "Scanner QR"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        Label {
            text: "Aponte a câmera para o QR Code de um endereço 2x2Coin."
            wrapMode: Text.WordWrap
            width: parent.width
            color: theme.textPrimary
        }
    }
}
