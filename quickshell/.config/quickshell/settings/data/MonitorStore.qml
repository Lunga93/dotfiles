pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: store

    property var monitors: []
    property bool loaded: false

    property Process _scanner: Process {
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text;
                try {
                    const data = JSON.parse(raw);
                    const list = [];
                    for (const connector in data) {
                        if (!data.hasOwnProperty(connector)) continue;
                        const m = data[connector];
                        const logical = m.logical || {};
                        list.push({
                            connector: connector,
                            name: m.name || connector,
                            make: m.make || "",
                            model: m.model || "",
                            serial: m.serial || "",
                            width: logical.width || 0,
                            height: logical.height || 0,
                            x: logical.x || 0,
                            y: logical.y || 0,
                            scale: logical.scale || 1.0,
                            transform: logical.transform || "Normal",
                            modes: m.modes || [],
                            currentMode: m.current_mode !== undefined ? m.current_mode : 0,
                            enabled: true
                        });
                    }
                    list.sort((a, b) => a.x - b.x || a.y - b.y);
                    store.monitors = list;
                    store.loaded = true;
                } catch (e) {
                    console.warn("MonitorStore: failed to parse niri outputs", e);
                }
            }
        }
        stderr: StdioCollector {}
    }

    property Process _exec: Process { command: ["true"] }

    function refresh(): void {
        _scanner.command = ["bash", "-c", "niri msg -j outputs 2>/dev/null || echo '{}'"];
        _scanner.running = true;
    }

    function modeLabel(mode): string {
        if (!mode) return "";
        const w = mode.width || 0;
        const h = mode.height || 0;
        const hz = mode.refresh_rate ? (mode.refresh_rate / 1000).toFixed(2) : "60";
        return w + "\u00D7" + h + " @ " + hz + " Hz";
    }

    function currentModeLabel(monitor): string {
        if (!monitor || !monitor.modes) return "";
        const idx = monitor.currentMode || 0;
        const mode = monitor.modes[idx];
        return modeLabel(mode);
    }

    function setMode(monitor, modeIndex): void {
        if (!monitor) return;
        const name = monitor.connector || monitor.name;
        const mode = monitor.modes[modeIndex];
        if (!mode) return;
        const modeStr = mode.width + "x" + mode.height + "@" + (mode.refresh_rate || 60000);
        _exec.command = ["bash", "-c", "niri msg output '" + name + "' mode '" + modeStr + "' && niri msg action load-config-file"];
        _exec.startDetached();
    }

    function setScale(monitor, scale): void {
        if (!monitor) return;
        const name = monitor.connector || monitor.name;
        _exec.command = ["bash", "-c", "niri msg output '" + name + "' scale " + scale + " && niri msg action load-config-file"];
        _exec.startDetached();
    }

    function applyConfig(): void {
        _exec.command = ["bash", "-c", "~/.local/bin/apply-monitors"];
        _exec.startDetached();
    }

    Component.onCompleted: refresh()
}
