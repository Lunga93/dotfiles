import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."

Item {
    id: root

    property var scaleOptions: [ 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0 ]
    property var scaleLabels: [ "0.5\u00D7", "0.75\u00D7", "1.0\u00D7", "1.25\u00D7", "1.5\u00D7", "1.75\u00D7", "2.0\u00D7" ]

    function scaleOptionIndex(scale) {
        for (let i = 0; i < root.scaleOptions.length; i++) {
            if (Math.abs(root.scaleOptions[i] - scale) < 0.01) return i;
        }
        return 2;
    }

    function uniqueModes(modes) {
        if (!modes) return [];
        const seen = {};
        const out = [];
        for (let i = 0; i < modes.length; i++) {
            const m = modes[i];
            const key = (m.width || 0) + "x" + (m.height || 0);
            if (!seen[key]) {
                seen[key] = true;
                out.push({ index: i, width: m.width, height: m.height,
                    refresh: m.refresh_rate || 60000, label: key });
            }
        }
        return out.slice(0, 12);
    }

    implicitHeight: content.height + 24

    Column {
        id: content
        width: parent.width
        spacing: 12

        Row {
            spacing: 8
            leftPadding: 4
            visible: MonitorStore.loaded

            Rectangle {
                width: 3; height: 12; radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.primary
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "MONITORS"
                color: Theme.textSecondary
                font.family: Theme.fontFamily; font.pixelSize: 11
                font.weight: Font.Bold; font.letterSpacing: 0.6
            }
            Item { Layout.fillWidth: true; height: 1 }
        }

        Row {
            spacing: 8
            visible: MonitorStore.loaded

            PillSelector {
                id: actionPills
                options: ["Refresh", "Apply"]
                currentIndex: -1
                onSelected: function(index) {
                    if (index === 0) MonitorStore.refresh();
                    else MonitorStore.applyConfig();
                    currentIndex = -1;
                }
            }
        }

        Repeater {
            model: MonitorStore.monitors
            delegate: Rectangle {
                id: card
                required property var modelData
                width: parent.width
                height: contentCol.height + 24
                radius: Theme.radiusCard
                color: Theme.surfaceElev
                border.color: Theme.border
                border.width: 1

                Column {
                    id: contentCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Row {
                        spacing: 12
                        width: parent.width

                        Rectangle {
                            width: 72; height: 48
                            radius: 6
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: (modelData.width || 0) + "\u00D7" + (modelData.height || 0)
                                color: Theme.textSecondary
                                font.family: Theme.fontMono; font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Column {
                            spacing: 4
                            width: parent.width - 92

                            Text {
                                text: modelData.make ? (modelData.make + " " + modelData.model)
                                    : (modelData.name || modelData.connector || "")
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: MonitorStore.currentModeLabel(modelData) + " \u00B7 " + (modelData.scale || 1.0) + "\u00D7 scale"
                                color: Theme.textSecondary
                                font.family: Theme.fontMono; font.pixelSize: 11
                            }
                        }
                    }

                    Text {
                        text: "Resolution"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                        font.letterSpacing: 0.4
                    }

                    PillSelector {
                        id: modeSelector
                        width: parent.width
                        options: {
                            const modes = root.uniqueModes(modelData.modes);
                            return modes.map(m => m.width + "\u00D7" + m.height);
                        }
                        currentIndex: {
                            if (!modelData.modes || modelData.currentMode === undefined) return -1;
                            const current = modelData.modes[modelData.currentMode];
                            if (!current) return -1;
                            const um = root.uniqueModes(modelData.modes);
                            for (let i = 0; i < um.length; i++) {
                                if (um[i].width === current.width && um[i].height === current.height) return i;
                            }
                            return -1;
                        }
                        onSelected: function(index) {
                            const um = root.uniqueModes(modelData.modes);
                            if (index >= 0 && index < um.length) {
                                MonitorStore.setMode(modelData, um[index].index);
                                modelData.currentMode = um[index].index;
                            }
                        }
                    }

                    Text {
                        text: "Scale"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Medium
                        font.letterSpacing: 0.4
                    }

                    PillSelector {
                        id: scaleSelector
                        options: root.scaleLabels
                        currentIndex: root.scaleOptionIndex(modelData.scale || 1.0)
                        onSelected: function(index) {
                            MonitorStore.setScale(modelData, root.scaleOptions[index]);
                            modelData.scale = root.scaleOptions[index];
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width - 8
            text: MonitorStore.loaded && MonitorStore.monitors.length === 0
                ? "No monitors detected. Ensure niri is running."
                : !MonitorStore.loaded ? "Detecting monitors..." : ""
            color: Theme.textTertiary
            font.family: Theme.fontFamily; font.pixelSize: 11
            visible: text !== ""
            leftPadding: 4; topPadding: 4
        }

        Text {
            width: parent.width - 8
            leftPadding: 4; topPadding: 4
            text: "Changes take effect immediately.\nClick Apply to persist to config.kdl."
            color: Theme.textTertiary
            font.family: Theme.fontFamily; font.pixelSize: 10
            font.italic: true
            visible: MonitorStore.loaded && MonitorStore.monitors.length > 0
        }
    }
}
