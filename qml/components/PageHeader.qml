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
    property bool compact: false
    property bool showBack: false

    AppTheme { id: theme }

    Layout.fillWidth: true
    width: parent ? parent.width : 390
    height: compact ? 56 : 72
    color: theme.background

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: theme.outline
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: 64
        height: 2
        color: theme.electricBlue
        anchors.horizontalCenter: parent.horizontalCenter
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Label {
            text: pageHeader.title
            font.pixelSize: compact ? 17 : 20
            font.bold: true
            color: theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: pageHeader.subtitle
            font.pixelSize: 12
            color: theme.textSecondary
            Layout.alignment: Qt.AlignHCenter
            visible: pageHeader.subtitle.length > 0
        }
    }
}
