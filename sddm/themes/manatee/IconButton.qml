import QtQuick
import "."

Item {
    id: root

    property var colors
    property string icon: ""
    property string label: ""
    property real iconSize: 16
    property bool destructive: false

    signal clicked()

    width: Theme.iconButtonSize
    height: Theme.iconButtonSize + (label.length > 0 ? 18 : 0)

    Rectangle {
        id: bg
        width: Theme.iconButtonSize
        height: Theme.iconButtonSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        radius: Theme.radiusRound
        color: ma.pressed ? (root.colors ? root.colors.surfacePressed : "#33ffffff")
             : ma.containsMouse ? (root.colors ? root.colors.surfaceHover : "#24ffffff")
             : (root.colors ? root.colors.surfaceElev : "#14ffffff")
        border.color: root.colors ? root.colors.border : "#1affffff"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast }
        }

        scale: ma.pressed ? 0.94 : (ma.containsMouse ? 1.06 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: "Font Awesome 7 Free Solid"
            font.pixelSize: root.iconSize
            color: (root.destructive && ma.containsMouse)
                 ? (root.colors ? root.colors.destructive : "#ff453a")
                 : (root.colors ? root.colors.textPrimary : "#f5f5f7")
            Behavior on color {
                ColorAnimation { duration: Theme.durationFast }
            }
        }
    }

    Text {
        anchors.top: bg.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        visible: ma.containsMouse && root.label.length > 0
        opacity: visible ? 1.0 : 0.0
        font.family: Theme.fontFamily
        font.pixelSize: 11
        color: root.colors ? root.colors.textSecondary : "#a6f5f5f7"

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: bg
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
