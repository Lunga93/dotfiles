// App search provider — reads .desktop files and scores them against the query.
// Replaces Clavis's ApplicationService with a script-based approach.

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string query: ""
    property var results: []
    property int limit: 50
    property var _apps: []
    property bool loading: false
    property bool available: true
    property var error: null

    // Parse .desktop files from standard XDG paths
    Process {
        id: desktopScan
        command: ["bash", "-c", `
            for dir in /usr/share/applications ~/.local/share/applications; do
                [ -d "$dir" ] || continue
                for f in "$dir"/*.desktop; do
                    [ -f "$f" ] || continue
                    # Skip hidden/no-display
                    grep -q "^NoDisplay=true" "$f" && continue
                    grep -q "^Hidden=true" "$f" && continue
                    name=$(grep "^Name=" "$f" | head -1 | cut -d= -f2-)
                    generic=$(grep "^GenericName=" "$f" | head -1 | cut -d= -f2-)
                    comment=$(grep "^Comment=" "$f" | head -1 | cut -d= -f2-)
                    exec=$(grep "^Exec=" "$f" | head -1 | cut -d= -f2-)
                    icon=$(grep "^Icon=" "$f" | head -1 | cut -d= -f2-)
                    keywords=$(grep "^Keywords=" "$f" | head -1 | cut -d= -f2-)
                    id=$(basename "$f" .desktop)
                    printf '{"id":"%s","name":"%s","generic":"%s","comment":"%s","exec":"%s","icon":"%s","keywords":"%s"}\\n' \
                        "$id" "$name" "$generic" "$comment" "$exec" "$icon" "$keywords"
                done
            done
        `]
        running: false
        onRunningChanged: {
            root.loading = false;
            if (!running && exitCode === 0) {
                const lines = stdout.trim().split("\n").filter(l => l.length > 0);
                root._apps = lines.map(line => {
                    try { return JSON.parse(line); }
                    catch(e) { return null; }
                }).filter(a => a !== null && a.name !== "");
                root.available = true;
                root.error = null;
                root.rebuild();
            } else if (!running) {
                root.available = false;
                root.error = { message: "Failed to scan .desktop files" };
            }
        }
    }

    Component.onCompleted: { root.loading = true; desktopScan.running = true; }

    function normalized(value) {
        return String(value || "").trim().toLocaleLowerCase();
    }

    function isWordStart(text, query) {
        if (text.startsWith(query))
            return true;
        for (let index = 1; index < text.length; index += 1) {
            const previous = text.charAt(index - 1);
            if ((previous === " " || previous === "-" || previous === "_"
                    || previous === "." || previous === "/")
                    && text.indexOf(query, index) === index)
                return true;
        }
        return false;
    }

    function subsequencePenalty(text, query) {
        let queryIndex = 0;
        let firstIndex = -1;
        let lastIndex = -1;
        for (let index = 0; index < text.length && queryIndex < query.length;
                index += 1) {
            if (text.charAt(index) !== query.charAt(queryIndex))
                continue;
            if (firstIndex < 0)
                firstIndex = index;
            lastIndex = index;
            queryIndex += 1;
        }
        if (queryIndex !== query.length)
            return -1;
        return Math.max(0, lastIndex - firstIndex - query.length + 1);
    }

    function fieldScore(value, needle, weight) {
        const text = normalized(value);
        if (text === "" || needle === "")
            return needle === "" ? weight : -1;
        if (text === needle)
            return 5000 + weight;
        if (text.startsWith(needle))
            return 4000 + weight - Math.min(99, text.length - needle.length);
        if (isWordStart(text, needle))
            return 3000 + weight;
        const substringIndex = text.indexOf(needle);
        if (substringIndex >= 0)
            return 2000 + weight - Math.min(99, substringIndex);
        const penalty = subsequencePenalty(text, needle);
        return penalty >= 0 ? 1000 + weight - Math.min(99, penalty) : -1;
    }

    function appScore(app, needle) {
        if (needle === "")
            return 0;
        let best = -1;
        best = Math.max(best, fieldScore(app.name, needle, 80));
        best = Math.max(best, fieldScore(app.generic, needle, 60));
        best = Math.max(best, fieldScore(app.keywords, needle, 40));
        best = Math.max(best, fieldScore(app.id, needle, 20));
        return best;
    }

    function rebuild() {
        const needle = normalized(root.query);
        const next = [];
        for (let index = 0; index < root._apps.length; index += 1) {
            const app = root._apps[index];
            if (!app) continue;
            const score = appScore(app, needle);
            if (score < 0) continue;
            next.push({
                provider: "apps",
                id: String(app.id || app.name || index),
                title: String(app.name || app.id || ""),
                subtitle: String(app.generic || app.comment || app.id || ""),
                icon: String(app.icon || ""),
                preview: "",
                score: score,
                actions: ["launch"],
                exec: String(app.exec || "")
            });
        }
        next.sort((left, right) => {
            if (right.score !== left.score)
                return right.score - left.score;
            const byName = left.title.localeCompare(right.title);
            return byName !== 0 ? byName : left.id.localeCompare(right.id);
        });
        root.results = next.slice(0, root.limit);
    }

    function execute(index) {
        const result = root.results[index];
        if (!result || !result.exec)
            return false;
        // Strip %f, %u, etc. from exec line
        const cmd = result.exec.replace(/\s*%[fFuUdDnNmickv]/g, "").trim();
        launcherExec.command = ["bash", "-c", cmd + " &"];
        launcherExec.running = true;
        return true;
    }

    Process {
        id: launcherExec
        command: []
        running: false
    }

    onQueryChanged: rebuild()
}
