// Copyright (c) 2026 - 2X2Coin Project
// Componente de cabeçalho de página

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: pageHeader
    property string title: ""
    property string subtitle: ""

    Layout.fillWidth: true
    width: parent ? parent.width : 390
    height: 64
    color: "#1A1A2E"

    // Linha decorativa inferior
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#333355"
    }

    // Linha de destaque
    Rectangle {
        anchors.bottom: parent.bottom
        width: 60
        height: 2
        color: "#00D4AA"
        anchors.horizontalCenter: parent.horizontalCenter
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Label {
            text: pageHeader.title
            font.pixelSize: 18
            font.bold: true
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: pageHeader.subtitle
            font.pixelSize: 12
            color: "#8899AA"
            Layout.alignment: Qt.AlignHCenter
            visible: pageHeader.subtitle.length > 0
        }
    }
}
