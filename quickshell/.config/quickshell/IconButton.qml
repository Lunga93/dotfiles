// Circular icon button. Used inside popouts.

import QtQuick

Item {
    id: root
    property string icon: ""
    property bool active: false
    property color tintActive: Theme.destructive
    property int diameter: 34
    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: width / 2
        color: mouse.pressed
            ? Theme.surfacePressed
            : (mouse.containsMouse ? Theme.surfaceHover : Theme.surfaceElev)
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.tintActive : Theme.textPrimary
        font.pixelSize: Math.round(root.diameter * 0.46)
        font.family: Theme.fontMono
        renderType: Text.NativeRendering
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
