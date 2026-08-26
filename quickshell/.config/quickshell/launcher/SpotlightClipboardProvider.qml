// Clipboard search provider — uses cliphist for history, wl-copy/wl-paste for restore.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string query: ""
    property var results: []
    property bool loading: false
    property bool available: _cliphistAvailable
    property bool _cliphistAvailable: false
    property var error: null

    readonly property var resultModel: clipboardListModel

    ListModel { id: clipboardListModel }

    Process {
        id: cliphistCheck
        command: ["bash", "-c", "command -v cliphist >/dev/null 2>&1 && echo ok || echo missing"]
        running: false
        onRunningChanged: {
            if (!running) {
                root._cliphistAvailable = stdout.trim() === "ok";
                if (root._cliphistAvailable)
                    root.refresh();
            }
        }
    }

    Process {
        id: cliphistList
        command: ["cliphist", "list"]
        running: false
        onRunningChanged: {
            root.loading = false;
            if (!running && exitCode === 0) {
                root._rawEntries = stdout.trim().split("\n")
                    .filter(l => l.length > 0);
                root.error = null;
                root.rebuild();
            } else if (!running) {
                root.error = { message: "Failed to read clipboard history" };
            }
        }
    }

    property var _rawEntries: []

    Component.onCompleted: cliphistCheck.running = true

    function refresh() {
        root.loading = true;
        cliphistList.running = true;
    }

    function rebuild() {
        const needle = String(root.query || "").trim().toLocaleLowerCase();
        const next = [];
        clipboardListModel.clear();
        for (let index = 0; index < root._rawEntries.length; index += 1) {
            const entry = root._rawEntries[index];
            if (!entry || entry === "") continue;
            // cliphist entries look like "id\tpreview" or "id\tbinary"
            const tabPos = entry.indexOf("\t");
            const id = tabPos >= 0 ? entry.substring(0, tabPos) : entry;
            const preview = tabPos >= 0 ? entry.substring(tabPos + 1) : entry;
            const searchable = preview.toLocaleLowerCase();
            if (needle !== "" && searchable.indexOf(needle) < 0) continue;
            next.push({
                provider: "clipboard",
                id: id,
                title: preview.substring(0, 120),
                subtitle: preview.length > 120 ? "…" : "clipboard",
                icon: "content_paste",
                preview: "",
                score: needle === "" ? root._rawEntries.length - index
                    : (searchable.startsWith(needle) ? 2 : 1),
                actions: ["restore"],
                rawEntry: entry
            });
            clipboardListModel.append({ clipboardEntryId: id });
        }
        root.results = next;
    }

    function execute(index) {
        const result = root.results[index];
        if (!result) return false;
        restoreEntry.command = ["bash", "-c",
            "echo '" + result.id + "' | cliphist decode | wl-copy"];
        restoreEntry.running = true;
        return true;
    }

    function deleteEntry(index) {
        const result = root.results[index];
        if (!result) return false;
        deleteEntry_.command = ["bash", "-c",
            "echo '" + result.id + "' | cliphist delete"];
        deleteEntry_.running = true;
        // Remove from local list
        clipboardListModel.remove(index);
        const next = root.results.slice();
        next.splice(index, 1);
        root.results = next;
        return true;
    }

    function clear() {
        clearAll.running = true;
        clipboardListModel.clear();
        root.results = [];
    }

    Process {
        id: restoreEntry
        command: []
        running: false
    }

    Process {
        id: deleteEntry_
        command: []
        running: false
    }

    Process {
        id: clearAll
        command: ["cliphist", "wipe"]
        running: false
    }

    onQueryChanged: rebuild()
}
