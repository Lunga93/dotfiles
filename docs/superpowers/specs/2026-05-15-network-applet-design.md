# Network Applet for Quickshell Bar

Date: 2026-05-15
Status: Design (approved)
Author: AI agent

## Overview

Add a wifi/ethernet network applet to the Quickshell bar, matching the feature
depth and polish of the existing AudioPanel: live status icon, a popout for
network management (scan, connect, disconnect, toggle wifi), with smooth
animations throughout.

## Components

### Shell script: `network-status --watch`

Persistent process (like `bluetooth-status --watch`) that polls `nmcli` and
emits JSON lines on state changes. Used by both NetworkSegment (icon) and
NetworkPanel (current connection data).

**Output JSON (one line per state change):**
```json
{
  "type": "wifi",
  "ssid": "MyWiFi",
  "signal": 80,
  "ip": "192.168.1.42",
  "state": "connected",
  "wifi_powered": true,
  "wifi_enabled": true,
  "devices": [
    {"type": "wifi", "interface": "wlan0", "state": "connected"},
    {"type": "ethernet", "interface": "eth0", "state": "unavailable"}
  ]
}
```

States: `connected`, `connecting`, `disconnected`, `unavailable`

### Shell script: `network-scan`

One-shot command. Runs `nmcli device wifi list --rescan yes` and outputs JSON
array of available networks:

```json
[
  {"ssid": "MyWiFi", "signal": 80, "security": "WPA2", "bars": 4},
  {"ssid": "NeighborNet", "signal": 35, "security": "", "bars": 2}
]
```

### Shell commands (inline via QML Process)

- **Connect open:** `nmcli device wifi connect <ssid>`
- **Connect secured:** `nmcli device wifi connect <ssid> password <password>`
- **Disconnect:** `nmcli connection down <conn-name>`
- **Wifi on:** `nmcli radio wifi on`
- **Wifi off:** `nmcli radio wifi off`

### `NetworkSegment.qml` (bar icon)

- Reads from `network-status --watch` (persistent Process)
- Icon follows the `BarIconButton` pattern
- **Icons:** wifi signal 0-4 bars ( 󰤯 󰤟 󰤢 󰤥 󰤨 ), ethernet ( 󰈀 ), disconnected ( 󰤭 )
- Active state when connected (tint `Theme.accent`)
- Tooltip shows SSID or status
- Hover/press: `Theme.surfaceHover`/`Theme.surfacePressed` transitions
- Click: toggle NetworkPanel via `Globals.toggle(Globals.networkPanel)`

### `NetworkPanel.qml` (popout)

Extends `Popout` (same base as AudioPanel, CalendarPopout).

**Layout (top→bottom):**

1. **Header**: "Network" title (DemiBold 14px) + wifi toggle pill (like
   WallpaperHero's Dynamic/Manual pill). Toggle calls `nmcli radio wifi on/off`.
   Smooth color transitions on toggle state change.

2. **Current connection card**: visible when `state === "connected"`.
   - Row: SSID (bold) + signal bars icon + signal percent
   - Row: IP address (mono, muted)
   - Disconnect button (click → `nmcli connection down`, with feedback state)
   - Border: `Theme.border`, rounded, hover highlight

3. **Available networks section**: always visible.
   - Header row: "AVAILABLE NETWORKS" + count
   - Scrollable list (Flickable + ScrollBar custom thumb, same pattern as
     WallpaperPage)
   - Each item is a clickable row/card with:
     - Signal bars (0-4, Nerd Font icons)
     - Lock icon ( 󰤩 for secured, nothing for open)
     - SSID name
     - "Connected" badge or active indicator when currently connected
     - Scale animation on hover (1.0→1.02, like WallpaperGrid)

4. **Inline password field**: when a secured network is tapped:
   - Smooth height animation expanding the row
   - Password TextField (echo mode) + Connect button (→ "Connecting..." state)
   - Animated spinner/progress during connection attempt
   - Error state (wrong password, timeout) with message + color transition

5. **Footer**: "Network Settings" button → `nm-connection-editor`
   - Full-width, hover highlight, subtle arrow icon

**Animations (matching Theme.durationFast/Med/Slow):**
- Panel open/close: opacity 0→1, yScale 0.96→1.0 (same Popout base class)
- Wifi toggle: pill color transition
- Connection state changes: crossfade text/info
- Network list items: staggered fade-in on scan
- Password field expand: height animation
- Hover effects: color, scale transitions

### Registry changes

**`Globals.qml`:**
```qml
property var networkPanel: null
```

**`shell.qml`:**
```qml
NetworkPanel { id: networkPanel }
// component init: Globals.networkPanel = networkPanel
// IPC handler for "network" target
```

**`Bar.qml`:**
```qml
NetworkSegment { Layout.alignment: Qt.AlignVCenter }
// Insert between BluetoothSegment and VolumeSegment
```

## Data Flow

```
nmcli radio/device
      ↓
network-status --watch  ──→  NetworkSegment (icon + tooltip)
      ↓
network-status --watch  ──→  NetworkPanel (current connection)
network-scan (on open)   ──→  NetworkPanel (available networks)
user action (connect/...) ──→  nmcli command via Process
```

## Files to Create/Modify

### New files:
- `scripts/.local/bin/network-status`: watch script (like bluetooth-status)
- `scripts/.local/bin/network-scan`: one-shot scan script
- `quickshell/.config/quickshell/NetworkSegment.qml`: bar icon
- `quickshell/.config/quickshell/NetworkPanel.qml`: popout panel

### Modified files:
- `quickshell/.config/quickshell/Globals.qml`: add `networkPanel`
- `quickshell/.config/quickshell/shell.qml`: instantiate NetworkPanel
- `quickshell/.config/quickshell/Bar.qml`: add NetworkSegment

## Testing

- `bats test/`: existing tests must still pass
- Manual: click network icon, verify scan populates, connect to open/secured
  network, disconnect, toggle wifi off/on, verify icon updates live
