// Network status icon. Shows wifi signal, ethernet, or disconnected.
// Click toggles the NetworkPanel popout.

import QtQuick
import Quickshell.Io

BarIconButton {
    id: root

    property var state: ({state: "disconnected", wifi_enabled: false, wifi_powered: false, ssid: "", type: ""})
    readonly property bool hasConnection: state.state === "connected"

    function iconChar(): string {
        if (!state.wifi_enabled) return "󰤭";
        if (state.type === "ethernet") return "󰈀";
        if (state.state === "connected" && state.type === "wifi") {
            const s = state.signal || 0;
            if (s < 25)  return "󰤟";
            if (s < 50)  return "󰤢";
            if (s < 75)  return "󰤥";
            return "󰤨";
        }
        if (state.state === "connecting") return "󰤪";
        return state.wifi_powered ? "󰤫" : "󰤭";
    }

    icon: iconChar()
    active: hasConnection
    tooltip: hasConnection
        ? (state.ssid || (state.type === "ethernet" ? "Wired" : "Connected"))
        : (state.wifi_enabled ? "Disconnected" : "WiFi off")

    Process {
        id: watcher
        running: true
        command: ["sh", "-c", "exec ~/.local/bin/network-status --watch"]
        stdout: SplitParser {
            onRead: (line) => {
                try { root.state = JSON.parse(line); } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    onClicked: Globals.toggle(Globals.networkPanel)
}
