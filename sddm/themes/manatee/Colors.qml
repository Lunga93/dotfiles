import QtQuick

QtObject {
    id: root

    property color background: "#1c1c1e"
    property color foreground: "#f5f5f7"
    property color accent:     "#0a84ff"
    property color viewBg:     "#26262a"

    // Card surface: blend background with a touch of white before applying
    // alpha. Pure background+alpha disappears on dark wallpapers.
    readonly property color surface:        Qt.rgba(
        background.r * 0.85 + 0.15,
        background.g * 0.85 + 0.15,
        background.b * 0.85 + 0.15,
        0.78)
    readonly property color surfaceDeep:    Qt.rgba(background.r, background.g, background.b, 0.92)
    readonly property color surfaceElev:    Qt.rgba(1, 1, 1, 0.08)
    readonly property color surfaceHover:   Qt.rgba(1, 1, 1, 0.14)
    readonly property color surfacePressed: Qt.rgba(1, 1, 1, 0.20)
    readonly property color border:         Qt.rgba(1, 1, 1, 0.10)
    readonly property color borderStrong:   Qt.rgba(1, 1, 1, 0.18)

    readonly property color textPrimary:   foreground
    readonly property color textSecondary: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.65)
    readonly property color textTertiary:  Qt.rgba(foreground.r, foreground.g, foreground.b, 0.40)

    readonly property color destructive: "#ff453a"
    readonly property color warning:     "#ffd60a"
    readonly property color success:     accent

    readonly property color accentSoft:  Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentMuted: Qt.rgba(accent.r, accent.g, accent.b, 0.55)

    readonly property color dimOverlay:  Qt.rgba(0, 0, 0, 0.35)
}
