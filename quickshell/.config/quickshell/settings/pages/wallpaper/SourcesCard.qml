import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

Rectangle {
    id: root
    width: parent.width
    height: childrenRect.height
    radius: 14
    color: "#221c15"
    border.color: "#0e0a06"
    border.width: 1

    readonly property var allSources: [
        { id: "local",    label: "Local Folder", icon: "folder" },
        { id: "unsplash", label: "Unsplash",     icon: "image" },
        { id: "reddit",   label: "Reddit",       icon: "image" },
        { id: "bing",     label: "Bing",         icon: "image" },
        { id: "picsum",   label: "Picsum",       icon: "image" }
    ]

    signal sourcesChanged()

    function isEnabled(id: string): bool {
        const en = SettingsStore.get("wallpaper", "sources_enabled") || {};
        return en[id] !== false;
    }

    function setEnabled(id: string, enabled: bool): void {
        const en = Object.assign({}, SettingsStore.get("wallpaper", "sources_enabled") || {});
        en[id] = enabled;
        SettingsStore.set("wallpaper", "sources_enabled", en);
        root.sourcesChanged();
    }

    function folderPicker(): void {
        const cmd = "zenity --file-selection --directory --title='Select Wallpaper Library' 2>/dev/null || kdialog --getexistingdirectory 2>/dev/null || echo ''";
        SettingsStore.execScript("result=$(" + cmd + "); if [ -n \"$result\" ]; then " +
            "sed -i 's|\"library_dir\": \"[^\"]*\"|\"library_dir\": \"'$result'\"|' ~/.config/dotfiles/settings.json; " +
            "fi");
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "SOURCES"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }

        Repeater {
            model: root.allSources

            delegate: Item {
                required property var modelData
                required property int index
                width: parent.width
                height: 52

                readonly property bool isOn: root.isEnabled(modelData.id)

                Rectangle {
                    anchors.fill: parent
                    color: rowArea.containsMouse ? "#2a2419" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Item {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16

                        Row {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 28; height: 28; radius: 8
                                color: isOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(1, 1, 1, 0.04)
                                anchors.verticalCenter: parent.verticalCenter

                                PhosphorIcon {
                                    anchors.centerIn: parent
                                    name: modelData.icon
                                    size: 14
                                    color: isOn ? Theme.accent : "#5a5249"
                                    weight: isOn ? "fill" : "regular"
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: modelData.label
                                    color: isOn ? "#f5ede0" : "#8a8175"
                                    font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                                }
                                Text {
                                    text: modelData.id === "local" ? (SettingsStore.get("wallpaper", "library_dir") || "~/Pictures/wallpapers") : ""
                                    color: "#6b6258"
                                    font.family: Theme.fontFamily; font.pixelSize: 10
                                    visible: modelData.id === "local"
                                    elide: Text.ElideMiddle
                                    width: 160
                                }
                            }
                        }

                        Rectangle {
                            anchors.right: toggleSwitch.left; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28; height: 28; radius: 14
                            color: overflowArea.containsMouse ? "#3a3225" : "transparent"
                            visible: modelData.id === "local"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\u22ef"
                                color: "#a89e8e"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                id: overflowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: overflowMenu.open()
                            }

                            Popup {
                                id: overflowMenu
                                y: parent.height + 4
                                width: 180
                                padding: 4
                                background: Rectangle {
                                    color: "#231d16"
                                    border.color: "#3a3225"
                                    border.width: 1
                                    radius: 10
                                }

                                Column {
                                    width: parent.width
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { label: "Change folder\u2026", action: function() { root.folderPicker(); overflowMenu.close(); } },
                                            { label: "Open in file manager", action: function() { SettingsStore.execScript("xdg-open \"" + (SettingsStore.get("wallpaper", "library_dir") || "~/Pictures/wallpapers") + "\""); overflowMenu.close(); } },
                                            { label: "Re-tag library", action: function() { SettingsStore.execScript("tag-wallpaper-moods --force"); overflowMenu.close(); } }
                                        ]
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: parent.width; height: 30; radius: 6
                                            color: menuArea.containsMouse ? "#3a3225" : "transparent"
                                            Behavior on color { ColorAnimation { duration: 80 } }

                                            Text {
                                                anchors.left: parent.left; anchors.leftMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.label
                                                color: "#f5ede0"
                                                font.family: Theme.fontFamily; font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: menuArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.action()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleSwitch {
                            id: toggleSwitch
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: isOn
                            onToggled: function(state) { root.setEnabled(modelData.id, state); }
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

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.right: parent.right; anchors.rightMargin: 16
                    height: 1
                    color: "#0e0a06"
                    visible: index < root.allSources.length - 1
                }
            }
        }
    }
}
