import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import "../components"

Page {
    id: settingsPage
    signal lockWallet()

    AppTheme { id: theme }

    background: Rectangle { color: theme.background }

    header: PageHeader {
        title: "Configurações"
        subtitle: "Wallet, blockchain e segurança"
        showBack: false
    }

    function notify(message) {
        app.showNotification("2x2Coin Wallet", message)
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
            anchors.margins: theme.pageMargin
            spacing: 18

            Label {
                text: "WALLET"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.1
                color: theme.textMuted
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        {
                            title: "Re-sincronizar Blockchain",
                            subtitle: "Reconectar e baixar blocos novamente",
                            icon: "qrc:/assets/icons/network.svg",
                            accent: theme.warning,
                            action: "resync"
                        },
                        {
                            title: "Backup da Wallet no Dispositivo",
                            subtitle: "Exportação local criptografada",
                            icon: "qrc:/assets/icons/backup.svg",
                            accent: theme.neonGreen,
                            action: "backup"
                        },
                        {
                            title: "Trocar Senha de Acesso",
                            subtitle: "Atualizar PIN/senha local",
                            icon: "qrc:/assets/icons/lock.svg",
                            accent: theme.electricBlue,
                            action: "password"
                        },
                        {
                            title: "Criar Nova Carteira",
                            subtitle: "Iniciar novo cofre local",
                            icon: "qrc:/assets/icons/export.svg",
                            accent: theme.textSecondary,
                            action: "new"
                        },
                        {
                            title: "Abrir Carteira Existente",
                            subtitle: "Importar ou restaurar por frase",
                            icon: "qrc:/assets/icons/import.svg",
                            accent: theme.textSecondary,
                            action: "open"
                        },
                        {
                            title: "Fechar Aplicativo",
                            subtitle: "Bloquear a wallet e sair",
                            icon: "qrc:/assets/icons/unlock.svg",
                            accent: theme.danger,
                            action: "close"
                        }
                    ]

                    delegate: Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76
                        leftPadding: 0
                        rightPadding: 0
                        topPadding: 0
                        bottomPadding: 0
                        background: Rectangle {
                            radius: theme.radius
                            color: parent.down ? theme.surfaceHigh : theme.surface
                            border.color: modelData.action === "resync" ? theme.warning : theme.outline
                            border.width: 1
                        }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                radius: 12
                                color: modelData.action === "resync" ? "#261A0A" : theme.backgroundRaised
                                border.color: modelData.accent

                                Image {
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: modelData.icon
                                    sourceSize: Qt.size(22, 22)
                                    opacity: 0.85
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Label {
                                    text: modelData.title
                                    color: theme.textPrimary
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: modelData.subtitle
                                    color: theme.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Label {
                                text: "›"
                                color: modelData.accent
                                font.pixelSize: 24
                            }
                        }
                        onClicked: {
                            if (modelData.action === "resync") {
                                app.disconnectFromNetwork()
                                app.connectToNetwork()
                                notify("Re-sincronização da blockchain iniciada.")
                            } else if (modelData.action === "backup") {
                                backupDialog.open()
                            } else if (modelData.action === "password") {
                                passwordDialog.open()
                            } else if (modelData.action === "new") {
                                notify("Use o onboarding para criar uma nova carteira com backup seguro.")
                            } else if (modelData.action === "open") {
                                notify("Use Abrir Carteira Existente no primeiro acesso para restaurar por frase.")
                            } else if (modelData.action === "close") {
                                app.lockWallet()
                                settingsPage.lockWallet()
                                Qt.quit()
                            }
                        }
                    }
                }
            }

            Label {
                text: "SOBRE"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.1
                color: theme.textMuted
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                radius: theme.radiusLarge
                color: theme.surface
                border.color: theme.outline
                implicitHeight: aboutLayout.implicitHeight + 32

                ColumnLayout {
                    id: aboutLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Image {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            source: "qrc:/assets/images/logo_2x2coin.png"
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: "2x2Coin Wallet"; color: theme.textPrimary; font.pixelSize: 16; font.bold: true }
                            Label { text: "Versão da carteira: v2.0.2"; color: theme.textSecondary; font.pixelSize: 12 }
                        }
                    }

                    Repeater {
                        model: [
                            { title: "Site Oficial", url: "https://2x2coin.com" },
                            { title: "Explorer da Moeda", url: "https://explorer.2x2coin.com" },
                            { title: "Repositório GitHub", url: "https://github.com/coinsdevcode/2x2Coin" }
                        ]

                        delegate: Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            text: modelData.title
                            font.pixelSize: 13
                            font.bold: true
                            Material.foreground: theme.electricBlue
                            background: Rectangle {
                                radius: theme.radiusSmall
                                color: parent.down ? theme.electricBlueSoft : theme.backgroundRaised
                                border.color: theme.outline
                            }
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "Idioma"
                            color: theme.textSecondary
                            font.pixelSize: 12
                            font.bold: true
                        }

                        ComboBox {
                            Layout.fillWidth: true
                            model: [
                                "🇧🇷 Português", "🇺🇸 English", "🇪🇸 Español", "🇫🇷 Français",
                                "🇩🇪 Deutsch", "🇮🇹 Italiano", "🇯🇵 日本語", "🇰🇷 한국어",
                                "🇨🇳 中文", "🇮🇳 हिन्दी", "🇸🇦 العربية", "🇷🇺 Русский"
                            ]
                            Material.foreground: theme.textPrimary
                            Material.background: theme.backgroundRaised
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: backupDialog
        title: "Backup da Wallet"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 12

            Label {
                text: "Exportar um backup criptografado para o armazenamento local do dispositivo."
                color: theme.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: backupPathField
                Layout.fillWidth: true
                text: "2x2coin-wallet-backup.dat"
                color: theme.textPrimary
                background: Rectangle {
                    radius: theme.radius
                    color: theme.surface
                    border.color: theme.outline
                }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "Exportar"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Material.background: theme.neonGreen
                Material.foreground: theme.onAccent
            }
        }

        onAccepted: {
            if (app.backupWallet(backupPathField.text))
                notify("Backup exportado no dispositivo.")
            else
                notify("Não foi possível exportar o backup.")
        }
    }

    Dialog {
        id: passwordDialog
        title: "Trocar Senha de Acesso"
        modal: true
        anchors.centerIn: parent
        width: parent.width - 32
        standardButtons: Dialog.Cancel

        ColumnLayout {
            width: parent.width
            spacing: 10

            TextField {
                id: oldPasswordField
                Layout.fillWidth: true
                placeholderText: "Senha/PIN atual"
                echoMode: TextInput.Password
                color: theme.textPrimary
                background: Rectangle { radius: theme.radius; color: theme.surface; border.color: theme.outline }
            }

            TextField {
                id: newPasswordField
                Layout.fillWidth: true
                placeholderText: "Nova senha/PIN"
                echoMode: TextInput.Password
                color: theme.textPrimary
                background: Rectangle { radius: theme.radius; color: theme.surface; border.color: theme.outline }
            }

            Label {
                text: "Use uma senha forte ou PIN longo para proteger o arquivo da carteira."
                color: theme.textSecondary
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "Salvar"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                enabled: oldPasswordField.text.length > 0 && newPasswordField.text.length >= 6
                Material.background: enabled ? theme.electricBlue : theme.slate
                Material.foreground: theme.textPrimary
            }
        }

        onAccepted: {
            if (app.changePassword(oldPasswordField.text, newPasswordField.text))
                notify("Senha de acesso atualizada.")
            else
                notify("Não foi possível alterar a senha.")
            oldPasswordField.text = ""
            newPasswordField.text = ""
        }
    }
}
