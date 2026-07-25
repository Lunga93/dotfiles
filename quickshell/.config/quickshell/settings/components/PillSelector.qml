import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    signal selected(int index)

    implicitWidth: Math.max(flow.width + 12, 80)
    height: flow.height + 12
    radius: 12
    color: "#0f0b07"
    border.color: "#0e0a06"
    border.width: 1

    Flow {
        id: flow
        anchors.left: parent.left; anchors.leftMargin: 6
        anchors.right: parent.right; anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

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
                    if (pillArea.pressed) return Qt.rgba(1, 1, 1, 0.10);
                    if (pillArea.containsMouse) return Qt.rgba(1, 1, 1, 0.05);
                    return "transparent";
                }
                Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }

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
