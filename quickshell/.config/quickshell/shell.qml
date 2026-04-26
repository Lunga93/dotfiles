// Quickshell entry. One Bar per screen + the floating popouts.

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    AudioPanel      { id: audioPanel }
    CalendarPopout  { id: calendarPopout }
    PowerMenuPopout { id: powerPopout }

    Item {
        Component.onCompleted: {
            Globals.audioPanel     = audioPanel;
            Globals.calendarPopout = calendarPopout;
            Globals.powerPopout    = powerPopout;
        }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { Globals.toggle(audioPanel) }
        function show(): void   { audioPanel.visible = true }
        function hide(): void   { audioPanel.visible = false }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { Globals.toggle(calendarPopout) }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Globals.toggle(powerPopout) }
    }
}
