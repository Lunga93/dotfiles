import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    signal selected(int index)

    height: 32
    width: pillRow.width + 6
    radius: 16
    color: Theme.surfaceDeep
    border.color: Theme.dividerColor
    border.width: 1

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 3
        spacing: 0

        Repeater {
            model: root.options

            delegate: Rectangle {
                required property var modelData
                required property int index

                readonly property bool isActive: index === root.currentIndex

                width: pillText.width + 22
                height: 26
                radius: 13
                color: {
                    if (isActive) return Theme.secondary;
                    if (pillArea.pressed) return Theme.surfaceHover;
                    if (pillArea.containsMouse) return Theme.surfaceElev;
                    return "transparent";
                }
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: modelData
                    color: isActive ? Theme.foreground : Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: isActive ? Font.DemiBold : Font.Medium
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: pillArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.selected(index);
                    }
                }
            }
        }
    }
}
