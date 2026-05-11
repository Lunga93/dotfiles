import QtQuick
import Quickshell
import Quickshell.Io
import ".."

QtObject {
    id: root

    property ListModel items: ListModel {}
    property string errorText: ""
    property bool loaded: false

    readonly property string statePath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/manatee-welcome/keybinds.json"

    property FileView _file: FileView {
        path: root.statePath
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root._parse(text())
        onLoadFailed: root.errorText = "keybinds file not found"
    }

    function _parse(text: string): void {
        root.items.clear();
        if (!text || text.trim().length === 0) {
            root.errorText = "keybinds.json is empty";
            root.loaded = true;
            return;
        }
        try {
            const arr = JSON.parse(text);
            for (let i = 0; i < arr.length; i++) {
                root.items.append({
                    keys:   String(arr[i].keys   || ""),
                    action: String(arr[i].action || "")
                });
            }
            root.errorText = "";
            root.loaded = true;
        } catch (e) {
            root.errorText = "parse error: " + e;
            console.error("NiriKeybindsModel:", e);
        }
    }
}
