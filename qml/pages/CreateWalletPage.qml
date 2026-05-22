// Copyright (c) 2026 - 2X2Coin Project
// Tela de criação de nova carteira 2X2Coin

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: createWalletPage
    signal walletCreated()
    signal back()

    property var mnemonic: []
    property int currentStep: 0  // 0=senha, 1=mnemônico, 2=verificação

    background: Rectangle { color: "#0F0F1A" }

    header: ToolBar {
        Material.background: "#1A1A2E"
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: "←"
                font.pixelSize: 20
                onClicked: {
                    if (currentStep > 0) currentStep--
                    else createWalletPage.back()
                }
            }
            Label {
                text: ["Definir Senha", "Frase de Recuperação", "Verificar Frase"][currentStep]
                font.pixelSize: 16
                font.bold: true
                color: "#FFFFFF"
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Item { width: 48 }
        }
    }

    // Indicador de progresso
    ProgressBar {
        anchors.top: parent.top
        width: parent.width
        value: (currentStep + 1) / 3
        Material.accent: "#00D4AA"
    }

    // ============================================================
    // Passo 0: Definir senha
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16
        visible: currentStep === 0

        Item { Layout.fillHeight: true }

        Label {
            text: "🔐"
            font.pixelSize: 48
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Proteja sua carteira"
            font.pixelSize: 22
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Crie uma senha forte para proteger o acesso à sua carteira 2X2Coin."
            font.pixelSize: 14
            color: "#8899AA"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }

        Item { height: 16 }

        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: "Senha (mínimo 8 caracteres)"
            echoMode: TextInput.Password
            color: "#FFFFFF"
            font.pixelSize: 16
            background: Rectangle {
                radius: 12; color: "#1A1A2E"
                border.color: passwordField.activeFocus ? "#00D4AA" : "#333355"
                border.width: passwordField.activeFocus ? 2 : 1
            }
        }

        TextField {
            id: confirmPasswordField
            Layout.fillWidth: true
            placeholderText: "Confirmar senha"
            echoMode: TextInput.Password
            color: "#FFFFFF"
            font.pixelSize: 16
            background: Rectangle {
                radius: 12; color: "#1A1A2E"
                border.color: {
                    if (!confirmPasswordField.activeFocus && confirmPasswordField.text.length > 0)
                        return passwordField.text === confirmPasswordField.text ? "#00D4AA" : "#FF5252"
                    return confirmPasswordField.activeFocus ? "#00D4AA" : "#333355"
                }
                border.width: confirmPasswordField.activeFocus ? 2 : 1
            }
        }

        // Força da senha
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: passwordField.text.length > 0

            Label {
                text: {
                    var len = passwordField.text.length
                    if (len < 8) return "Senha muito curta"
                    if (len < 12) return "Senha fraca"
                    if (len < 16) return "Senha média"
                    return "Senha forte"
                }
                font.pixelSize: 12
                color: {
                    var len = passwordField.text.length
                    if (len < 8) return "#FF5252"
                    if (len < 12) return "#FF8C00"
                    if (len < 16) return "#FFD700"
                    return "#00D4AA"
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                value: Math.min(passwordField.text.length / 16, 1.0)
                Material.accent: {
                    var len = passwordField.text.length
                    if (len < 8) return "#FF5252"
                    if (len < 12) return "#FF8C00"
                    if (len < 16) return "#FFD700"
                    return "#00D4AA"
                }
            }
        }

        Item { Layout.fillHeight: true }

        Button {
            Layout.fillWidth: true
            height: 56
            text: "Continuar →"
            font.pixelSize: 16
            font.bold: true
            enabled: passwordField.text.length >= 8 &&
                     passwordField.text === confirmPasswordField.text
            Material.background: enabled ? "#00D4AA" : "#333355"
            Material.foreground: enabled ? "#0F0F1A" : "#666677"
            onClicked: {
                // Criar wallet com a senha
                if (app.createNewWallet(passwordField.text)) {
                    mnemonic = app.getMnemonic()
                    currentStep = 1
                }
            }
        }
    }

    // ============================================================
    // Passo 1: Exibir mnemônico
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        visible: currentStep === 1

        Label {
            text: "⚠ Anote estas 12 palavras em ordem"
            font.pixelSize: 16
            font.bold: true
            color: "#FF8C00"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Esta é a única forma de recuperar sua carteira se você perder o acesso ao dispositivo."
            font.pixelSize: 13
            color: "#8899AA"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Grid de palavras
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: mnemonic
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 8
                    color: "#1A1A2E"
                    border.color: "#00D4AA"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Label {
                            text: (index + 1) + "."
                            font.pixelSize: 11
                            color: "#555566"
                            Layout.preferredWidth: 18
                        }

                        Label {
                            text: modelData
                            font.pixelSize: 14
                            font.bold: true
                            color: "#00D4AA"
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // Aviso
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 8
            color: "#2A1A0A"
            border.color: "#FF8C00"

            Label {
                anchors.fill: parent
                anchors.margins: 8
                text: "🔒 Guarde em local seguro. Nunca fotografe ou salve digitalmente."
                font.pixelSize: 12
                color: "#FF8C00"
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                height: 48
                text: "Copiar"
                flat: true
                Material.foreground: "#00D4AA"
                background: Rectangle {
                    radius: 4; color: "transparent"
                    border.color: "#00D4AA"; border.width: 1
                }
                onClicked: app.copyToClipboard(mnemonic.join(" "))
            }

            Button {
                Layout.fillWidth: true
                height: 48
                text: "Já anotei →"
                font.bold: true
                Material.background: "#00D4AA"
                Material.foreground: "#0F0F1A"
                onClicked: currentStep = 2
            }
        }
    }

    // ============================================================
    // Passo 2: Verificar mnemônico
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        visible: currentStep === 2

        Label {
            text: "✓ Verificar Frase de Recuperação"
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Digite suas 12 palavras para confirmar que você as anotou corretamente."
            font.pixelSize: 13
            color: "#8899AA"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        TextArea {
            id: verifyMnemonicField
            Layout.fillWidth: true
            height: 100
            placeholderText: "Digite as 12 palavras separadas por espaço..."
            color: "#FFFFFF"
            font.pixelSize: 14
            wrapMode: TextEdit.WordWrap
            background: Rectangle {
                radius: 12; color: "#1A1A2E"
                border.color: verifyMnemonicField.activeFocus ? "#00D4AA" : "#333355"
                border.width: verifyMnemonicField.activeFocus ? 2 : 1
            }
        }

        // Resultado da verificação
        Label {
            text: {
                if (verifyMnemonicField.text.trim().split(" ").length < 12) return ""
                return app.verifyMnemonic(verifyMnemonicField.text.trim()) ?
                       "✓ Frase correta!" : "✗ Frase incorreta. Verifique as palavras."
            }
            font.pixelSize: 14
            font.bold: true
            color: app.verifyMnemonic(verifyMnemonicField.text.trim()) ? "#00D4AA" : "#FF5252"
            visible: verifyMnemonicField.text.trim().split(" ").length >= 12
        }

        Item { Layout.fillHeight: true }

        Button {
            Layout.fillWidth: true
            height: 56
            text: "✓  Concluir Criação da Carteira"
            font.pixelSize: 16
            font.bold: true
            enabled: app.verifyMnemonic(verifyMnemonicField.text.trim())
            Material.background: enabled ? "#00D4AA" : "#333355"
            Material.foreground: enabled ? "#0F0F1A" : "#666677"
            onClicked: createWalletPage.walletCreated()
        }
    }
}
