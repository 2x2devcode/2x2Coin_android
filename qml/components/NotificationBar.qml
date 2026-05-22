// Copyright (c) 2026 - 2X2Coin Project
// Barra de notificação de transações

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: notifBar
    height: visible ? 56 : 0
    color: "#00D4AA"
    visible: false
    z: 100

    property string notifTitle: ""
    property string notifMessage: ""

    function show(title, message) {
        notifTitle = title
        notifMessage = message
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 4000
        onTriggered: hideAnimation.start()
    }

    NumberAnimation {
        id: hideAnimation
        target: notifBar
        property: "opacity"
        to: 0
        duration: 300
        onFinished: {
            notifBar.visible = false
            notifBar.opacity = 1
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: "🔔"
            font.pixelSize: 18
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label {
                text: notifTitle
                font.pixelSize: 13
                font.bold: true
                color: "#0F0F1A"
            }
            Label {
                text: notifMessage
                font.pixelSize: 12
                color: "#0F0F1A"
            }
        }

        RoundButton {
            width: 28
            height: 28
            text: "✕"
            font.pixelSize: 12
            Material.background: "transparent"
            Material.foreground: "#0F0F1A"
            onClicked: hideAnimation.start()
        }
    }
}
