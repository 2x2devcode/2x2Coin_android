import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import "../components"

Page {
    id: settingsPage
    background: Rectangle { color: "#0F0F1A" }

    header: PageHeader {
        title: "Settings"
        showBack: false
    }

    Flickable {
        anchors.fill: parent
        contentHeight: settingsLayout.height + 40
        clip: true

        ColumnLayout {
            id: settingsLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 0

            // Seção: Aplicativo
            Label {
                text: "APPLICATION"
                font.pixelSize: 13; font.bold: true; color: "#8899AA"
                topPadding: 12; bottomPadding: 8; Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/icons/settings.svg"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "Dark Theme"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "Use dark colors to save battery"; color: "#8899AA"; font.pixelSize: 12 }
                    }
                    Switch { checked: app.settings.darkTheme; onClicked: app.settings.darkTheme = checked }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/icons/history.svg"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "Notifications"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "Alerts for incoming transactions"; color: "#8899AA"; font.pixelSize: 12 }
                    }
                    Switch { checked: app.settings.notifications; onClicked: app.settings.notifications = checked }
                }
            }

            // Seção: Segurança
            Label {
                text: "SECURITY"
                font.pixelSize: 13; font.bold: true; color: "#8899AA"
                topPadding: 20; bottomPadding: 8; Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/icons/lock.svg"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "Biometrics"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "Use fingerprint to unlock"; color: "#8899AA"; font.pixelSize: 12 }
                    }
                    Switch { checked: app.settings.biometric; onClicked: app.settings.biometric = checked }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                MouseArea { anchors.fill: parent; onClicked: backupDialog.open() }
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/icons/backup.svg"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "Wallet Backup"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "View recovery mnemonic phrase"; color: "#8899AA"; font.pixelSize: 12 }
                    }
                }
            }

            // Seção: Rede
            Label {
                text: "NETWORK"
                font.pixelSize: 13; font.bold: true; color: "#8899AA"
                topPadding: 20; bottomPadding: 8; Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/icons/network.svg"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "Testnet Mode"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "Use test network for developers"; color: "#8899AA"; font.pixelSize: 12 }
                    }
                    Switch { checked: app.settings.testnet; onClicked: app.settings.testnet = checked }
                }
            }

            // Seção: Sobre
            Label {
                text: "ABOUT"
                font.pixelSize: 13; font.bold: true; color: "#8899AA"
                topPadding: 20; bottomPadding: 8; Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                RowLayout {
                    anchors.fill: parent; spacing: 16
                    Image { source: "qrc:/assets/images/logo_2x2coin.png"; width: 24; height: 24; sourceSize: Qt.size(24, 24) }
                    ColumnLayout {
                        spacing: 0; Layout.fillWidth: true
                        Label { text: "2X2Coin Wallet"; color: "#FFFFFF"; font.pixelSize: 15 }
                        Label { text: "Versão " + app.version; color: "#8899AA"; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    // Diálogos
    Dialog {
        id: backupDialog
        title: "Security Backup"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Close

        ColumnLayout {
            width: parent.width
            spacing: 16
            Label {
                text: "Your recovery phrase (12 words):"
                color: "#8899AA"; font.pixelSize: 13
            }
            Rectangle {
                Layout.fillWidth: true; height: 100; color: "#1A1A2E"; radius: 8
                Label {
                    anchors.fill: parent; anchors.margins: 12
                    text: "word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12"
                    wrapMode: Text.WordWrap; color: "#00D4AA"; font.bold: true; horizontalAlignment: Text.AlignHCenter
                }
            }
            Label {
                text: "WARNING: Never share these words with anyone. They provide full access to your funds."
                color: "#FF5555"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true
            }
        }
    }
}
