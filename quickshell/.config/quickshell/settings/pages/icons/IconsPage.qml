import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."

Item {
    id: root

    readonly property var cursorThemeKeys: ["capitaine-cursors", "Adwaita", "Bibata-Modern-Classic", "Bibata-Modern-Ice", "phinger-cursors"]
    readonly property var cursorThemeLabels: ["Capitaine", "Adwaita", "Bibata Classic", "Bibata Ice", "Phinger"]
    readonly property var iconThemeKeys: ["Adwaita", "Papirus", "Papirus-Dark", "Tela-circle", "WhiteSur", "Numix-Circle"]
    readonly property var iconThemeLabels: ["Adwaita", "Papirus", "Papirus Dark", "Tela", "WhiteSur", "Numix"]

    function indexOf(arr, value) {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] === value) return i;
        }
        return 0;
    }


    Flickable {
        id: scroller
        anchors.fill: parent
        contentHeight: column.height + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 4500

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        Column {
            id: column
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 76
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "Icons"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Icon pack, cursor theme, and cursor size."
                        color: Theme.textSubtitle
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 18
                bottomPadding: 32

                SettingsGroup {
                    header: "ICON PACK"
                    accent: Theme.primary

                    SettingsRow {
                        title: "Theme"
                        description: "GTK icon theme used by all applications."
                        hint: SettingsStore.iconTheme && root.indexOf(root.iconThemeKeys, SettingsStore.iconTheme) === 0 && SettingsStore.iconTheme !== "Adwaita"
                            ? "Current: " + SettingsStore.iconTheme + " (not in preset list)"
                            : ""

                        PillSelector {
                            options: root.iconThemeLabels
                            currentIndex: root.indexOf(root.iconThemeKeys, SettingsStore.iconTheme)
                            onSelected: function(index) {
                                SettingsStore.setIconTheme(root.iconThemeKeys[index]);
                            }
                        }
                    }
                }

                SettingsGroup {
                    header: "CURSOR"
                    accent: Theme.secondary

                    SettingsRow {
                        title: "Theme"
                        description: "Mouse cursor style."

                        PillSelector {
                            options: root.cursorThemeLabels
                            currentIndex: root.indexOf(root.cursorThemeKeys, SettingsStore.cursorTheme)
                            onSelected: function(index) {
                                SettingsStore.setCursorTheme(root.cursorThemeKeys[index]);
                            }
                        }
                    }

                    Divider {}

                    SettingsRow {
                        title: "Size"
                        description: "Cursor diameter in pixels."

                        SettingsSlider {
                            width: 240
                            from: 16
                            to: 48
                            value: SettingsStore.cursorSize
                            unitLabel: Math.round(value) + " px"
                            snap: true
                            stepSize: 2
                            onValueChangedByUser: function(v) {
                                SettingsStore.setCursorSize(Math.round(v));
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: Theme.radiusCard
                    color: Theme.surfaceElev
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Theme packs must be installed system-wide. Use pacman or yay."
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Theme.border
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
