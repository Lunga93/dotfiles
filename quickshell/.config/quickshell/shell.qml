//@ pragma UseQApplication
// Quickshell entry. One Bar per screen + the floating popouts.

//@ pragma IconTheme AdwaitaLegacy
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    Component.onCompleted: {
        Qt.application.styleHints.colorScheme = Qt.Dark;
    }

    Process {
        command: ["bash", "-c", "~/.local/bin/apply-display-scale"]
        Component.onCompleted: startDetached()
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Aperture        { id: aperture }
    AudioPanel      { id: audioPanel }
    CalendarPopout  { id: calendarPopout }
    PowerMenuPopout { id: powerPopout }
    NetworkPanel    { id: networkPanel }
    SettingsWindow  { id: settingsWindow }
    LauncherWindow  { id: spotlight }

    Item {
        Component.onCompleted: {
            Globals.audioPanel     = audioPanel;
            Globals.calendarPopout = calendarPopout;
            Globals.powerPopout    = powerPopout;
            Globals.networkPanel   = networkPanel;
            Globals.settingsWindow = settingsWindow;
        }
    }

    IpcHandler {
        target: "aperture"
        function toggle(): void { aperture.toggle() }
        function show(): void   { aperture.show() }
        function hide(): void   { aperture.hide() }
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

    IpcHandler {
        target: "network"
        function toggle(): void { Globals.toggle(networkPanel) }
        function show(): void   { networkPanel.visible = true }
        function hide(): void   { networkPanel.visible = false }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { settingsWindow.toggle() }
        function show(): void   { settingsWindow.open() }
        function hide(): void   { settingsWindow.close() }
    }

    IpcHandler {
        target: "spotlight"
        function toggle(): void { spotlight.toggle() }
        function show(): void   { spotlight.show() }
        function hide(): void   { spotlight.hide() }
    }
}
