# Network Applet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a full-featured wifi/ethernet network applet to the Quickshell bar (segment + popout panel) and switch color mode to dynamic.

**Architecture:** A `network-status --watch` shell script (like `bluetooth-status`) provides live connection state. A `network-scan` one-shot provides available network lists. Both feed into a `NetworkSegment` (bar icon) and `NetworkPanel` (popout) with inline password auth and nmcli-based connect/disconnect. Panel matches AudioPanel polish with animations throughout.

**Tech Stack:** Bash, nmcli, QtQuick/QML (Quickshell), Nerd Font icons

---

### Task 1: Switch color mode to dynamic

**Files:**
- Modify: `~/.config/dotfiles/settings.json`
- Run: `~/.local/bin/set-wallpaper "$(cat ~/.config/current_wallpaper)"`

- [ ] **Step 1: Update settings.json to dynamic mode**

```bash
python3 -c "
import json
p = '$HOME/.config/dotfiles/settings.json'
d = json.load(open(p))
d.setdefault('appearance',{})['accent_mode'] = 'dynamic'
d['appearance']['manual_primary'] = None
d['appearance']['manual_secondary'] = None
json.dump(d, open(p,'w'), indent=2)
"
```

- [ ] **Step 2: Re-apply theme to regenerate with dynamic colors**

```bash
~/.local/bin/set-wallpaper "$(cat ~/.config/current_wallpaper)"
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "fix: switch color mode to dynamic for wallpaper-derived accents"
```

---

### Task 2: Create `network-status` script

**Files:**
- Create: `scripts/.local/bin/network-status`

Follows `bluetooth-status` pattern: `snapshot()` emits JSON state, `--watch` polls every 5s.

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# network-status [--watch]
# Emits current network state as JSON. --watch polls every 5s.

JQ="$(command -v jq || true)"

if [ -z "$JQ" ]; then
    echo '{"error":"jq not found","state":"unavailable"}'
    exit 0
fi

snapshot() {
    local wifi_enabled wifi_powered type ssid signal ip state conn_name devices_json

    wifi_enabled=false; wifi_powered=false
    local radio
    radio=$(nmcli radio wifi 2>/dev/null || true)
    [ "$radio" = "enabled" ] && wifi_enabled=true

    devices_json="[]"
    local line
    while IFS=: read -r dev type state conn; do
        [ -z "$dev" ] && continue
        devices_json=$(echo "$devices_json" | "$JQ" -c \
            --arg dev "$dev" --arg type "$type" --arg state "$state" --arg conn "$conn" \
            '. + [{"interface": $dev, "type": $type, "state": $state, "connection": $conn}]')
    done < <(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)

    local wifi_dev
    wifi_dev=$(echo "$devices_json" | "$JQ" -r '[.[] | select(.type == "wifi") | .interface] | first // ""')

    if [ -n "$wifi_dev" ]; then
        local wifi_state
        wifi_state=$(echo "$devices_json" | "$JQ" -r --arg d "$wifi_dev" '.[] | select(.interface == $d) | .state')
        [ "$wifi_state" = "connected" ] && wifi_powered=true
    fi

    # Find primary connection (first connected device)
    local primary_dev
    primary_dev=$(echo "$devices_json" | "$JQ" -r '[.[] | select(.state == "connected")] | first // empty')
    if [ -n "$primary_dev" ]; then
        type=$(echo "$primary_dev" | "$JQ" -r '.type')
        conn_name=$(echo "$primary_dev" | "$JQ" -r '.connection')
        state="connected"

        if [ "$type" = "wifi" ]; then
            local wifi_info
            wifi_info=$(nmcli -t -f SSID,SIGNAL device wifi list 2>/dev/null | grep -v "^$" | awk -F: -v c="$conn_name" 'BEGIN{IGNORECASE=1} $1 == c {print $1":"$2; exit}')
            if [ -n "$wifi_info" ]; then
                ssid=$(echo "$wifi_info" | cut -d: -f1)
                signal=$(echo "$wifi_info" | cut -d: -f2)
            else
                ssid="$conn_name"; signal=0
            fi
        else
            # ethernet or other: use connection name as display label
            ssid="$conn_name"; signal=0
        fi

        local ip
        ip=$(nmcli -t -f IP4.ADDRESS device show "$(echo "$primary_dev" | "$JQ" -r '.interface')" 2>/dev/null | head -1 | cut -d: -f2- | tr -d '[:space:]')
        [ -n "$ip" ] && ip="${ip%%/*}"

        "$JQ" -nc \
            --arg type "${type:-unknown}" \
            --arg ssid "${ssid:-}" \
            --argjson signal "${signal:-0}" \
            --arg ip "${ip:-}" \
            --arg state "$state" \
            --argjson wifi_enabled "$wifi_enabled" \
            --argjson wifi_powered "$wifi_powered" \
            --argjson devices "$devices_json" \
            '{type: $type, ssid: $ssid, signal: $signal, ip: $ip, state: $state, wifi_enabled: $wifi_enabled, wifi_powered: $wifi_powered, devices: $devices}'
    else
        # Check if any wifi device exists (for disconnected state)
        local has_wifi
        has_wifi=$(echo "$devices_json" | "$JQ" '[.[] | select(.type == "wifi")] | length')
        [ "$has_wifi" -gt 0 ] && wifi_powered=true

        "$JQ" -nc \
            --arg state "disconnected" \
            --argjson wifi_enabled "$wifi_enabled" \
            --argjson wifi_powered "$wifi_powered" \
            --argjson devices "$devices_json" \
            '{state: $state, wifi_enabled: $wifi_enabled, wifi_powered: $wifi_powered, devices: $devices}'
    fi
}

