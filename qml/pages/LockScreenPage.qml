// Copyright (c) 2026 - 2X2Coin Project
// Tela de bloqueio/desbloqueio da wallet 2X2Coin

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Page {
    id: lockScreen
    signal unlocked()

    AppTheme { id: theme }

    property int failedAttempts: 0
    property bool isLocked: failedAttempts >= 5

    background: Rectangle {
        color: theme.background
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 1.1
            height: 220
            radius: 110
            y: -120
            opacity: 0.22
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: theme.electricBlue }
                GradientStop { position: 1.0; color: theme.neonGreen }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 0

        Item { Layout.fillHeight: true }

        // Logo
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 90
                height: 90
                radius: 24
                color: theme.surface
                border.color: theme.neonGreen
                border.width: 1

                Label {
                    anchors.centerIn: parent
                    text: "2X2"
                    font.pixelSize: 26
                    font.bold: true
                    color: theme.neonGreen
                }
            }

            Label {
                text: "2X2Coin Wallet"
                font.pixelSize: 24
                font.bold: true
                color: theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Carteira Bloqueada"
                font.pixelSize: 14
                color: theme.textSecondary
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 40 }

        // Campo de senha
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Digite sua senha"
                echoMode: TextInput.Password
                color: theme.textPrimary
                placeholderTextColor: theme.textMuted
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                enabled: !isLocked

                background: Rectangle {
                    radius: 12
                    color: theme.surface
                    border.color: {
                        if (lockScreen.failedAttempts > 0) return theme.danger
                        return passwordField.activeFocus ? theme.electricBlue : theme.outline
                    }
                    border.width: passwordField.activeFocus ? 2 : 1
                }

                Keys.onReturnPressed: unlockButton.clicked()
                Keys.onEnterPressed: unlockButton.clicked()
            }

            // Mensagem de erro
            Label {
                text: {
                    if (isLocked) return "Muitas tentativas incorretas. Aguarde."
                    if (failedAttempts > 0) return "Senha incorreta. Tentativas: " + failedAttempts + "/5"
                    return ""
                }
                font.pixelSize: 12
                color: theme.danger
                Layout.alignment: Qt.AlignHCenter
                visible: failedAttempts > 0
            }

            // Botão desbloquear
            Button {
                id: unlockButton
                Layout.fillWidth: true
                height: 56
                text: isLocked ? "Bloqueado" : "Desbloquear"
                font.pixelSize: 16
                font.bold: true
                enabled: !isLocked && passwordField.text.length > 0
                Material.background: enabled ? theme.neonGreen : theme.slate
                Material.foreground: enabled ? theme.onAccent : theme.textMuted

                onClicked: {
                    if (app.unlockWallet(passwordField.text)) {
                        failedAttempts = 0
                        lockScreen.unlocked()
                    } else {
                        failedAttempts++
                        passwordField.text = ""

                        // Animação de erro
                        shakeAnimation.start()
                    }
                }
            }

            // Biometria (se disponível)
            Button {
                Layout.fillWidth: true
                height: 48
                text: "Usar Biometria"
                flat: true
                Material.foreground: theme.electricBlue
                visible: app.isBiometricAvailable()
                onClicked: app.authenticateWithBiometric()
            }
        }

        Item { Layout.fillHeight: true }

        // Opção de restaurar
        Label {
            text: "Esqueceu a senha? Restaure com sua frase de recuperação"
            font.pixelSize: 12
            color: theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.bottomMargin: 16
    } // Fecha o Layout/Column anterior

    // Animação de erro (shake) - Agora estruturada corretamente
    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: passwordField; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: passwordField; property: "x"; to: 10;  duration: 50 }
        NumberAnimation { target: passwordField; property: "x"; to: -8;  duration: 50 }
        NumberAnimation { target: passwordField; property: "x"; to: 8;   duration: 50 }
        NumberAnimation { target: passwordField; property: "x"; to: 0;   duration: 50 }
    }

    // Conexão com resultado de biometria
    Connections {
        target: app
        function onBiometricResult(success) {
            if (success) lockScreen.unlocked()
        }
    }
}
