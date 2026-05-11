import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Item {
    id: root
    property bool checked: false
    signal toggled(bool state)

    width: 44
    height: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: 13
        color: root.checked ? Theme.secondary : "#2c2519"
        border.color: root.checked ? Qt.darker(Theme.secondary, 1.2) : "#0e0a06"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            id: thumb
            width: 20
            height: 20
            radius: 10
            color: "#ffffff"
            x: root.checked ? parent.width - width - 3 : 3
            y: 3
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Inner highlight
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 2
                width: parent.width * 0.7
                height: parent.height * 0.4
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.5)
            }

            scale: pressArea.pressed ? 1.1 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }
        }

        MouseArea {
            id: pressArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }
}
