pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store

    property string settingsPath: Quickshell.env("HOME") + "/.config/dotfiles/settings.json"
    property string currentWallpaper: ""
    property int wallpaperVersion: 0  // bumps on every reload to cache-bust Image{} sources
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
            "manual_primary": null,
            "manual_secondary": null
        },
        "top_bar": {
            "gradient_style": "off",
            "gradient_intensity": 0.5,
            "background_opacity": 0.85,
            "text_glow": 0.0,
            "font_family": "",
            "font_weight": "Regular"
        },
        "display": {
            "scale": 1.0,
            "night_light_enabled": false,
            "night_light_temperature": 4000
        },
        "icons": {
            "icon_theme": "Papirus",
            "cursor_theme": "Capitaine",
            "cursor_size": 24
        },
        "sound": {
            "output_volume": 100,
            "output_muted": false,
            "input_volume": 100,
            "input_muted": false,
            "alert_sounds_enabled": true
        },
        "network": {
            "wifi_enabled": true
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
                store.migrateAccentFields();
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
            // Bump even if path string is unchanged — fetch-wallpaper rewrites
            // a fixed path (daily.jpg) in place, so the URL stays the same and
            // Qt's image cache would otherwise serve stale pixels.
            store.wallpaperVersion += 1;
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

    function migrateAccentFields(): void {
        const app = store.data.appearance || {};
        if (app.manual_accent && !app.manual_primary) {
            app.manual_primary = app.manual_accent;
        }
        if ("manual_accent" in app) delete app.manual_accent;
        store.data.appearance = app;
    }

    function setManualPrimary(hex: string): void {
        set("appearance", "manual_primary", hex);
        set("appearance", "accent_mode", "manual");
        reapplyTheme();
    }

    function setManualSecondary(hex: string): void {
        set("appearance", "manual_secondary", hex);
        set("appearance", "accent_mode", "manual");
        reapplyTheme();
    }

    function setAccentMode(mode: string): void {
        set("appearance", "accent_mode", mode);
        reapplyTheme();
    }

    function reapplyTheme(): void {
        execScript("~/.local/bin/apply-theme \"$(cat ~/.config/current_wallpaper)\"");
    }

    // Kept for backward compat with any callers still using setManualAccent.
    function setManualAccent(hex: string): void {
        setManualPrimary(hex);
    }

    // ── Display ──
    property var displayScale: get("display", "scale")
    property var nightLightEnabled: get("display", "night_light_enabled")
    property var nightLightTemperature: get("display", "night_light_temperature")

    function setDisplayScale(scale: string): void { set("display", "scale", scale) }
    function setNightLightEnabled(enabled: bool): void { set("display", "night_light_enabled", enabled) }
    function setNightLightTemperature(temp: int): void { set("display", "night_light_temperature", temp) }

    // ── Top Bar ──
    property var topBarGradientIntensity: get("top_bar", "gradient_intensity")
    property var topBarBgOpacity: get("top_bar", "background_opacity")
    property var topBarTextGlow: get("top_bar", "text_glow")
    property var topBarGradientStyle: get("top_bar", "gradient_style")
    property var topBarFontFamily: get("top_bar", "font_family")
    property var topBarFontWeight: get("top_bar", "font_weight")

    // ── Icons ──
    property var iconTheme: get("icons", "icon_theme")
    property var cursorTheme: get("icons", "cursor_theme")
    property var cursorSize: get("icons", "cursor_size")

    function setIconTheme(theme: string): void {
        set("icons", "icon_theme", theme);
        execScript("gsettings set org.gnome.desktop.interface icon-theme '" + theme + "'");
    }
    function setCursorTheme(theme: string): void {
        set("icons", "cursor_theme", theme);
        execScript("gsettings set org.gnome.desktop.interface cursor-theme '" + theme + "'");
    }
    function setCursorSize(size: int): void {
        set("icons", "cursor_size", size);
        execScript("gsettings set org.gnome.desktop.interface cursor-size " + size);
    }

    // ── Sound ──
    property var outputVolume: get("sound", "output_volume")
    property var outputMuted: get("sound", "output_muted")
    property var inputVolume: get("sound", "input_volume")
    property var inputMuted: get("sound", "input_muted")
    property var alertSoundsEnabled: get("sound", "alert_sounds_enabled")

    function setOutputVolume(vol: int): void { set("sound", "output_volume", vol) }
    function setOutputMuted(muted: bool): void { set("sound", "output_muted", muted) }
    function setInputVolume(vol: int): void { set("sound", "input_volume", vol) }
    function setInputMuted(muted: bool): void { set("sound", "input_muted", muted) }
    function setAlertSoundsEnabled(enabled: bool): void { set("sound", "alert_sounds_enabled", enabled) }

    // ── Network ──
    property var wifiEnabled: get("network", "wifi_enabled")

    function setWifiEnabled(enabled: bool): void { set("network", "wifi_enabled", enabled) }
}
