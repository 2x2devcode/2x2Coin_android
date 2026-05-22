// Copyright (c) 2026 - 2X2Coin Project
// Tela de restauração de carteira via mnemônico

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: restorePage
    signal walletRestored()
    signal back()

    background: Rectangle { color: "#0F0F1A" }

    header: ToolBar {
        Material.background: "#1A1A2E"
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "←"
                font.pixelSize: 20
                onClicked: restorePage.back()
            }
            Label {
                text: "Restaurar Carteira"
                font.pixelSize: 16
                font.bold: true
                color: "#FFFFFF"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item { width: 48 }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: parent.width
            anchors.margins: 24
            spacing: 16

            Item { height: 8 }

            Label {
                text: "↺"
                font.pixelSize: 48
                Layout.alignment: Qt.AlignHCenter
                color: "#00D4AA"
            }

            Label {
                text: "Restaurar Carteira Existente"
                font.pixelSize: 22
                font.bold: true
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Digite suas 12 palavras de recuperação para restaurar o acesso à sua carteira 2X2Coin."
                font.pixelSize: 14
                color: "#8899AA"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }

            // Campo de mnemônico
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Frase de Recuperação (12 palavras)"
                    font.pixelSize: 13
                    color: "#8899AA"
                }

                TextArea {
                    id: mnemonicField
                    Layout.fillWidth: true
                    height: 100
                    placeholderText: "palavra1 palavra2 palavra3 ... palavra12"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    wrapMode: TextEdit.WordWrap
                    background: Rectangle {
                        radius: 12; color: "#1A1A2E"
                        border.color: mnemonicField.activeFocus ? "#00D4AA" : "#333355"
                        border.width: mnemonicField.activeFocus ? 2 : 1
                    }
                }

                // Contador de palavras
                Label {
                    text: {
                        var words = mnemonicField.text.trim().split(/\s+/).filter(w => w.length > 0)
                        return words.length + "/12 palavras"
                    }
                    font.pixelSize: 12
                    color: {
                        var words = mnemonicField.text.trim().split(/\s+/).filter(w => w.length > 0)
                        return words.length === 12 ? "#00D4AA" : "#8899AA"
                    }
                }
            }

            // Botão colar
            Button {
                Layout.fillWidth: true
                height: 44
                text: "📋  Colar da Área de Transferência"
                flat: true
                Material.foreground: "#00D4AA"
                background: Rectangle {
                    radius: 4; color: "transparent"
                    border.color: "#333355"; border.width: 1
                }
                onClicked: {
                    var pasted = app.pasteFromClipboard()
                    if (pasted.length > 0) mnemonicField.text = pasted
                }
            }

            // Senha opcional (BIP39 passphrase)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Senha Adicional (opcional)"
                    font.pixelSize: 13
                    color: "#8899AA"
                }

                TextField {
                    id: passphraseField
                    Layout.fillWidth: true
                    placeholderText: "BIP39 passphrase (deixe vazio se não usou)"
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    background: Rectangle {
                        radius: 12; color: "#1A1A2E"
                        border.color: passphraseField.activeFocus ? "#00D4AA" : "#333355"
                        border.width: passphraseField.activeFocus ? 2 : 1
                    }
                }
            }

            // Nova senha para proteger a wallet
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Nova Senha de Acesso"
                    font.pixelSize: 13
                    color: "#8899AA"
                }

                TextField {
                    id: newPasswordField
                    Layout.fillWidth: true
                    placeholderText: "Senha para proteger a carteira restaurada"
                    echoMode: TextInput.Password
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    background: Rectangle {
                        radius: 12; color: "#1A1A2E"
                        border.color: newPasswordField.activeFocus ? "#00D4AA" : "#333355"
                        border.width: newPasswordField.activeFocus ? 2 : 1
                    }
                }
            }

            // Aviso
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: "#0D2030"
                border.color: "#1A3A5C"

                Label {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: "ℹ A restauração pode demorar alguns minutos enquanto a carteira sincroniza com a rede."
                    font.pixelSize: 12
                    color: "#8899AA"
                    wrapMode: Text.WordWrap
                }
            }

            Item { height: 8 }

            Button {
                Layout.fillWidth: true
                height: 56
                text: "↺  Restaurar Carteira"
                font.pixelSize: 16
                font.bold: true
                enabled: {
                    var words = mnemonicField.text.trim().split(/\s+/).filter(w => w.length > 0)
                    return words.length === 12 && newPasswordField.text.length >= 8
                }
                Material.background: enabled ? "#00D4AA" : "#333355"
                Material.foreground: enabled ? "#0F0F1A" : "#666677"
                onClicked: {
                    if (app.restoreWallet(mnemonicField.text.trim(), passphraseField.text)) {
                        restorePage.walletRestored()
                    }
                }
            }

            Item { height: 20 }
        }
    }
}
