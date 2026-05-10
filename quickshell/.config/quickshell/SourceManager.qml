import QtQuick
import QtQuick.Controls
import Quickshell

Column {
    id: root
    width: parent.width
    spacing: 0

    readonly property var allSources: [
        { id: "local",    label: "Local Folder", desc: "~/Pictures/wallpapers/", icon: "folder" },
        { id: "unsplash", label: "Unsplash",     desc: "Curated photography",    icon: "image" },
        { id: "reddit",   label: "Reddit",       desc: "Custom subreddits",      icon: "image" },
        { id: "bing",     label: "Bing",         desc: "Photo of the day",       icon: "image" },
        { id: "picsum",   label: "Picsum",       desc: "Lorem Picsum random",    icon: "image" }
    ]

    function isEnabled(id: string): bool {
        const en = SettingsStore.get("wallpaper", "sources_enabled") || {};
        return en[id] !== false;
    }

    function setEnabled(id: string, enabled: bool): void {
        const en = SettingsStore.get("wallpaper", "sources_enabled") || {};
        en[id] = enabled;
        SettingsStore.set("wallpaper", "sources_enabled", en);
    }

    Item {
        width: parent.width
        height: 36
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "SOURCES"
            color: "#6b6258"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.8
        }
    }

    // Source toggle rows
    Repeater {
        model: root.allSources

        delegate: Item {
            required property var modelData
            required property int index
            width: parent.width
            height: 56

            readonly property bool isOn: root.isEnabled(modelData.id)

            Rectangle {
                anchors.fill: parent
                color: rowArea.containsMouse ? "#2a2419" : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 32; height: 32; radius: 8
                            color: isOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(1, 1, 1, 0.04)
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 140 } }

                            PhosphorIcon {
                                anchors.centerIn: parent
                                name: modelData.icon
                                size: 16
                                color: isOn ? Theme.accent : "#5a5249"
                                weight: isOn ? "fill" : "regular"
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: modelData.label
                                color: isOn ? "#f5ede0" : "#8a8175"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            Text {
                                text: modelData.desc
                                color: "#6b6258"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }

                    ToggleSwitch {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: isOn
                        onToggled: function(state) {
                            root.setEnabled(modelData.id, state);
                        }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onClicked: function(mouse) { mouse.accepted = false }
                }
            }

            // Divider between rows
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                height: 1
                color: "#0e0a06"
                visible: index < root.allSources.length - 1
            }
        }
    }
}
