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
                width: 3; height: 12; radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: gs.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: gs.header
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 0.6
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
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.right: controlSlot.left; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: lr.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
            }
            Text {
                width: parent.width
                text: lr.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily; font.pixelSize: 11
                visible: lr.description !== ""
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: lr.hint
                color: Theme.textTertiary
                font.family: Theme.fontFamily; font.pixelSize: 10; font.italic: true
                visible: lr.hint !== ""
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: controlSlot
            anchors.right: parent.right; anchors.rightMargin: 20
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
                        text: "Sound"
                        color: "#f5ede0"
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Output and input levels, alert sounds."
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
                    header: "OUTPUT"
                    accent: Theme.primary

                    LabelRow {
                        title: "Device"
                        description: root.outputName
                    }

                    Divider {}

                    LabelRow {
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

                    LabelRow {
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

                GroupShell {
                    header: "INPUT"
                    accent: Theme.secondary

                    LabelRow {
                        title: "Device"
                        description: root.inputName
                    }

                    Divider {}

                    LabelRow {
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

                    LabelRow {
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

                GroupShell {
                    header: "ALERTS"
                    accent: "#ffb86c"

                    LabelRow {
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
            color: Qt.rgba(1, 1, 1, 0.15)
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
