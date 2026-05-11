pragma Singleton
import QtQuick
import ".."

QtObject {
    readonly property string name:     "Manatee"
    readonly property string tagline:  "A gentle, glossy Wayland desktop for Arch."
    readonly property string summary:  "Built on Niri and Quickshell, themed by your wallpaper."

    readonly property string repoUrl:  "https://github.com/Lunga93/dotfiles"
    readonly property string docsUrl:  "https://github.com/Lunga93/dotfiles/blob/main/README.md"

    readonly property var components: [
        {
            "name": "Niri",
            "blurb": "Scrollable-tiling Wayland compositor. Workspaces scroll vertically; columns scroll horizontally.",
            "icon": "window"
        },
        {
            "name": "Quickshell",
            "blurb": "Qt6/QML shell daemon that renders the bar and floating popouts (audio, calendar, power).",
            "icon": "dock"
        },
        {
            "name": "Wofi",
            "blurb": "Fuzzy app launcher. Press Mod+Space to open it.",
            "icon": "search"
        },
        {
            "name": "swaync",
            "blurb": "Notification daemon with a slide-out control center. Press Mod+N.",
            "icon": "bell"
        },
        {
            "name": "Alacritty",
            "blurb": "GPU-accelerated terminal. Press Mod+Return to launch.",
            "icon": "terminal"
        },
        {
            "name": "pywal",
            "blurb": "Generates a color palette from your wallpaper and themes every component live.",
            "icon": "palette"
        }
    ]
}
