pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: categories

    readonly property var all: [
        {
            section: "Personalization",
            items: [
                { id: "wallpaper",  label: "Wallpaper",  icon: "image" },
                { id: "appearance", label: "Appearance", icon: "palette" },
                { id: "icons",      label: "Icons",      icon: "shapes" },
            ]
        },
        {
            section: "System",
            items: [
                { id: "display",    label: "Display",    icon: "monitor" },
                { id: "keybindings",label: "Keybindings",icon: "keyboard" },
                { id: "network",    label: "Network",    icon: "wifi-high" },
                { id: "sound",      label: "Sound",      icon: "speaker-high" },
            ]
        },
        {
            section: "About",
            items: [
                { id: "system-info", label: "System Info", icon: "info" },
            ]
        }
    ]
}