watch() {
    snapshot
    while sleep 5; do snapshot; done
}

case "${1:-}" in
    --watch)  watch ;;
    --pretty) snapshot | "$JQ" . ;;
    "")       snapshot ;;
    -h|--help)
        echo "network-status [--watch|--pretty]"
        ;;
    *) echo "Unknown: $1" >&2; exit 2 ;;
esac
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/.local/bin/network-status
```

- [ ] **Step 3: Test the script**

```bash
scripts/.local/bin/network-status
```
Expected: JSON with current connection state.

- [ ] **Step 4: Commit**

```bash
git add scripts/.local/bin/network-status && git commit -m "feat: add network-status script"
```

---

### Task 3: Create `network-scan` script

**Files:**
- Create: `scripts/.local/bin/network-scan`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# network-scan
# One-shot scan of available wifi networks. Emits JSON array.

JQ="$(command -v jq || true)"

if [ -z "$JQ" ]; then
    echo '{"error":"jq not found"}'
    exit 1
fi

# Request a fresh scan
nmcli device wifi list --rescan yes 2>/dev/null || true

# Parse list: deduplicate by SSID, keep strongest signal
networks=$(
    nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null \
    | grep -v '^:' \
    | awk -F: '{
        ssid=$1; signal=$2; sec=$3
        if (ssid == "") next
        if (ssid in max) {
            if (signal > max[ssid]) {
                max[ssid]=signal; secs[ssid]=sec
            }
        } else {
            max[ssid]=signal; secs[ssid]=sec; keys[++k]=ssid
        }
    } END {
        for (i=1; i<=k; i++) {
            s=keys[i]; sig=max[s]; bars=int(sig/25)+1
            if (bars>4) bars=4
            sec=secs[s]
            is_sec="false"
            if (sec != "" && sec != "--") is_sec="true"
            printf "%s{\"ssid\":\"%s\",\"signal\":%d,\"bars\":%d,\"secured\":%s}", (i==1?"":","), s, sig, bars, is_sec
        }
    }'
)
[ -z "$networks" ] && networks=""

echo "{\"networks\":[$networks]}"
```

- [ ] **Step 2: Make executable + test**

```bash
chmod +x scripts/.local/bin/network-scan
scripts/.local/bin/network-scan
```

- [ ] **Step 3: Commit**

```bash
git add scripts/.local/bin/network-scan && git commit -m "feat: add network-scan script"
```

---

### Task 4: Create `NetworkSegment.qml`

**Files:**
- Create: `quickshell/.config/quickshell/NetworkSegment.qml`

Bar icon following `BluetoothSegment` pattern. Shows wifi signal (4 levels), ethernet, or disconnected. Click toggles NetworkPanel.

- [ ] **Step 1: Write NetworkSegment.qml**

```qml
// Network status icon. Shows wifi signal, ethernet, or disconnected.
// Click toggles the NetworkPanel popout.

import QtQuick
import Quickshell.Io

BarIconButton {
    id: root

    property var state: ({state: "disconnected", wifi_enabled: false, wifi_powered: false, ssid: ""})
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
        ? (state.ssid || "Connected")
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
```

- [ ] **Step 2: Verify file structure matches stow target**

```bash
ls quickshell/.config/quickshell/NetworkSegment.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/NetworkSegment.qml && git commit -m "feat: add NetworkSegment bar icon"
```

---

### Task 5: Create `NetworkPanel.qml`

**Files:**
- Create: `quickshell/.config/quickshell/NetworkPanel.qml`

Full-featured popout: current connection, wifi toggle, available networks scan,
inline password auth for secured networks. Animations throughout.

