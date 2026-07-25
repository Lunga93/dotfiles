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

    component GroupShell: Column {
        id: gs
        property string header: ""
        property string accent: Theme.primary
        default property alias content: inner.data

        width: parent.width

        Row {
            spacing: 8
            leftPadding: 16
            topPadding: 12
            bottomPadding: 8
            visible: gs.header !== ""

            Rectangle {
                width: 3; height: 12
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: gs.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: gs.header
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.6
            }
        }

        Rectangle {
            width: parent.width
            height: inner.height
            radius: Theme.radiusCard
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1
            clip: true

            Column {
                id: inner
                width: parent.width
            }
        }
    }

    component Divider: Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    component LabelRow: Item {
        id: lr
        property string title: ""
        property string description: ""
        property string hint: ""
        default property alias control: controlSlot.data

        width: parent.width
        height: Math.max(60, textCol.height + 28)

        Column {
            id: textCol
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: controlSlot.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: lr.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                text: lr.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                visible: lr.description !== ""
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: lr.hint
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.italic: true
                visible: lr.hint !== ""
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: controlSlot
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
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
                        color: "#f5ede0"
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Icon pack, cursor theme, and cursor size."
                        color: "#8a8175"
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Column {
                x: 28
                width: parent.width - 56
                spacing: 18
                bottomPadding: 32

                GroupShell {
                    header: "ICON PACK"
                    accent: Theme.primary

                    LabelRow {
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

                GroupShell {
                    header: "CURSOR"
                    accent: Theme.secondary

                    LabelRow {
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

                    LabelRow {
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
                    color: Qt.rgba(1, 1, 1, 0.025)
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
            color: Qt.rgba(1, 1, 1, 0.15)
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
