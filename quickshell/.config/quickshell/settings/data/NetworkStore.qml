// Shared network state for the bar popout and the Settings network page.
// Single watcher runs `network-status --watch`; scan + connection lists are
// fetched on demand. All mutating actions shell out to nmcli and let the
// watcher converge the snapshot back to reality.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store

    // Snapshot from network-status --watch.
    property var state: ({
        state: "disconnected", type: "", ssid: "", signal: 0, ip: "",
        wifi_hw: false, wifi_enabled: false, wifi_powered: false, devices: []
    })
    property var networks: []
    // Saved connections: [{name, type, autoconnect, device, active}]
    property var connections: []
    // VPN subset of connections.
    property var vpns: []
    property bool ready: false
    property bool scanning: false
    property string connectingSsid: ""
    property string statusMessage: ""
    // Inline password entry for a (secured, not-yet-saved) network.
    property string passwordSsid: ""
    property string passwordValue: ""
    // Revealed saved wifi password (per-connection, requested explicitly).
    property string revealedFor: ""
    property string revealedPassword: ""
    property string pwdTarget: ""

    readonly property bool connected: state.state === "connected"
    readonly property bool wifiConnected: connected && state.type === "wifi"
    readonly property bool wifiEnabled: !!state.wifi_enabled
    readonly property bool wifiHw: !!state.wifi_hw
    readonly property string activeConnection: store.activeConnName()

    // ── Live status watcher ───────────────────────────────────────────────────
    property Process watcher: Process {
        running: true
        command: ["sh", "-c", "exec ~/.local/bin/network-status --watch"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const s = JSON.parse(line);
                    store.state = s;
                    store.ready = true;
                    if (store.connectingSsid
                        && s.state === "connected" && s.type === "wifi"
                        && s.ssid === store.connectingSsid) {
                        store.connectingSsid = "";
                        store.setStatus("Connected to " + s.ssid);
                        store.connectTimer.stop();
                    }
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    // ── Scan ──────────────────────────────────────────────────────────────────
    property Process scanProc: Process {
        running: false
        command: ["true"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const d = JSON.parse(line);
                    store.networks = d.networks || [];
                    store.scanning = false;
                } catch (e) {
                    store.setStatus("Scan failed");
                }
            }
        }
        onRunningChanged: {
            if (!running) store.scanning = false;
        }
    }

    // ── Connection-list refresh ───────────────────────────────────────────────
    property Process connProc: Process {
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: store._parseConnections(text)
        }
    }

    // ── Actions: connect / up / down / forget / modify ────────────────────────
    property Process actionProc: Process {
        running: false
        command: ["true"]
        stdout: SplitParser { onRead: (line) => store._handleActionLine(line) }
        stderr: SplitParser { onRead: (line) => store._handleActionLine(line) }
    }

    property Process toggleProc: Process {
        running: false
        command: ["true"]
    }

    // ── Saved-password reveal ─────────────────────────────────────────────────
    property Process pwdProc: Process {
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: store._parsePassword(text)
        }
    }

    property Timer connectTimer: Timer {
        interval: 12000
        onTriggered: {
            if (store.connectingSsid !== "") {
                store.connectingSsid = "";
                store.setStatus("Connection timed out");
            }
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function doScan() {
        if (store.scanning) return;
        store.scanning = true;
        scanProc.command = ["sh", "-c", "exec ~/.local/bin/network-scan"];
        scanProc.running = true;
    }

    function refreshConnections() {
        connProc.command = [
            "sh", "-c",
            "nmcli -t -f NAME,TYPE,AUTOCONNECT,DEVICE,connection.autoconnect-priority connection show 2>/dev/null; " +
            "echo '---'; nmcli -t -f NAME connection show --active 2>/dev/null"
        ];
        connProc.running = true;
    }

    function toggleWifi(on) {
        toggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        toggleProc.startDetached();
        store.setStatus(on ? "Enabling Wi-Fi…" : "Disabling Wi-Fi…");
    }

    function connectToNetwork(ssid, secured, password) {
        if (store.connectingSsid) return;
        store.connectingSsid = ssid;
        store.passwordSsid = "";
        store.passwordValue = "";
        store.clearStatus();
        const cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (secured && password) {
            cmd.push("password");
            cmd.push(password);
        }
        actionProc.command = cmd;
        actionProc.running = true;
        connectTimer.start();
    }

    function connectSaved(name) {
        if (store.connectingSsid) return;
        store.connectingSsid = name;
        store.clearStatus();
        actionProc.command = ["nmcli", "connection", "up", name];
        actionProc.running = true;
        connectTimer.start();
    }

    function disconnectCurrent() {
        const name = store.activeConnection;
        if (!name) return;
        actionProc.command = ["nmcli", "connection", "down", name];
        actionProc.running = true;
        store.setStatus("Disconnecting…");
    }

    function forgetConnection(name) {
        toggleProc.command = ["nmcli", "connection", "delete", name];
        toggleProc.startDetached();
        store.setStatus("Forgot " + name);
        store._dropFromLists(name);
    }

    function setAutoconnect(name, on) {
        toggleProc.command = [
            "nmcli", "connection", "modify", name,
            "connection.autoconnect", on ? "yes" : "no"
        ];
        toggleProc.startDetached();
        store.setStatus(on ? "Autoconnect on for " + name : "Autoconnect off for " + name);
    }

    function setPriority(name, value) {
        toggleProc.command = [
            "nmcli", "connection", "modify", name,
            "connection.autoconnect-priority", String(value)
        ];
        toggleProc.startDetached();
    }

    function setDns(name, dns) {
        // One nmcli modify call sets both flags atomically.
        toggleProc.command = [
            "nmcli", "connection", "modify", name,
            "ipv4.ignore-auto-dns", dns ? "yes" : "no",
            "ipv4.dns", dns || ""
        ];
        toggleProc.startDetached();
        store.setStatus(dns ? "DNS updated for " + name : "DNS reset for " + name);
    }

    function showPassword(name) {
        store.revealedFor = "";
        store.revealedPassword = "";
        store.pwdTarget = name;
        pwdProc.command = ["nmcli", "-s", "connection", "show", name];
        pwdProc.running = true;
    }

    function vpnUp(name) { store.connectSaved(name); }
    function vpnDown(name) {
        actionProc.command = ["nmcli", "connection", "down", name];
        actionProc.running = true;
        store.setStatus("Disconnecting VPN…");
    }
    function vpnDelete(name) {
        store.forgetConnection(name);
        store.refreshConnections();
    }

    function setStatus(msg) { store.statusMessage = msg; }
    function clearStatus() { store.statusMessage = ""; }

    function activeConnName() {
        const devs = store.state.devices || [];
        for (const d of devs) {
            if (d.state === "connected" && d.connection) return d.connection;
        }
        return "";
    }

    // ── Internal ──────────────────────────────────────────────────────────────

    function _handleActionLine(line) {
        const t = line.trim();
        if (!t) return;
        if (t.indexOf("Error") >= 0 || t.indexOf("error:") >= 0
            || t.indexOf("Failed") >= 0) {
            store.connectingSsid = "";
            connectTimer.stop();
            store.setStatus(t);
            return;
        }
        if (t.indexOf("successfully activated") >= 0) {
            store.connectingSsid = "";
            connectTimer.stop();
            store.setStatus("Connected");
        }
    }

    function _parseConnections(text) {
        const [allPart, activePart] = text.split("---");
        const active = new Set();
        for (const line of (activePart || "").split("\n")) {
            const name = line.split(":")[0];
            if (name) active.add(name);
        }
        const conns = [];
        const vpns = [];
        for (const line of (allPart || "").split("\n")) {
            if (!line) continue;
            const parts = line.split(":");
            if (parts.length < 4) continue;
            const type = parts[1] || "";
            const name = parts[0];
            if (type.indexOf("vpn") >= 0 || type.indexOf("wireguard") >= 0) {
                vpns.push({
                    name: name,
                    type: type,
                    device: parts[3] || "",
                    active: active.has(name)
                });
            } else {
                conns.push({
                    name: name,
                    type: type,
                    autoconnect: (parts[2] || "").toLowerCase() === "yes",
                    device: parts[3] || "",
                    priority: parseInt(parts[4] || "0", 10) || 0,
                    active: active.has(name)
                });
            }
        }
        store.connections = conns;
        store.vpns = vpns;
    }

    function _parsePassword(text) {
        for (const line of text.split("\n")) {
            const idx = line.indexOf("802-11-wireless-security.psk:");
            if (idx >= 0) {
                const val = line.slice(idx + "802-11-wireless-security.psk:".length).trim();
                store.revealedFor = store.pwdTarget;
                store.revealedPassword = val || "(no password set)";
                return;
            }
        }
        store.revealedFor = store.pwdTarget;
        store.revealedPassword = "(not a Wi-Fi connection)";
    }

    function _dropFromLists(name) {
        store.connections = store.connections.filter(c => c.name !== name);
        store.vpns = store.vpns.filter(c => c.name !== name);
    }

    Component.onCompleted: {
        store.refreshConnections();
    }
}
