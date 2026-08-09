// Collapsible-free settings card: accent-bar header + bordered surface.
// Default property collects rows, so groups read like markup:

import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Column {
    id: root
    property string header: ""
    property color accent: Theme.primary
    property alias spacing: col.spacing

    width: parent.width

    Row {
        spacing: 8
        leftPadding: 16
        topPadding: 12
        bottomPadding: 8
        visible: root.header !== ""

        Rectangle {
            width: 3; height: 12; radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.accent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.header
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 0.6
        }
    }

    Rectangle {
        width: parent.width
        height: col.height
        radius: Theme.radiusCard
        color: Theme.surfaceElev
        border.color: Theme.border
        border.width: 1
        clip: true

        Column {
            id: col
            width: parent.width
        }
    }
}
