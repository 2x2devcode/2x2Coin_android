// Copyright (c) 2026 - 2X2Coin Project
// Balance dashboard for the 2x2Coin wallet.

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import "../components"

Item {
    id: overviewTab
    signal openSend()
    signal openReceive()
    signal openSettings()

    AppTheme { id: theme }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width
        background: Rectangle { color: theme.background }

        ColumnLayout {
            width: parent.width
            spacing: 18

            Rectangle {
                Layout.fillWidth: true
                Layout.margins: theme.pageMargin
                Layout.bottomMargin: 0
                radius: theme.radiusLarge
                color: theme.surface
                border.color: theme.outline
                border.width: 1
                implicitHeight: syncLayout.implicitHeight + 26

                ColumnLayout {
                    id: syncLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 10
                            Layout.preferredHeight: 10
                            radius: 5
                            color: app.isConnected ? theme.neonGreen : theme.danger

                            SequentialAnimation on opacity {
                                running: app.isSyncing
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.35; duration: 650 }
                                NumberAnimation { to: 1.0; duration: 650 }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: app.isSyncing ? "Sincronizando com a rede..." : "Blockchain Atualizada"
                            color: theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Label {
                            text: app.peerCount + " peers"
                            color: theme.textSecondary
                            font.pixelSize: 11
                            visible: app.isConnected
                        }
                    }

                    ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        value: app.isSyncing ? 0.68 : 1.0
                        indeterminate: app.isSyncing
                        background: Rectangle {
                            radius: 2
                            color: theme.slate
                        }
                        contentItem: Item {
                            Rectangle {
                                width: parent.width * syncProgress.visualPosition
                                height: parent.height
                                radius: 2
                                color: app.isSyncing ? theme.electricBlue : theme.neonGreen
                            }
                        }
                        id: syncProgress
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Último Bloco Sincronizado: #" + app.blockHeight
                        color: theme.textMuted
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                radius: 26
                border.color: theme.outlineStrong
                border.width: 1
                implicitHeight: balanceLayout.implicitHeight + 42
                gradient: Gradient {
                    orientation: Gradient.Diagonal
                    GradientStop { position: 0.0; color: "#121A24" }
                    GradientStop { position: 0.55; color: "#0B1119" }
                    GradientStop { position: 1.0; color: "#071511" }
                }

                ColumnLayout {
                    id: balanceLayout
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            text: "Saldo total"
                            color: theme.textSecondary
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            radius: 10
                            color: theme.electricBlueSoft
                            implicitWidth: networkLabel.implicitWidth + 18
                            implicitHeight: 26
                            border.color: theme.electricBlue
                            Label {
                                id: networkLabel
                                anchors.centerIn: parent
                                text: app.networkName
                                color: theme.electricBlue
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    Label {
                        id: balanceLabel
                        Layout.fillWidth: true
                        text: app.balance
                        color: theme.textPrimary
                        font.pixelSize: 38
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WrapAnywhere

                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "≈ R$ 0,00"
                        color: theme.textSecondary
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 58
                            radius: theme.radius
                            color: theme.backgroundRaised
                            border.color: theme.outline
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Label { text: "Pendente"; color: theme.textMuted; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                                Label { text: app.unconfBalance; color: theme.warning; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 58
                            radius: theme.radius
                            color: theme.backgroundRaised
                            border.color: theme.outline
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Label { text: "Total"; color: theme.textMuted; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                                Label { text: app.totalBalance; color: theme.neonGreen; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }
            }

            Label {
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                Layout.fillWidth: true
                text: "Ações rápidas"
                color: theme.textPrimary
                font.pixelSize: 18
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: theme.pageMargin
                Layout.rightMargin: theme.pageMargin
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    text: "Enviar"
                    font.pixelSize: 13
                    font.bold: true
                    icon.source: "qrc:/assets/icons/send.svg"
                    icon.color: theme.electricBlue
                    icon.width: 26
                    icon.height: 26
                    display: AbstractButton.TextUnderIcon
                    Material.foreground: theme.textPrimary
                    background: Rectangle {
                        radius: theme.radiusLarge
                        color: parent.down ? theme.surfaceHigh : theme.surface
                        border.color: theme.electricBlue
                        border.width: 1
                    }
                    onClicked: overviewTab.openSend()
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    text: "Receber\nDepósitos"
                    font.pixelSize: 13
                    font.bold: true
                    icon.source: "qrc:/assets/icons/receive.svg"
                    icon.color: theme.neonGreen
                    icon.width: 26
                    icon.height: 26
                    display: AbstractButton.TextUnderIcon
                    Material.foreground: theme.textPrimary
                    background: Rectangle {
                        radius: theme.radiusLarge
                        color: parent.down ? theme.surfaceHigh : theme.surface
                        border.color: theme.neonGreen
                        border.width: 1
                    }
                    onClicked: overviewTab.openReceive()
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    text: "Configurações"
                    font.pixelSize: 13
                    font.bold: true
                    icon.source: "qrc:/assets/icons/settings.svg"
                    icon.color: theme.textSecondary
                    icon.width: 26
                    icon.height: 26
                    display: AbstractButton.TextUnderIcon
                    Material.foreground: theme.textPrimary
                    background: Rectangle {
                        radius: theme.radiusLarge
                        color: parent.down ? theme.surfaceHigh : theme.surface
                        border.color: theme.outline
                        border.width: 1
                    }
                    onClicked: overviewTab.openSettings()
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
                implicitHeight: nodeLayout.implicitHeight + 28

                ColumnLayout {
                    id: nodeLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 7

                    Label {
                        text: "Nó nativo 2x2Coin"
                        color: theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Blockchain local em C++ baseada no repositório oficial coinsdevcode/2x2Coin."
                        color: theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
