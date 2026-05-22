// Copyright (c) 2026 - 2X2Coin Project
// Tela de boas-vindas - primeira execução

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: welcomePage
    signal createWallet()
    signal restoreWallet()

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0F0F1A" }
            GradientStop { position: 0.5; color: "#1A1A2E" }
            GradientStop { position: 1.0; color: "#0A1520" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 40 }

        // Logo e nome
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Logo animado
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                gradient: Gradient {
                    orientation: Gradient.Diagonal
                    GradientStop { position: 0.0; color: "#00D4AA" }
                    GradientStop { position: 1.0; color: "#0088FF" }
                }

                // Sombra
                layer.enabled: true

                Label {
                    anchors.centerIn: parent
                    text: "2X2"
                    font.pixelSize: 36
                    font.bold: true
                    color: "#FFFFFF"
                }

                // Animação de pulso
                SequentialAnimation on scale {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.05; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.00; duration: 1500; easing.type: Easing.InOutSine }
                }
            }

            Label {
                text: "2X2Coin"
                font.pixelSize: 36
                font.bold: true
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Carteira Digital Segura"
                font.pixelSize: 16
                color: "#00D4AA"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 40 }

        // Características
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [
                    { icon: "🔐", text: "Carteira HD (BIP32/BIP44) com 12 palavras" },
                    { icon: "⚡", text: "Suporte a PoW e PoS (após bloco 110.000)" },
                    { icon: "🌐", text: "Conexão direta com a rede 2X2Coin" },
                    { icon: "🔒", text: "Chaves privadas armazenadas localmente" }
                ]

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: modelData.icon
                        font.pixelSize: 20
                    }

                    Label {
                        text: modelData.text
                        font.pixelSize: 14
                        color: "#CCDDEE"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 40 }

        // Botões de ação
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                height: 56
                text: "✦  Criar Nova Carteira"
                font.pixelSize: 16
                font.bold: true
                Material.background: "#00D4AA"
                Material.foreground: "#0F0F1A"
                onClicked: welcomePage.createWallet()
            }

            Button {
                Layout.fillWidth: true
                height: 56
                text: "↺  Restaurar Carteira Existente"
                font.pixelSize: 16
                font.bold: true
                flat: false
                Material.background: "transparent"
                Material.foreground: "#00D4AA"
                background: Rectangle {
                    radius: 4
                    color: "transparent"
                    border.color: "#00D4AA"
                    border.width: 2
                }
                onClicked: welcomePage.restoreWallet()
            }
        }

        // Aviso de segurança
        Label {
            text: "Suas chaves privadas são armazenadas apenas neste dispositivo.\n" +
                  "Nunca compartilhe sua frase de recuperação."
            font.pixelSize: 11
            color: "#555566"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: 16
        }

        Item { Layout.minimumHeight: 20 }
    }
}
