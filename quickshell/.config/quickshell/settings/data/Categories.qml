pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: categories

    readonly property var all: [
        {
            section: "Personalization",
            items: [
                { id: "wallpaper",  label: "Wallpaper",  icon: "image",  ship: 1 },
                { id: "appearance", label: "Appearance", icon: "palette", ship: 2 },
                { id: "icons",      label: "Icons",      icon: "shapes",  ship: 2 },
            ]
        },
        {
            section: "System",
            items: [
                { id: "display",    label: "Display",    icon: "monitor",      ship: 3 },
                { id: "keybindings",label: "Keybindings",icon: "keyboard",     ship: 3 },
                { id: "network",    label: "Network",    icon: "wifi-high",    ship: 4 },
                { id: "sound",      label: "Sound",      icon: "speaker-high", ship: 4 },
            ]
        },
        {
            section: "About",
            items: [
                { id: "system-info", label: "System Info", icon: "info", ship: 4 },
            ]
        }
    ]
}
