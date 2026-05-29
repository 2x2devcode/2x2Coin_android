// Copyright (c) 2026 - 2X2Coin Project
// New-wallet flow with a minimal PIN keypad and recovery phrase verification.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Page {
    id: createWalletPage
    signal walletCreated()
    signal back()

    AppTheme { id: theme }

    property var mnemonic: []
    property int currentStep: 0
    property string pin: ""
    property string confirmPin: ""
    property bool confirmingPin: false
    property string pinError: ""
    readonly property int pinLength: 6

    function activePin() {
        return confirmingPin ? confirmPin : pin
    }

    function appendDigit(digit) {
        if (activePin().length >= pinLength)
            return

        if (confirmingPin)
            confirmPin += digit
        else
            pin += digit

        if (activePin().length === pinLength)
            completePinStage()
    }

    function backspacePin() {
        pinError = ""
        if (confirmingPin)
            confirmPin = confirmPin.slice(0, -1)
        else
            pin = pin.slice(0, -1)
    }

    function completePinStage() {
        if (!confirmingPin) {
            confirmingPin = true
            pinError = ""
            return
        }

        if (pin !== confirmPin) {
            pinError = "Os PINs nao coincidem. Tente novamente."
            pin = ""
            confirmPin = ""
            confirmingPin = false
            return
        }

        if (app.createNewWallet(pin)) {
            mnemonic = app.getMnemonic()
            currentStep = 1
        }
    }

    background: Rectangle { color: theme.background }

    header: ToolBar {
        Material.background: theme.background
        height: 58

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            ToolButton {
                text: "‹"
                font.pixelSize: 28
                Material.foreground: theme.textPrimary
                onClicked: {
                    if (currentStep > 0) {
                        currentStep--
                    } else if (confirmingPin) {
                        confirmingPin = false
                        confirmPin = ""
                        pinError = ""
                    } else {
                        createWalletPage.back()
                    }
                }
            }

            Label {
                text: ["PIN de Acesso", "Backup da Wallet", "Confirmacao"][currentStep]
                font.pixelSize: 16
                font.bold: true
                color: theme.textPrimary
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Item { Layout.preferredWidth: 48 }
        }
    }

    ProgressBar {
        anchors.top: parent.top
        width: parent.width
        value: (currentStep + 1) / 3
        Material.accent: currentStep === 0 ? theme.electricBlue : theme.neonGreen
        background: Rectangle { color: theme.surface }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.pageMargin
        spacing: 16
        visible: currentStep === 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 12 }

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "back"]
                delegate: Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    enabled: modelData !== ""
                    text: modelData === "back" ? "⌫" : modelData
                    font.pixelSize: modelData === "back" ? 20 : 22
                    font.bold: modelData !== "back"
                    Material.foreground: modelData === "back" ? theme.textSecondary : theme.textPrimary
                    background: Rectangle {
                        radius: theme.radiusLarge
                        color: parent.down ? theme.surfaceHigh : theme.surface
                        border.color: parent.down ? theme.electricBlue : theme.outline
                        border.width: 1
                    }
                    onClicked: {
                        pinError = ""
                        if (modelData === "back")
                            backspacePin()
                        else
                            appendDigit(modelData)
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 8
            text: "O PIN e usado apenas localmente para proteger o arquivo da carteira."
            font.pixelSize: 11
            color: theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.pageMargin
        spacing: 14
        visible: currentStep === 1

        Label {
            text: "Anote estas 12 palavras em ordem"
            font.pixelSize: 20
            font.bold: true
            color: theme.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Esta e a unica forma de recuperar a carteira se voce perder o dispositivo."
            font.pixelSize: 13
            color: theme.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: mnemonic
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: theme.radiusSmall
                    color: theme.surface
                    border.color: theme.outline
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 5

                        Label {
                            text: (index + 1) + "."
                            font.pixelSize: 11
                            color: theme.textMuted
                            Layout.preferredWidth: 18
                        }

                        Label {
                            text: modelData
                            font.pixelSize: 14
                            font.bold: true
                            color: theme.neonGreen
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: warningText.implicitHeight + 22
            radius: theme.radius
            color: "#20170B"
            border.color: theme.warning

            Label {
                id: warningText

                anchors.margins: 11
                text: "Guarde offline. Nunca fotografe, publique ou envie sua frase de recuperacao."
                font.pixelSize: 12
                color: theme.warning
                wrapMode: Text.WordWrap
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                text: "Copiar"
                flat: true

                Material.foreground: theme.electricBlue
                background: Rectangle {
                    radius: theme.radius
                    color: "transparent"
                    border.color: theme.electricBlue
                    border.width: 1
                }
                onClicked: app.copyToClipboard(mnemonic.join(" "))
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                text: "Ja anotei"
                font.bold: true
                Material.foreground: theme.onAccent
                background: Rectangle {
                    radius: theme.radius
                    color: parent.down ? "#17D68F" : theme.neonGreen
                }
                onClicked: currentStep = 2
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.pageMargin
        spacing: 14
        visible: currentStep === 2

        Label {
            text: "Confirme a frase de recuperacao"
            font.pixelSize: 22
            font.bold: true
            color: theme.textPrimary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label {
            text: "Digite as 12 palavras para confirmar que o backup foi salvo corretamente."
            font.pixelSize: 13

            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        TextArea {
            id: verifyMnemonicField
            Layout.fillWidth: true

            Layout.preferredHeight: 132
            placeholderText: "palavra1 palavra2 ... palavra12"
            color: theme.textPrimary
            placeholderTextColor: theme.textMuted
            font.pixelSize: 15
            wrapMode: TextEdit.WordWrap
            background: Rectangle {
                radius: theme.radius
                color: theme.surface
                border.color: verifyMnemonicField.activeFocus ? theme.electricBlue : theme.outline
                border.width: verifyMnemonicField.activeFocus ? 2 : 1
            }
        }

        Label {
            text: {
                if (verifyMnemonicField.text.trim().split(/\s+/).length < 12)
                    return ""
                return app.verifyMnemonic(verifyMnemonicField.text.trim())
                       ? "Frase confirmada"
                       : "Frase incorreta. Verifique a ordem das palavras."
            }
            font.pixelSize: 13
            font.bold: true
            color: app.verifyMnemonic(verifyMnemonicField.text.trim()) ? theme.neonGreen : theme.danger
            visible: verifyMnemonicField.text.trim().split(/\s+/).length >= 12
        }

        Item { Layout.fillHeight: true }

        Button {
            Layout.fillWidth: true

            Layout.preferredHeight: 56
            text: "Concluir Criacao da Carteira"
            font.pixelSize: 15
            font.bold: true
            enabled: app.verifyMnemonic(verifyMnemonicField.text.trim())
            Material.foreground: enabled ? theme.onAccent : theme.textMuted
            background: Rectangle {
                radius: theme.radius
                color: parent.enabled ? theme.neonGreen : theme.slate
            }
            onClicked: createWalletPage.walletCreated()
        }
    }
}
