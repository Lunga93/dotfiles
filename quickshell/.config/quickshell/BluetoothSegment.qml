// Bluetooth status icon. Hides itself if no adapter is present.
// Click → overskride; right-click → wofi bluetooth-menu fallback.

import QtQuick
import Quickshell.Io

BarIconButton {
    id: root

    property var state: ({ available: false, powered: false, count: 0 })
    readonly property bool show: state && state.available
    readonly property bool connected: show && state.powered && state.count > 0

    visible: show
    icon: !show
        ? ""
        : (connected ? "󰂱" : (state.powered ? "󰂯" : "󰂲"))
    active: connected
    tooltip: !show
        ? "Bluetooth unavailable"
        : (connected ? state.count + " device(s) connected"
                     : (state.powered ? "Bluetooth on" : "Bluetooth off"))

    Process {
        id: watcher
        running: true
        command: ["sh", "-c", "exec ~/.local/bin/bluetooth-status --watch"]
        stdout: SplitParser {
            onRead: (line) => {
                try { root.state = JSON.parse(line); } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    Process { id: open; command: ["overskride"] }
    Process { id: menu; command: ["sh", "-c", "exec ~/.local/bin/bluetooth-menu"] }

    onClicked: open.startDetached()
    onRightClicked: menu.startDetached()
}
