// Floating audio control. Reads pipewire directly via Quickshell.Services.Pipewire.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Popout {
    id: panel
    cardWidth: 340
    padding: 18

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: {
            const list = [];
            if (panel.sink)   list.push(panel.sink);
            if (panel.source) list.push(panel.source);
            for (const node of Pipewire.nodes.values) {
                if (node.audio && !node.isStream) list.push(node);
            }
            return list;
        }
    }

    ColumnLayout {
        width: 304
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Sound"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        VolumeRow {
            Layout.fillWidth: true
            node: panel.sink
            fallbackIcon: panel.sink ? AudioNames.sinkIcon(panel.sink.name) : "󰕾"
            mutedIcon: "󰝟"
            label: "Output"
        }

        VolumeRow {
            Layout.fillWidth: true
            node: panel.source
            fallbackIcon: panel.source ? AudioNames.sourceIcon(panel.source.name) : "󰍬"
            mutedIcon: "󰍭"
            label: "Input"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.border
            Layout.topMargin: 4
        }

        Text {
            Layout.fillWidth: true
            text: "Output device"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.6
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ScriptModel {
                    values: {
                        const out = [];
                        for (const node of Pipewire.nodes.values) {
                            if (node.isSink && !node.isStream && node.audio) out.push(node);
                        }
                        return out;
                    }
                }

                DeviceChip {
                    required property var modelData
                    icon:  modelData ? AudioNames.sinkIcon(modelData.name)  : "󰓃"
                    label: modelData ? AudioNames.sinkLabel(modelData)      : ""
                    active: panel.sink && modelData && panel.sink.id === modelData.id
                    onClicked: if (modelData) Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: "Input device"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.6
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: ScriptModel {
                    values: {
                        const out = [];
                        for (const node of Pipewire.nodes.values) {
                            if (!node.isSink && !node.isStream && node.audio
                                && !(node.name || "").endsWith(".monitor")) {
                                out.push(node);
                            }
                        }
                        return out;
                    }
                }

                DeviceChip {
                    required property var modelData
                    icon:  modelData ? AudioNames.sourceIcon(modelData.name) : "󰍬"
                    label: modelData ? AudioNames.sourceLabel(modelData)     : ""
                    active: panel.source && modelData && panel.source.id === modelData.id
                    onClicked: if (modelData) Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }
    }
}
