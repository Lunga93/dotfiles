// Pill-shaped device selector. Active state fills with accent.

import QtQuick

Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    implicitHeight: 28
    implicitWidth: row.implicitWidth + 24

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusPill
        color: root.active
            ? Theme.accent
            : (mouse.pressed
                ? Theme.surfacePressed
                : (mouse.containsMouse ? Theme.surfaceHover : Theme.surfaceElev))
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.icon
            color: root.active ? Theme.background : Theme.textSecondary
            font.pixelSize: 13
            font.family: Theme.fontMono
            renderType: Text.NativeRendering
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }
        Text {
            text: root.label
            color: root.active ? Theme.background : Theme.textPrimary
            font.pixelSize: 12
            font.family: Theme.fontFamily
            font.weight: root.active ? Font.Medium : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

