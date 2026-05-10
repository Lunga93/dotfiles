pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store

    property string settingsPath: Quickshell.env("HOME") + "/.config/dotfiles/settings.json"
    property string currentWallpaper: ""
    property string selectedMood: ""
    property string moodCachePath: Quickshell.env("HOME") + "/.cache/dotfiles/wallpaper-moods.json"

    property var data: ({
        "wallpaper": {
            "frequency": "daily",
            "skip_today": false,
            "sources_enabled": {
                "local": true,
                "unsplash": true,
                "reddit": true,
                "bing": true,
                "picsum": true
            },
            "sources_order": ["local", "unsplash", "reddit", "bing", "picsum"],
            "custom_subreddits": ["wallpapers", "earthporn", "minimalwallpaper"],
            "unsplash_api_key": "",
            "recent": [],
            "favorites": [],
            "library_dir": "",
            "selected_mood": null
        },
        "appearance": {
            "accent_mode": "dynamic",
            "manual_accent": null
        }
    })

    signal changed()

    property FileView _file: FileView {
        path: store.settingsPath
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                for (const key in parsed) {
                    if (parsed.hasOwnProperty(key) && store.data.hasOwnProperty(key)) {
                        Object.assign(store.data[key], parsed[key]);
                    }
                }
                store.changed();
                store.loadSelectedMood();
            } catch (e) {
                console.warn("SettingsStore: failed to parse settings, keeping defaults");
            }
        }
        onLoadFailed: store.save()
    }

    property FileView _wallpaperFile: FileView {
        path: Quickshell.env("HOME") + "/.config/current_wallpaper"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: {
            store.currentWallpaper = text().trim();
        }
    }

    property Process _writer: Process { command: ["true"] }
    property Process _exec: Process { command: ["true"] }

    function save(): void {
        const json = JSON.stringify(store.data, null, 2);
        const cmd = "mkdir -p " + Quickshell.env("HOME") + "/.config/dotfiles && cat > '" + store.settingsPath + "' << 'ENDOFFILE'\n" + json + "\nENDOFFILE";
        _writer.command = ["bash", "-c", cmd];
        _writer.startDetached();
    }

    function set(section: string, key: string, value: var): void {
        if (!store.data[section]) {
            store.data[section] = {};
        }
        store.data[section][key] = value;
        save();
        store.changed();
    }

    function loadSelectedMood(): void {
        const mood = store.get("wallpaper", "selected_mood");
        store.selectedMood = mood || "";
    }

    function get(section: string, key: string): var {
        if (store.data[section]) {
            return store.data[section][key];
        }
        return null;
    }

    function execScript(cmd: string): void {
        _exec.command = ["bash", "-c", cmd];
        _exec.startDetached();
    }

    function setWallpaper(path: string): void {
        execScript("~/.local/bin/set-wallpaper '" + path + "'");
        // push to recent (max 10, dedup, MRU first)
        let recent = store.data.wallpaper.recent || [];
        recent = recent.filter(p => p !== path);
        recent.unshift(path);
        if (recent.length > 10) recent = recent.slice(0, 10);
        set("wallpaper", "recent", recent);
    }

    function fetchWallpaper(): void {
        execScript("~/.local/bin/fetch-wallpaper");
    }

    function setManualAccent(hex: string): void {
        set("appearance", "manual_accent", hex);
        set("appearance", "accent_mode", "manual");
        execScript("echo '" + hex + "' > ~/.local/share/dotfiles/last_accent && ~/.local/bin/apply-theme \"$(cat ~/.config/current_wallpaper)\"");
    }

    function setAccentMode(mode: string): void {
        set("appearance", "accent_mode", mode);
        if (mode === "dynamic") {
            execScript("~/.local/bin/apply-theme \"$(cat ~/.config/current_wallpaper)\"");
        }
    }
}
