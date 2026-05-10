import QtQuick
import QtQuick.Controls
import Quickshell

PanelWindow {
    id: window
    visible: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true

    property int activeIndex: 0

    function open(): void {
        window.visible = true;
    }

    function close(): void {
        window.visible = false;
    }

    function toggle(): void {
        if (window.visible) close();
        else open();
    }

    // Solid scrim
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: window.close()
        }

        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    // Window — solid layered surfaces, no glass
    Rectangle {
        id: container
        readonly property int defaultHeight: 640
        readonly property int expandedHeight: 900
        width: 1000
        height: SettingsStore.selectedMood ? expandedHeight : defaultHeight
        Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        anchors.centerIn: parent
        radius: 16
        color: "#1a1611"
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        clip: true

        // Drop shadow effect via stacked rectangles
        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            radius: 22
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.25)
            border.width: 1
            z: -1
        }

        // Window scale animation on open
        scale: window.visible ? 1.0 : 0.94
        opacity: window.visible ? 1.0 : 0
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        // Title bar — solid, with bottom hairline
        Rectangle {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42
            color: "#231d16"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    id: closeLight
                    width: 13; height: 13; radius: 6.5
                    color: closeArea.containsMouse ? Theme.color1 : Qt.darker(Theme.color1, 1.3)
                    border.color: Qt.rgba(0, 0, 0, 0.2); border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.close()
                    }
                }
                Rectangle {
                    width: 13; height: 13; radius: 6.5
                    color: minArea.containsMouse ? Theme.color5 : Qt.darker(Theme.color5, 1.3)
                    border.color: Qt.rgba(0, 0, 0, 0.2); border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea { id: minArea; anchors.fill: parent; hoverEnabled: true }
                }
                Rectangle {
                    width: 13; height: 13; radius: 6.5
                    color: maxArea.containsMouse ? Theme.color2 : Qt.darker(Theme.color2, 1.3)
                    border.color: Qt.rgba(0, 0, 0, 0.2); border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea { id: maxArea; anchors.fill: parent; hoverEnabled: true }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Settings"
                color: "#a89e8e"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#0e0a06"
            }
        }

        // Sidebar — solid, slightly darker than content
        Rectangle {
            id: sidebarBg
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 232
            color: "#15110c"
            clip: true

            SettingsSidebar {
                id: sidebar
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                activeCategory: window.activeIndex
                onCategorySelected: function(idx) {
                    window.activeIndex = idx;
                }
            }

            // Right divider
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: "#0e0a06"
            }
        }

        // Content area — solid
        Rectangle {
            anchors.top: titleBar.bottom
            anchors.left: sidebarBg.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "#1a1611"

            SettingsContent {
                id: content
                anchors.fill: parent
                activeIndex: window.activeIndex
            }
        }
    }
}
