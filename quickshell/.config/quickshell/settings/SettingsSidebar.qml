import QtQuick
import QtQuick.Controls
import Quickshell
import ".." // qmldir types

Flickable {
    id: root
    property int activeCategory: 0
    signal categorySelected(int index)

    contentHeight: column.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // Pre-compute flat list with global indices
    readonly property var flatItems: {
        const result = [];
        let g = 0;
        for (let s = 0; s < Categories.all.length; s++) {
            const section = Categories.all[s];
            result.push({ type: "header", label: section.section, sectionIdx: s });
            for (let i = 0; i < section.items.length; i++) {
                result.push({
                    type: "item",
                    label: section.items[i].label,
                    icon: section.items[i].icon,
                    globalIdx: g
                });
                g++;
            }
        }
        return result;
    }

    Column {
        id: column
        width: parent.width
        spacing: 2
        topPadding: 4

        Repeater {
            model: root.flatItems

            delegate: Loader {
                required property var modelData
                width: parent.width
                sourceComponent: modelData.type === "header" ? headerComp : itemComp
            }
        }
    }

    Component {
        id: headerComp
        Item {
            property var modelData: parent ? parent.modelData : null
            width: parent ? parent.width : 0
            height: 30

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: parent.modelData ? parent.modelData.label.toUpperCase() : ""
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }
    }

    Component {
        id: itemComp
        Item {
            property var modelData: parent ? parent.modelData : null
            width: parent ? parent.width : 0
            height: 40

            readonly property bool isActive: modelData && modelData.globalIdx === root.activeCategory

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                radius: 10

                color: {
                    if (isActive) return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18);
                    if (mouse.pressed) return Qt.rgba(1, 1, 1, 0.10);
                    if (mouse.containsMouse) return Qt.rgba(1, 1, 1, 0.06);
                    return "transparent";
                }
                Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }

                // Active indicator bar
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: -4
                    width: 3
                    height: parent.height * 0.55
                    radius: 2
                    color: Theme.accent
                    opacity: isActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 26; height: 26
                        radius: 7
                        color: isActive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28) : Qt.rgba(1, 1, 1, 0.05)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 140 } }

                        PhosphorIcon {
                            anchors.centerIn: parent
                            name: modelData ? modelData.icon : ""
                            size: 15
                            color: isActive ? Theme.accent : "#a89e8e"
                            weight: isActive ? "fill" : "regular"
                        }
                    }

                    Text {
                        text: modelData ? modelData.label : ""
                        color: isActive ? "#f5ede0" : "#cfc4b3"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: isActive ? Font.DemiBold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (modelData) root.categorySelected(modelData.globalIdx)
            }
        }
    }
}
