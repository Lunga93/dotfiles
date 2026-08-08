//@ pragma UseQApplication
// Quickshell entry. One Bar per screen + the floating popouts.

import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
    id: root

    Component.onCompleted: {
        Qt.application.styleHints.colorScheme = Qt.Dark;
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    AudioPanel      { id: audioPanel }
    CalendarPopout  { id: calendarPopout }
    PowerMenuPopout { id: powerPopout }
    NetworkPanel    { id: networkPanel }
    SettingsWindow  { id: settingsWindow }

    Item {
        Component.onCompleted: {
            Globals.audioPanel     = audioPanel;
            Globals.calendarPopout = calendarPopout;
            Globals.powerPopout    = powerPopout;
            Globals.networkPanel   = networkPanel;
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
        target: "network"
        function toggle(): void { Globals.toggle(networkPanel) }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { Globals.toggle(powerPopout) }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { settingsWindow.toggle() }
        function show(): void   { settingsWindow.open() }
        function hide(): void   { settingsWindow.close() }
    }
}
