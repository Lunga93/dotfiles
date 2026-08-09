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

                SettingsGroup {
                    header: "SCALING"
                    accent: Theme.primary

                    SettingsRow {
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

                SettingsGroup {
                    header: "NIGHT LIGHT"
                    accent: "#ffb86c"

                    SettingsRow {
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

                    SettingsRow {
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

                SettingsGroup {
                    header: "COLOR SCHEME"
                    accent: Theme.primary

                    SettingsRow {
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

                MonitorPanel {
                    width: parent.width
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
