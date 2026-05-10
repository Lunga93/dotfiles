import QtQuick
import QtQuick.Controls
import Quickshell

Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    signal selected(int index)

    height: 32
    width: pillRow.width + 6
    radius: 16
    color: "#0f0b07"
    border.color: "#0e0a06"
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
                    if (isActive) return Theme.accent;
                    if (pillArea.pressed) return Qt.rgba(1, 1, 1, 0.10);
                    if (pillArea.containsMouse) return Qt.rgba(1, 1, 1, 0.05);
                    return "transparent";
                }
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }

                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: modelData
                    color: isActive ? "#1a1105" : "#cfc4b3"
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