- [ ] **Step 1: Write NetworkPanel.qml**

```qml
// Floating network control. Uses nmcli via network-status/network-scan.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Popout {
    id: panel
    cardWidth: 340
    padding: 18

    // ── state ────────────────────────────────────────────────────────
    property var state: ({state: "disconnected", wifi_enabled: false, wifi_powered: false, ssid: "", signal: 0, ip: ""})
    property var networks: []
    property bool scanning: false
    property string expandedSsid: ""  // which secured network shows password field
    property string connectingSsid: ""
    property string connectError: ""

    // Derive signal bars (0-4)
    function bars(signal: int): int {
        if (signal >= 75) return 4;
        if (signal >= 50) return 3;
        if (signal >= 25) return 2;
        if (signal >= 1)  return 1;
        return 0;
    }

    function signalIcon(b: int): string {
        return ["󰤯","󰤟","󰤢","󰤥","󰤨"][b] || "󰤭";
    }

    // ── watcher: live connection state ───────────────────────────────
    Process {
        id: watcher
        running: true
        command: ["sh", "-c", "exec ~/.local/bin/network-status --watch"]
        stdout: SplitParser {
            onRead: (line) => {
                try { panel.state = JSON.parse(line); } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    // ── scanner: one-shot network list ───────────────────────────────
    Process {
        id: scanner
        property bool pending: false
        command: ["sh", "-c", "exec ~/.local/bin/network-scan"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const d = JSON.parse(line);
                    panel.networks = d.networks || [];
                    panel.scanning = false;
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running && pending) { pending = false; running = true; }
    }

    function doScan(): void {
        scanning = true;
        scanner.pending = true;
        scanner.running = false;
        scanner.running = true;
    }

    // ── actions: Process pool ────────────────────────────────────────
    Process { id: wifiOnProc;  command: ["nmcli", "radio", "wifi", "on"] }
    Process { id: wifiOffProc; command: ["nmcli", "radio", "wifi", "off"] }
    Process { id: connectProc; command: ["true"] }
    Process { id: discProc;    command: ["true"] }
    Process { id: settingsProc; command: ["nm-connection-editor"] }

    function toggleWifi(enabled: bool): void {
        (enabled ? wifiOnProc : wifiOffProc).startDetached();
    }

    function connectNetwork(ssid: string, password: string): void {
        connectingSsid = ssid;
        connectError = "";
        var cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (password) { cmd.push("password"); cmd.push(password); }
        connectProc.command = cmd;
        connectProc.startDetached();
    }

    function disconnectCurrent(): void {
        const conn = panel.state.devices
            ? panel.state.devices.find(d => d.state === "connected")
            : null;
        if (conn && conn.connection) {
            discProc.command = ["nmcli", "connection", "down", conn.connection];
            discProc.startDetached();
        }
    }

    function networkInList(ssid: string): bool {
        return panel.networks.some(n => n.ssid === ssid);
    }

    // Connected SSID may not be in scan results (hidden network etc).
    // Show it as a virtual entry.
    property var visibleNetworks: {
        const list = panel.networks.slice();
        if (panel.state.state === "connected" && panel.state.ssid
            && !list.some(n => n.ssid === panel.state.ssid)) {
            list.unshift({ssid: panel.state.ssid, signal: panel.state.signal || 0, bars: bars(panel.state.signal || 0), secured: false});
        }
        return list;
    }

    // ── UI ───────────────────────────────────────────────────────────
    ColumnLayout {
        width: 304
        spacing: 14

        // ── Header: title + wifi toggle ──────────────────────────────
        Item {
            Layout.fillWidth: true
            height: 24

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Network"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: panel.state.wifi_enabled ? "On" : "Off"
                    color: panel.state.wifi_enabled ? Theme.accent : Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 20; radius: 10
                    color: panel.state.wifi_enabled ? Theme.accent : Theme.surfaceElev
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    Rectangle {
                        x: panel.state.wifi_enabled ? 18 : 2
                        y: 2; width: 16; height: 16; radius: 8
                        color: "#fff"
                        Behavior on x { NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.toggleWifi(!panel.state.wifi_enabled)
                    }
                }
            }
        }

        // ── Current connection ───────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: stateLabel.y + stateLabel.implicitHeight + 14
            radius: Theme.radiusControl
            color: Theme.surfaceElev
            visible: panel.state.state === "connected" || panel.state.state === "connecting"
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: Theme.durationMed } }

            Text {
                id: stateLabel
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.top: parent.top; anchors.topMargin: 12
                text: panel.state.state === "connecting" ? "Connecting…" : panel.state.ssid
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.top: stateLabel.bottom; anchors.topMargin: 4
                text: {
                    if (panel.state.type === "ethernet") return "Wired: " + (panel.state.ip || "");
                    return panel.state.ip || "";
                }
                visible: panel.state.state === "connected" && !!panel.state.ip
                color: Theme.textSecondary
                font.family: panel.state.type === "ethernet" ? Theme.fontFamily : Theme.fontMono
                font.pixelSize: 11
            }

            Row {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.top: parent.top; anchors.topMargin: 12
                spacing: 6
                visible: panel.state.type === "wifi"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: signalIcon(bars(panel.state.signal || 0))
                    color: Theme.textSecondary
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (panel.state.signal || 0) + "%"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                height: 24; radius: 6
                color: discArea.containsMouse ? Theme.surfaceHover : "transparent"
                visible: panel.state.state === "connected"
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Text {
                    anchors.centerIn: parent
                    text: "Disconnect"
                    color: Theme.destructive
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: discArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.disconnectCurrent()
                }
            }
        }

        // ── Connect error ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: connectError ? 28 : 0
            radius: Theme.radiusControl
            color: Qt.rgba(1, 0.27, 0.23, 0.15)
            visible: !!panel.connectError
            Behavior on height { NumberAnimation { duration: Theme.durationFast } }
            clip: true

            Text {
                anchors.centerIn: parent
                text: panel.connectError
                color: Theme.destructive
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // ── Available networks ───────────────────────────────────────
        Column {
            Layout.fillWidth: true
            spacing: 6

            // Header row
            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "AVAILABLE NETWORKS"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.6
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: scanArea.containsMouse ? 30 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "(" + panel.visibleNetworks.length + ")"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    Behavior on anchors.rightMargin { NumberAnimation { duration: Theme.durationFast } }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↻"
                    color: panel.scanning ? Theme.accent : Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    Timer {
                        running: panel.scanning
                        repeat: true
                        interval: 600
                        onTriggered: parent.opacity = parent.opacity === 1 ? 0.3 : 1
                    }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.doScan()
                    }
                }
            }

            // Network list
            Flickable {
                width: parent.width
                height: Math.min(contentHeight, 320)
                contentHeight: listColumn.height + 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 8000
                maximumFlickVelocity: 4500

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                Column {
                    id: listColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: panel.visibleNetworks

                        delegate: Item {
                            required property var modelData
                            required property int index

                            width: listColumn.width
                            height: isExpanded ? 72 : 40
                            Behavior on height { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
                            clip: true

                            readonly property string ssid: modelData.ssid || ""
                            readonly property int sig: modelData.signal || 0
                            readonly property bool secured: modelData.secured === true
                            readonly property bool isConnected: panel.state.state === "connected" && panel.state.ssid === ssid
                            readonly property bool isConnecting: panel.connectingSsid === ssid
                            readonly property bool isExpanded: panel.expandedSsid === ssid && secured && !isConnected
                            readonly property int b: Math.min(Math.max(Math.floor(sig / 25) + 1, 0), 4)

                            Rectangle {
                                anchors.fill: parent
                                anchors.rightMargin: 4
                                radius: Theme.radiusControl
                                color: {
                                    if (isConnected) return Theme.accentSoft;
                                    if (netHover.containsMouse) return Theme.surfaceHover;
                                    return "transparent";
                                }
                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                            }

                            // Network info row (always visible)
                            Item {
                                anchors.left: parent.left; anchors.leftMargin: 8
                                anchors.right: parent.right; anchors.rightMargin: 8
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: panel.signalIcon(b)
                                    color: isConnected ? Theme.accent : Theme.textSecondary
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }

                                Text {
                                    anchors.left: parent.left; anchors.leftMargin: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ssid
                                    color: isConnected ? Theme.accent : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: isConnected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    width: parent.width - 120
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }

                                Text {
                                    anchors.right: secured ? (isConnected ? parent.right : lockIcon.left - 4) : parent.right
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        if (isConnecting) return "Connecting…";
                                        if (isConnected) return "Connected";
                                        return "";
                                    }
                                    color: isConnecting ? Theme.textTertiary : Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }

                                Text {
                                    id: lockIcon
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: secured ? "󰤩" : ""
                                    color: Theme.textTertiary
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    visible: secured && !isConnected
                                }
                            }

                            // Expanded password field (secured, non-connected)
                            Item {
                                anchors.left: parent.left; anchors.leftMargin: 8
                                anchors.right: parent.right; anchors.rightMargin: 8
                                anchors.top: parent.top; anchors.topMargin: 40
                                height: 30
                                visible: isExpanded

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.surfaceElev
                                    border.color: pwdInput.activeFocus ? Theme.accent : Theme.border
                                    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                                    TextInput {
                                        id: pwdInput
                                        anchors.left: parent.left; anchors.leftMargin: 8
                                        anchors.right: connectBtn.left; anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        echoMode: TextInput.Password
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        placeholderText: "Password"
                                        placeholderTextColor: Theme.textTertiary
                                        Keys.onReturnPressed: panel.connectNetwork(ssid, text)
                                    }
                                }

                                Rectangle {
                                    id: connectBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 26; height: 22; radius: 6
                                    color: connectMouse.containsMouse ? Theme.accent : Theme.accentMuted
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "#fff"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        id: connectMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: panel.connectNetwork(ssid, pwdInput.text)
                                    }
                                }
                            }

                            // Click handler on the main row
                            MouseArea {
                                id: netHover
                                anchors.fill: parent
                                anchors.rightMargin: 4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (isConnected) return;
                                    if (isConnecting) return;
                                    connectError = "";
                                    if (secured) {
                                        panel.expandedSsid = (panel.expandedSsid === ssid) ? "" : ssid;
                                    } else {
                                        panel.connectNetwork(ssid, "");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Footer ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Theme.radiusControl
            color: settingsArea.containsMouse ? Theme.surfaceHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "Network Settings"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "→"
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }

            MouseArea {
                id: settingsArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: settingsProc.startDetached()
            }
        }
    }

    // ── Scan on first open ───────────────────────────────────────────
    onVisibleChanged: {
        if (visible) {
            doScan();
        }
    }

    // When connect finishes, show result
    Connections {
        target: connectProc
        function onFinished(exitCode, exitStatus) {
            if (panel.connectingSsid) {
                if (exitCode === 0) {
                    panel.connectingSsid = "";
                    panel.expandedSsid = "";
                    panel.connectError = "";
                } else {
                    panel.connectError = "Failed to connect. Check password or try Open Network Settings.";
                    panel.connectingSsid = "";
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify file created**

```bash
ls quickshell/.config/quickshell/NetworkPanel.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/.config/quickshell/NetworkPanel.qml && git commit -m "feat: add NetworkPanel popout"
```

---

### Task 6: Register network panel in Globals + shell.qml

**Files:**
- Modify: `quickshell/.config/quickshell/Globals.qml`
- Modify: `quickshell/.config/quickshell/shell.qml`

- [ ] **Step 1: Add networkPanel to Globals**

```qml
// In Globals.qml, add after powerPopout:
    property var networkPanel: null
