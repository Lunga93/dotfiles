import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string outputName: "Detecting…"
    property string inputName: "Detecting…"

    property Process _outputNameProc: Process {
        command: ["bash", "-c", "wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'\"' '/node\\.description/ {print $2; exit}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                root.outputName = v || "Default output";
            }
        }
        onExited: function(code) { if (code !== 0) root.outputName = "Unavailable" }
    }

    property Process _inputNameProc: Process {
        command: ["bash", "-c", "wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk -F'\"' '/node\\.description/ {print $2; exit}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                root.inputName = v || "Default input";
            }
        }
        onExited: function(code) { if (code !== 0) root.inputName = "Unavailable" }
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
                        text: "Sound"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Output and input levels, alert sounds."
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
                    header: "OUTPUT"
                    accent: Theme.primary

                    SettingsRow {
                        title: "Device"
                        description: root.outputName
                    }

                    Divider {}

                    SettingsRow {
                        title: "Volume"
                        description: SettingsStore.outputMuted ? "Muted" : "Playback level"

                        SettingsSlider {
                            width: 240
                            from: 0
                            to: 100
                            value: SettingsStore.outputVolume
                            unitLabel: Math.round(value) + "%"
                            opacity: SettingsStore.outputMuted ? 0.5 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            onValueChangedByUser: function(v) {
                                SettingsStore.setOutputVolume(Math.round(v));
                            }
                        }
                    }

                    Divider {}

                    SettingsRow {
                        title: "Mute"
                        description: "Silence all playback."

                        ToggleSwitch {
                            checked: SettingsStore.outputMuted
                            onToggled: function(state) {
                                SettingsStore.setOutputMuted(state);
                            }
                        }
                    }
                }

                SettingsGroup {
                    header: "INPUT"
                    accent: Theme.secondary

                    SettingsRow {
                        title: "Device"
                        description: root.inputName
                    }

                    Divider {}

                    SettingsRow {
                        title: "Microphone level"
                        description: SettingsStore.inputMuted ? "Muted" : "Capture sensitivity"

                        SettingsSlider {
                            width: 240
                            from: 0
                            to: 100
                            value: SettingsStore.inputVolume
                            unitLabel: Math.round(value) + "%"
                            opacity: SettingsStore.inputMuted ? 0.5 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            onValueChangedByUser: function(v) {
                                SettingsStore.setInputVolume(Math.round(v));
                            }
                        }
                    }

                    Divider {}

                    SettingsRow {
                        title: "Mute microphone"
                        description: "Silence all capture."

                        ToggleSwitch {
                            checked: SettingsStore.inputMuted
                            onToggled: function(state) {
                                SettingsStore.setInputMuted(state);
                            }
                        }
                    }
                }

                SettingsGroup {
                    header: "ALERTS"
                    accent: "#ffb86c"

                    SettingsRow {
                        title: "Notification sounds"
                        description: "Play a sound for system notifications."

                        ToggleSwitch {
                            checked: SettingsStore.alertSoundsEnabled
                            onToggled: function(state) {
                                SettingsStore.setAlertSoundsEnabled(state);
                            }
                        }
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
