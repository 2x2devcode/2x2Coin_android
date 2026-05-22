// Copyright (c) 2026 - 2X2Coin Project
// Snackbar para mensagens rápidas

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15

Rectangle {
    id: snackbar
    width: Math.min(parent ? parent.width - 32 : 320, 400)
    height: 48
    radius: 24
    color: "#333355"
    visible: false
    opacity: 0

    property string message: ""

    function show(msg) {
        message = msg
        visible = true
        showAnim.start()
        hideTimer.restart()
    }

    NumberAnimation {
        id: showAnim
        target: snackbar
        property: "opacity"
        to: 1
        duration: 200
    }

    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: hideAnim.start()
    }

    NumberAnimation {
        id: hideAnim
        target: snackbar
        property: "opacity"
        to: 0
        duration: 300
        onFinished: snackbar.visible = false
    }

    Label {
        anchors.centerIn: parent
        text: snackbar.message
        font.pixelSize: 14
        color: "#FFFFFF"
        horizontalAlignment: Text.AlignHCenter
    }
}
