import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."

Item {
    id: root

    readonly property var scaleKeys: ["0.8", "1.0", "1.25", "1.5", "2.0"]
    readonly property var scaleLabels: ["0.8×", "1.0×", "1.25×", "1.5×", "2.0×"]

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
        color: Theme.dividerColor
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
                        text: "Display"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Scaling, night light, and per-display options."
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

                GroupShell {
                    header: "SCALING"
                    accent: Theme.primary

                    LabelRow {
                        title: "Text scaling factor"
                        description: "Applies to GTK and Qt applications system-wide."

                        PillSelector {
                            options: root.scaleLabels
                            currentIndex: root.indexOf(root.scaleKeys, SettingsStore.displayScale)
                            onSelected: function(index) {
                                SettingsStore.setDisplayScale(root.scaleKeys[index]);
                            }
                        }
                    }
                }

                GroupShell {
                    header: "NIGHT LIGHT"
                    accent: "#ffb86c"

                    LabelRow {
                        title: "Night light"
                        description: "Warmer screen tones to reduce eye strain."
                        hint: SettingsStore.nightLightEnabled ? "" : "Requires wlsunset (install via pacman)"

                        ToggleSwitch {
                            checked: SettingsStore.nightLightEnabled
                            onToggled: function(state) {
                                SettingsStore.setNightLightEnabled(state);
                            }
                        }
                    }

                    Divider {}

                    LabelRow {
                        title: "Color temperature"
                        description: "Lower = warmer, higher = cooler."

                        SettingsSlider {
                            width: 240
                            from: 1500
                            to: 6500
                            value: SettingsStore.nightLightTemperature
                            unitLabel: Math.round(value) + " K"
                            snap: true
                            stepSize: 100
                            onValueChangedByUser: function(v) {
                                SettingsStore.setNightLightTemperature(Math.round(v));
                            }
                        }
                    }
                }

                GroupShell {
                    header: "COLOR SCHEME"
                    accent: Theme.primary

                    LabelRow {
                        title: "Appearance mode"
                        description: "Applies to the shell bar, popouts, settings, and all GTK/Qt apps."

                        PillSelector {
                            options: ["Dark", "Light"]
                            currentIndex: SettingsStore.colorScheme === "light" ? 1 : 0
                            onSelected: function(index) {
                                SettingsStore.setColorScheme(index === 1 ? "light" : "dark");
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
                        text: "Per-display resolution and scale: edit niri config (output blocks)."
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
