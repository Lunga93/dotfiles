pragma Singleton
import QtQuick
import Quickshell.Io
import "../logic/monitors.js" as Monitors

QtObject {
    id: store

    property var monitors: []
    property bool loaded: false

    property Process _scanner: Process {
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    store.monitors = Monitors.parseMonitors(text);
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
        return Monitors.modeLabel(mode);
    }

    function currentModeLabel(monitor): string {
        return Monitors.currentModeLabel(monitor);
    }

    function setMode(monitor, modeIndex): void {
        if (!monitor) return;
        const name = monitor.connector || monitor.name;
        const mode = monitor.modes[modeIndex];
        if (!mode) return;
        const modeStr = Monitors.modeString(mode);
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
