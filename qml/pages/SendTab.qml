import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "../components"

Page {
    id: sendPage
    background: Rectangle { color: "#0F0F1A" }

    header: PageHeader {
        title: "Send 2X2Coin"
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
            anchors.margins: 16
            spacing: 20

            // Card de Available Balance
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: "#1A1A2E"
                radius: 12
                border.color: "#333355"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Rectangle {
                        width: 40; height: 40; radius: 20; color: "#1000D4AA"
                        Image {
                            anchors.centerIn: parent; width: 20; height: 20
                            source: "qrc:/assets/icons/home.svg"
                            sourceSize: Qt.size(20, 20)
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Label { text: "Available Balance"; color: "#8899AA"; font.pixelSize: 12 }
                        Label { 
                            text: app.balance + " 2X2"
                            color: "#FFFFFF"; font.pixelSize: 18; font.bold: true 
                        }
                    }
                }
            }

            // Formulário de Envio
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    spacing: 8
                    Label { text: "Destination Address"; color: "#8899AA"; font.pixelSize: 13 }
                    RowLayout {
                        spacing: 8
                        TextField {
                            id: addressField
                            Layout.fillWidth: true
                            placeholderText: "Enter or paste address"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                            background: Rectangle {
                                radius: 8; color: "#1A1A2E"; border.color: addressField.activeFocus ? "#00D4AA" : "#333355"
                            }
                        }
                        Button {
                            icon.source: "qrc:/assets/icons/qr.svg"
                            icon.color: "#00D4AA"
                            flat: true
                            onClicked: qrScanDialog.open()
                        }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Label { text: "Amount"; color: "#8899AA"; font.pixelSize: 13 }
                    RowLayout {
                        spacing: 8
                        TextField {
                            id: amountField
                            Layout.fillWidth: true
                            placeholderText: "0.00"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            color: "#FFFFFF"
                            font.pixelSize: 16
                            font.bold: true
                            background: Rectangle {
                                radius: 8; color: "#1A1A2E"; border.color: amountField.activeFocus ? "#00D4AA" : "#333355"
                            }
                        }
                        Button {
                            text: "MÁX"
                            flat: true
                            Material.foreground: "#00D4AA"
                            onClicked: amountField.text = app.balance
                        }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Label { text: "Transaction Fee"; color: "#8899AA"; font.pixelSize: 13 }
                    ComboBox {
                        id: feeCombo
                        Layout.fillWidth: true
                        model: ["Economic (Slow)", "Normal (Recommended)", "Priority (Fast)"]
                        currentIndex: 1
                        delegate: ItemDelegate {
                            width: feeCombo.width
                            text: modelData
                            highlighted: feeCombo.highlightedIndex === index
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "REVIEW TRANSACTION"
                font.bold: true
                enabled: addressField.text.length > 10 && parseFloat(amountField.text) > 0
                Material.background: "#00D4AA"
                Material.foreground: "#0F0F1A"
                onClicked: confirmDialog.open()
            }
        }
    }

    // Diálogo de Confirmação
    Dialog {
        id: confirmDialog
        title: "Confirm Send"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 12

            Label {
                text: "You are sending"
                color: "#8899AA"
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Label {
                text: amountField.text + " 2X2"
                color: "#FFFFFF"
                font.pixelSize: 24
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#333355"
            }

            ColumnLayout {
                spacing: 4
                Label { text: "To:"; color: "#8899AA"; font.pixelSize: 12 }
                Label { 
                    text: addressField.text
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Label { text: "Fee:"; color: "#8899AA"; font.pixelSize: 12; Layout.fillWidth: true }
                Label { text: "0.0001 2X2"; color: "#FFFFFF"; font.pixelSize: 12 }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "CONFIRM AND SEND"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.background: "#00D4AA"
                Material.foreground: "#0F0F1A"
            }
        }

        onAccepted: {
            if (app.sendCoins(addressField.text, parseFloat(amountField.text))) {
                successDialog.txid = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
                successDialog.open()
                addressField.text = ""
                amountField.text = ""
            } else {
                app.showNotification("Erro ao enviar moedas. Verifique o saldo e o endereço.")
            }
        }
    }

    // Diálogo de Sucesso
    Dialog {
        id: successDialog
        property string txid: ""
        title: "Transaction Sent!"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Ok

        ColumnLayout {
            width: parent.width
            spacing: 16
            
            Rectangle {
                width: 60; height: 60; radius: 30; color: "#1000D4AA"
                Layout.alignment: Qt.AlignHCenter
                Image {
                    anchors.centerIn: parent; width: 30; height: 30
                    source: "qrc:/assets/icons/send.svg"
                    sourceSize: Qt.size(30, 30)
                }
            }

            Label {
                text: "Your transaction has been successfully broadcast to the 2X2Coin network."
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                color: "#FFFFFF"
            }

            Button {
                text: "VIEW IN EXPLORER"
                Layout.alignment: Qt.AlignHCenter
                flat: true
                Material.foreground: "#00D4AA"
                onClicked: app.openExplorer(successDialog.txid)
            }
        }
    }

    // Diálogo de QR scan (placeholder)
    Dialog {
        id: qrScanDialog
        title: "Scan QR Code"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        Label {
            text: "Point the camera at the 2X2Coin address QR Code"
            wrapMode: Text.WordWrap
            width: parent.width
            color: "#FFFFFF"
        }
    }
}
