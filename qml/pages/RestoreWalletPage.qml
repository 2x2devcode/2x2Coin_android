// Copyright (c) 2026 - 2X2Coin Project
// Tela de restauração de carteira via mnemônico

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Page {
    id: restorePage
    signal walletRestored()
    signal back()

    AppTheme { id: theme }

    background: Rectangle { color: theme.background }

    header: ToolBar {
        Material.background: theme.background
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "←"
                font.pixelSize: 20
                Material.foreground: theme.textPrimary
                onClicked: restorePage.back()
            }
            Label {
                text: "Abrir Carteira Existente"
                font.pixelSize: 16
                font.bold: true
                color: theme.textPrimary
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
                text: "2X2"
                font.pixelSize: 26
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
                color: theme.neonGreen
                background: Rectangle {
                    radius: theme.radiusLarge
                    color: theme.surface
                    border.color: theme.neonGreen
                }
                padding: 22
            }

            Label {
                text: "Abrir Carteira Existente"
                font.pixelSize: 22
                font.bold: true
                color: theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Digite suas 12 palavras de recuperação para restaurar o acesso à sua carteira 2X2Coin."
                font.pixelSize: 14
                color: theme.textSecondary
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
                    color: theme.textSecondary
                }

                TextArea {
                    id: mnemonicField
                    Layout.fillWidth: true
                    height: 100
                    placeholderText: "palavra1 palavra2 palavra3 ... palavra12"
                    color: theme.textPrimary
                    placeholderTextColor: theme.textMuted
                    font.pixelSize: 14
                    wrapMode: TextEdit.WordWrap
                    background: Rectangle {
                        radius: 12; color: theme.surface
                        border.color: mnemonicField.activeFocus ? theme.electricBlue : theme.outline
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
                        return words.length === 12 ? theme.neonGreen : theme.textSecondary
                    }
                }
            }

            // Botão colar
            Button {
                Layout.fillWidth: true
                height: 44
                text: "Colar da Área de Transferência"
                flat: true
                Material.foreground: theme.electricBlue
                background: Rectangle {
                    radius: theme.radius; color: "transparent"
                    border.color: theme.outline; border.width: 1
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
                    color: theme.textSecondary
                }

                TextField {
                    id: passphraseField
                    Layout.fillWidth: true
                    placeholderText: "BIP39 passphrase (deixe vazio se não usou)"
                    echoMode: TextInput.Password
                    color: theme.textPrimary
                    placeholderTextColor: theme.textMuted
                    font.pixelSize: 14
                    background: Rectangle {
                        radius: 12; color: theme.surface
                        border.color: passphraseField.activeFocus ? theme.electricBlue : theme.outline
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
                    color: theme.textSecondary
                }

                TextField {
                    id: newPasswordField
                    Layout.fillWidth: true
                    placeholderText: "Senha para proteger a carteira restaurada"
                    echoMode: TextInput.Password
                    color: theme.textPrimary
                    placeholderTextColor: theme.textMuted
                    font.pixelSize: 14
                    background: Rectangle {
                        radius: 12; color: theme.surface
                        border.color: newPasswordField.activeFocus ? theme.electricBlue : theme.outline
                        border.width: newPasswordField.activeFocus ? 2 : 1
                    }
                }
            }

            // Aviso
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 8
                color: theme.backgroundRaised
                border.color: theme.outline

                Label {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: "A restauração pode demorar alguns minutos enquanto a carteira sincroniza com a rede."
                    font.pixelSize: 12
                    color: theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            Item { height: 8 }

            Button {
                Layout.fillWidth: true
                height: 56
                text: "Abrir Carteira"
                font.pixelSize: 16
                font.bold: true
                enabled: {
                    var words = mnemonicField.text.trim().split(/\s+/).filter(w => w.length > 0)
                    return words.length === 12 && newPasswordField.text.length >= 8
                }
                Material.background: enabled ? theme.electricBlue : theme.slate
                Material.foreground: enabled ? theme.textPrimary : theme.textMuted
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
