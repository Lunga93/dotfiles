// One audio node (sink or source) — labeled section with slider, mute, percent.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    id: root
    property var node: null
    property string fallbackIcon: "󰕾"
    property string mutedIcon: "󰝟"
    property string label: ""
    spacing: 6

    readonly property bool ready: node !== null && node !== undefined && node.audio !== null
    readonly property real volume: ready ? node.audio.volume : 0
    readonly property bool muted: ready ? node.audio.muted : false

    Text {
        Layout.fillWidth: true
        visible: root.label.length > 0
        text: root.label
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        IconButton {
            icon: root.muted ? root.mutedIcon : root.fallbackIcon
            active: root.muted
            diameter: 32
            onClicked: if (root.ready) root.node.audio.muted = !root.node.audio.muted
        }

        VolumeSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            value: root.volume
            muted: root.muted
            minimum: 0.0
            maximum: 1.0
            onMoved: (v) => { if (root.ready) root.node.audio.volume = v }
        }

        Text {
            Layout.preferredWidth: 32
            text: Math.round(root.volume * 100) + "%"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }
}
