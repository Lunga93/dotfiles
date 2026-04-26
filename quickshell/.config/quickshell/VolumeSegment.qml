// Volume pill segment: dynamic icon + percent. Click toggles the AudioPanel.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property string sinkName: sink ? (sink.name || "") : ""

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    implicitHeight: Theme.barHeight
    implicitWidth:  inner.implicitWidth + 12

    function sinkIcon(): string {
        if (root.muted) return "󰝟";
        if (root.volume < 0.34) return "󰕿";
        if (root.volume < 0.67) return "󰖀";
        return AudioNames.sinkIcon(root.sinkName);
    }

    Process { id: menuProc; command: ["sh", "-c", "exec ~/.local/bin/audio-menu"] }
    Process { id: muteProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }

    function bumpVolume(direction: int): void {
        if (!root.sink || !root.sink.audio) return;
        const step = 0.05;
        let v = root.sink.audio.volume + (direction > 0 ? step : -step);
        if (v < 0) v = 0;
        if (v > 1.5) v = 1.5;
        root.sink.audio.volume = v;
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.radiusControl - 2
        color: mouse.pressed
            ? Theme.surfacePressed
            : (mouse.containsMouse ? Theme.surfaceHover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    RowLayout {
        id: inner
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.sinkIcon()
            color: root.muted ? Theme.destructive : Theme.textPrimary
            font.pixelSize: Theme.barIconSize + 3
            font.family: Theme.fontMono
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }

        BarText {
            text: Math.round(root.volume * 100) + "%"
            color: root.muted ? Theme.textTertiary : Theme.textPrimary
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (e) => {
            if (e.button === Qt.RightButton)        menuProc.startDetached();
            else if (e.button === Qt.MiddleButton)  muteProc.startDetached();
            else                                    Globals.toggle(Globals.audioPanel);
        }
        onWheel: (w) => root.bumpVolume(w.angleDelta.y > 0 ? 1 : -1)
    }
}
