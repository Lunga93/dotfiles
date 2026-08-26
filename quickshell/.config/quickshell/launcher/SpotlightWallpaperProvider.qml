// Wallpaper search provider — reads ~/Pictures/wallpapers/ and applies via set-wallpaper.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string query: ""
    property var results: []
    property var _wallpapers: []
    property bool loading: false
    property bool available: true
    property var error: null

    Process {
        id: wallpaperScan
        command: ["bash", "-c", `
            dir="$HOME/Pictures/wallpapers"
            [ -d "$dir" ] || exit 0
            find "$dir" -maxdepth 2 -type f \( \
                -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
                -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \
            \) | sort | head -500
        `]
        running: false
        onRunningChanged: {
            root.loading = false;
            if (!running && exitCode === 0) {
                root._wallpapers = stdout.trim().split("\n")
                    .filter(l => l.length > 0);
                root.available = true;
                root.error = null;
                root.rebuild();
            } else if (!running) {
                root.available = false;
                root.error = { message: "Wallpapers directory not found" };
            }
        }
    }

    Component.onCompleted: { root.loading = true; wallpaperScan.running = true; }

    function basename(path) {
        const parts = String(path).split("/");
        return parts[parts.length - 1] || path;
    }

    function rebuild() {
        const needle = String(root.query || "").trim().toLocaleLowerCase();
        const next = [];
        for (let index = 0; index < root._wallpapers.length; index += 1) {
            const path = String(root._wallpapers[index] || "");
            if (path === "") continue;
            const name = root.basename(path);
            if (needle !== ""
                    && name.toLocaleLowerCase().indexOf(needle) < 0)
                continue;
            next.push({
                provider: "wallpapers",
                id: path,
                title: name,
                subtitle: "wallpaper",
                icon: "",
                preview: "file://" + path,
                score: needle === "" ? 0
                    : (name.toLocaleLowerCase().startsWith(needle) ? 2 : 1),
                actions: ["apply"],
                path: path
            });
        }
        next.sort((left, right) => {
            if (right.score !== left.score)
                return right.score - left.score;
            return left.title.localeCompare(right.title);
        });
        root.results = next;
    }

    function execute(index) {
        const result = root.results[index];
        if (!result || !result.path)
            return false;
        applyWallpaper.command = ["set-wallpaper", result.path];
        applyWallpaper.running = true;
        return true;
    }

    Process {
        id: applyWallpaper
        command: []
        running: false
    }

    onQueryChanged: rebuild()
}
