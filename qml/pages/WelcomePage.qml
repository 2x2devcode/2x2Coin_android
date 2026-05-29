// Copyright (c) 2026 - 2X2Coin Project
// Minimal first-run welcome screen.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Page {
    id: welcomePage
    signal createWallet()
    signal restoreWallet()

    AppTheme { id: theme }

    background: Rectangle {
        color: theme.background

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 1.25
            height: parent.height * 0.45
            radius: height / 2
            opacity: 0.28
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: theme.electricBlue }
                GradientStop { position: 1.0; color: theme.neonGreen }
            }
            y: -height * 0.55
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.pageMargin + 6
        spacing: 0

        Item { Layout.fillHeight: true; Layout.minimumHeight: 36 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 18

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 112
                height: 112
                radius: 28
                color: theme.surface
                border.color: theme.outlineStrong
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 76
                    height: 76
                    source: "qrc:/assets/images/logo_2x2coin.png"
                    fillMode: Image.PreserveAspectFit
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 54
                    height: 3
                    radius: 2
                    color: theme.neonGreen
                    opacity: 0.9
                }
            }

            Label {
                Layout.fillWidth: true
                text: "2x2Coin Wallet"
                font.pixelSize: 34
                font.bold: true
                color: theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Nó nativo C++ com blockchain local, chaves privadas no dispositivo e interface dark minimalista."
                font.pixelSize: 14
                lineHeight: 1.2
                color: theme.textSecondary
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 44 }

        Rectangle {
            Layout.fillWidth: true
            radius: theme.radiusLarge
            color: theme.surface
            border.color: theme.outline
            border.width: 1
            implicitHeight: featureLayout.implicitHeight + 32

            ColumnLayout {
                id: featureLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Repeater {
                    model: [
                        { mark: "01", title: "Carteira HD local", subtitle: "Criação, abertura e restauração sem custódia." },
                        { mark: "02", title: "Rede descentralizada", subtitle: "Sincronização direta com peers 2x2Coin." },
                        { mark: "03", title: "Design noturno", subtitle: "Alto contraste com azul e verde elétrico oficiais." }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            radius: 17
                            color: index === 1 ? theme.electricBlueSoft : theme.neonGreenSoft
                            border.color: index === 1 ? theme.electricBlue : theme.neonGreen

                            Label {
                                anchors.centerIn: parent
                                text: modelData.mark
                                color: index === 1 ? theme.electricBlue : theme.neonGreen
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: modelData.title; color: theme.textPrimary; font.pixelSize: 14; font.bold: true }
                            Label { text: modelData.subtitle; color: theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.minimumHeight: 36 }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                text: "Criar Nova Carteira"
                font.pixelSize: 16
                font.bold: true
                Material.foreground: theme.onAccent
                background: Rectangle {
                    radius: theme.radius
                    color: parent.down ? "#17D68F" : theme.neonGreen
                }
                onClicked: welcomePage.createWallet()
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                text: "Abrir Carteira Existente"
                font.pixelSize: 16
                font.bold: true
                flat: true
                Material.foreground: theme.electricBlue
                background: Rectangle {
                    radius: theme.radius
                    color: parent.down ? "#122337" : "transparent"
                    border.color: theme.electricBlue
                    border.width: 1
                }
                onClicked: welcomePage.restoreWallet()
            }
        }

        Label {
            text: "Suas chaves privadas nunca saem deste dispositivo."
            font.pixelSize: 11
            color: theme.textMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: 18
        }

        Item { Layout.minimumHeight: 14 }
    }
}
