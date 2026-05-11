pragma Singleton
import QtQuick
import ".."

QtObject {
    readonly property var essentials: [
        { "chord": "Mod+Space",   "label": "Open the launcher" },
        { "chord": "Mod+Return",  "label": "Open a terminal" },
        { "chord": "Mod+H/L",     "label": "Focus column left / right" },
        { "chord": "Mod+J/K",     "label": "Focus window down / up" },
        { "chord": "Mod+1-9",     "label": "Switch workspace" },
        { "chord": "Mod+Q",       "label": "Close the focused window" },
        { "chord": "Mod+F",       "label": "Toggle fullscreen" },
        { "chord": "Mod+Shift+W", "label": "Open the wallpaper picker" },
        { "chord": "Mod+N",       "label": "Toggle the notification center" },
        { "chord": "Mod+Shift+Escape", "label": "Show the full hotkey overlay" }
    ]
}
