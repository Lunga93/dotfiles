import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Rectangle {
    id: root
    property var options: []
    property int currentIndex: 0
    property bool wrap: false
    signal selected(int index)

    implicitWidth: root.wrap ? Math.max(loader.width + 12, 80) : loader.width + 8
    height: root.wrap ? loader.height + 12 : 34
    radius: 12
    color: "#0f0b07"
    border.color: "#0e0a06"
    border.width: 1

    Loader {
        id: loader
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.wrap ? 6 : 4
        width: root.wrap ? root.width - 12 : undefined
        sourceComponent: root.wrap ? flowComponent : rowComponent
    }

    Component {
        id: rowComponent
        Row {
            spacing: 2
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
                        font.family: Theme.fontFamily; font.pixelSize: 12
                        font.weight: isActive ? Font.DemiBold : Font.Medium
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

    Component {
        id: flowComponent
        Flow {
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
                        font.family: Theme.fontFamily; font.pixelSize: 12
                        font.weight: isActive ? Font.DemiBold : Font.Medium
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
}
