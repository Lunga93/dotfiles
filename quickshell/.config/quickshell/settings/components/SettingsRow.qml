import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Item {
    id: root
    property string title: ""
    property string description: ""
    property string accentColor: Theme.accent
    property int rowHeight: 44

    signal clicked

    width: parent.width
    height: rowHeight

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Theme.surfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: root.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Text {
                text: root.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                visible: root.description !== ""
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
