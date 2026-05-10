import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root
    property color swatchColor: Theme.accent
    property bool selected: false
    signal clicked

    width: 36
    height: 36

    // Outer ring (selection indicator)
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: root.swatchColor
        border.width: root.selected ? 2 : 0
        opacity: root.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // The swatch itself
    Rectangle {
        id: dot
        anchors.centerIn: parent
        width: 26
        height: 26
        radius: 13
        color: root.swatchColor
        border.color: Qt.rgba(0, 0, 0, 0.3)
        border.width: 1

        scale: swatchArea.pressed ? 0.85 : (swatchArea.containsMouse ? 1.1 : 1.0)
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        // Inner highlight for sphere look
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 3
            width: parent.width * 0.55
            height: parent.height * 0.35
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.25)
        }

        MouseArea {
            id: swatchArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