```

- [ ] **Step 2: Add to `_allPopouts()`**

```qml
    function _allPopouts(): var {
        return [audioPanel, calendarPopout, powerPopout, networkPanel].filter(p => p !== null);
    }
```

- [ ] **Step 3: Instantiate in shell.qml**

```qml
// In shell.qml, add after PowerMenuPopout:
    NetworkPanel  { id: networkPanel }

// In Component.onCompleted:
            Globals.networkPanel  = networkPanel;

// After the power IpcHandler:
    IpcHandler {
        target: "network"
        function toggle(): void { Globals.toggle(networkPanel) }
    }
```

- [ ] **Step 4: Commit**

```bash
git add quickshell/.config/quickshell/Globals.qml quickshell/.config/quickshell/shell.qml && git commit -m "feat: register NetworkPanel in Globals + shell"
```

---

### Task 7: Add NetworkSegment to Bar.qml

**Files:**
- Modify: `quickshell/.config/quickshell/Bar.qml`

- [ ] **Step 1: Add NetworkSegment between BluetoothSegment and VolumeSegment**

In `Bar.qml`, in the right-side `RowLayout`, insert after `BluetoothSegment`:

```qml
            NetworkSegment    { Layout.alignment: Qt.AlignVCenter }
```

- [ ] **Step 2: Commit**

```bash
git add quickshell/.config/quickshell/Bar.qml && git commit -m "feat: add NetworkSegment to bar"
```

---

### Task 8: Stow + restart qs to verify

- [ ] **Step 1: Re-stow quickshell package**

```bash
cd ~/dotfiles && stow -R quickshell
```

- [ ] **Step 2: Restart quickshell to pick up new components**

```bash
pkill -x qs || true
```

- [ ] **Step 3: Verify**

Check bar for network icon, click it, verify scan populates, connect/disconnect flow works.

- [ ] **Step 4: Test with locked-down sudo**

If you need to restart qs and `pkill` fails, use the user's terminal:

```bash
pkill -x qs
```
(quickshell should auto-restart via Niri's `spawn-at-startup` or similar)
