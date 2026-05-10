pragma Singleton
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

QtObject {
    id: catalog

    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/dotfiles/wallpaper-moods.json"

    readonly property var moods: [
        { id: "dark",  label: "Dark",  icon: "moon",   gradientStart: "#0a0a14", gradientEnd: "#1a1a28" },
        { id: "light", label: "Light", icon: "sun",     gradientStart: "#f0f0f5", gradientEnd: "#e0e0ea" },
        { id: "warm",  label: "Warm",  icon: "image",   gradientStart: "#cc4a3a", gradientEnd: "#ffa85f" },
        { id: "cool",  label: "Cool",  icon: "image",   gradientStart: "#3a5fcc", gradientEnd: "#5fb1ff" },
        { id: "sky",   label: "Sky",   icon: "image",   gradientStart: "#5fa8e8", gradientEnd: "#e8c89a" },
        { id: "earth", label: "Earth", icon: "image",   gradientStart: "#3a4a2a", gradientEnd: "#a8884a" }
    ]

    property var _moodCache: ({})
    property var _pathCache: ({})
    property int _totalTagged: 0

    function moodCount(moodId: string): int {
        if (_moodCache[moodId]) return _moodCache[moodId].length;
        return 0;
    }

    function wallpapersForMood(moodId: string): var {
        return _moodCache[moodId] || [];
    }

    function hasMood(path: string, moodId: string): bool {
        const moods = _pathCache[path];
        if (!moods) return false;
        return moods.indexOf(moodId) >= 0;
    }

    property FileView _cacheFile: FileView {
        path: catalog.cachePath
        preload: true
        onFileChanged: reload()
        onLoaded: catalog._parse(text())
        onLoadFailed: {
            console.warn("MoodCatalog: no mood cache found at", catalog.cachePath);
            catalog._moodCache = {};
            catalog._pathCache = {};
            catalog._totalTagged = 0;
        }
    }

    function _parse(rawJson: string): void {
        try {
            const parsed = JSON.parse(rawJson);
            const tags = parsed.tags || {};
            const inverted = {};
            const forward = {};
            let count = 0;

            for (const path in tags) {
                if (!tags.hasOwnProperty(path)) continue;
                const entry = tags[path];
                const moods = entry.moods || [];
                if (moods.length === 0) continue;

                forward[path] = moods;
                count++;

                for (let i = 0; i < moods.length; i++) {
                    const m = moods[i];
                    if (!inverted[m]) inverted[m] = [];
                    inverted[m].push(path);
                }
            }

            catalog._moodCache = inverted;
            catalog._pathCache = forward;
            catalog._totalTagged = count;
            console.log("MoodCatalog: loaded", count, "tagged wallpapers");
        } catch (e) {
            console.warn("MoodCatalog: failed to parse cache:", e);
            catalog._moodCache = {};
            catalog._pathCache = {};
            catalog._totalTagged = 0;
        }
    }

    function refresh(): void {
        _cacheFile.reload();
    }
}
