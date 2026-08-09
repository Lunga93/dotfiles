// Network status icon. Shows wifi signal, ethernet, or disconnected.
// State comes from the shared NetworkStore singleton (single watcher);
// click toggles the NetworkPanel popout.

import QtQuick
import "../"

BarIconButton {
    id: root

    readonly property var state: NetworkStore.state
    readonly property bool hasConnection: state.state === "connected"

    function iconChar(): string {
        if (state.type === "ethernet" && state.state === "connected") return "󰈀";
        if (!state.wifi_enabled) return "󰤭";
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
    tint: Theme.textPrimary
    fontSize: Theme.barIconSize + 6
    tooltip: hasConnection
        ? (state.type === "ethernet" ? "Wired" : (state.ssid || "Connected"))
        : (state.wifi_enabled ? "Disconnected" : "WiFi off")

    onClicked: Globals.toggle(Globals.networkPanel)
    onRightClicked: Globals.toggle(Globals.networkPanel)
}
