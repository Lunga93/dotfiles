pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store

    // bindings: array of { key, action, props } pulled from niri config
    property var bindings: []
    property bool loading: false
    property string lastError: ""

    // Pending rebind context: when set/reload is triggered we remember the
    // operation so onExited can emit the right signal back to the UI.
    property string _pendingOld: ""
    property string _pendingNew: ""

    signal bindingsLoaded()
    signal setSucceeded(string oldKey, string newKey)
    signal setFailed(string oldKey, string newKey, int code, string message)

    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/niri-keybind"

    Component.onCompleted: store.reload()

    property Process _lister: Process {
        command: ["bash", "-c", "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text;
                try {
                    const parsed = JSON.parse(raw);
                    if (Array.isArray(parsed)) {
                        store.bindings = parsed;
                        store.lastError = "";
                        store.bindingsLoaded();
                    } else {
                        store.lastError = "unexpected output from niri-keybind list";
                    }
                } catch (e) {
                    store.lastError = "failed to parse niri-keybind list output";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) store.lastError = text.trim();
            }
        }
        onRunningChanged: {
            if (!running) store.loading = false;
        }
    }

    property Process _setter: Process {
        command: ["bash", "-c", "true"]
        property string capturedStderr: ""
        stderr: StdioCollector {
            onStreamFinished: _setter.capturedStderr = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                store.setSucceeded(store._pendingOld, store._pendingNew);
                store.reload();
            } else {
                const msg = _setter.capturedStderr || ("exit " + exitCode);
                store.setFailed(store._pendingOld, store._pendingNew, exitCode, msg);
            }
            _setter.capturedStderr = "";
        }
    }

    function reload() {
        store.loading = true;
        _lister.command = [store.scriptPath, "list"];
        _lister.running = true;
    }

    function setBinding(oldKey: string, newKey: string) {
        if (!oldKey || !newKey) return;
        if (oldKey === newKey) {
            store.setSucceeded(oldKey, newKey);
            return;
        }
        store._pendingOld = oldKey;
        store._pendingNew = newKey;
        _setter.command = [store.scriptPath, "set", oldKey, newKey];
        _setter.running = true;
    }

    function bindingFor(actionBody: string) {
        for (let i = 0; i < store.bindings.length; ++i) {
            if (store.bindings[i].action === actionBody) return store.bindings[i];
        }
        return null;
    }

    function hasKey(key: string): bool {
        for (let i = 0; i < store.bindings.length; ++i) {
            if (store.bindings[i].key === key) return true;
        }
        return false;
    }
}
