// Design system + live palette. Watches ~/.cache/wal/colors.json (regenerated
// by pywal on every wallpaper change) and re-emits all theme tokens whenever
// it changes — no qs restart needed for a new theme.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var palette: ({
        background: "#1c1c1e",
        foreground: "#f5f5f7",
        primary:    "#0a84ff",
        secondary:  "#bf5af2",
        color0: "#1c1c1e", color1: "#ff453a", color2: "#0a84ff", color3: "#ffd60a",
        color4: "#0a84ff", color5: "#bf5af2", color6: "#64d2ff", color7: "#f5f5f7"
    })

    property FileView _walFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                const s = data.special || {};
                const c = data.colors  || {};
                // primary_accent / secondary_accent are written by apply-theme.
                // Fall back to color2/color5 for first run before apply-theme has touched the file.
                root.palette = {
                    background: s.background || "#1c1c1e",
                    foreground: s.foreground || "#f5f5f7",
                    primary:    c.primary_accent   || c.color2 || "#0a84ff",
                    secondary:  c.secondary_accent || c.color5 || "#bf5af2",
                    color0: c.color0 || "#1c1c1e",
                    color1: c.color1 || "#ff453a",
                    color2: c.color2 || "#0a84ff",
                    color3: c.color3 || "#ffd60a",
                    color4: c.color4 || "#0a84ff",
                    color5: c.color5 || "#bf5af2",
                    color6: c.color6 || "#64d2ff",
                    color7: c.color7 || "#f5f5f7"
                };
            } catch (e) {
                console.error("Theme: failed to parse pywal colors:", e);
            }
        }
    }

    function withAlpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property color background:    palette.background
    readonly property color foreground:    palette.foreground
    readonly property color primary:       palette.primary
    readonly property color secondary:     palette.secondary
    readonly property color accent:        palette.primary  // alias, backward-compat

    readonly property color color0: palette.color0
    readonly property color color1: palette.color1
    readonly property color color2: palette.color2
    readonly property color color3: palette.color3
    readonly property color color4: palette.color4
    readonly property color color5: palette.color5
    readonly property color color6: palette.color6
    readonly property color color7: palette.color7

    readonly property color surface:        withAlpha(background, 0.92)
    readonly property color surfaceDeep:    withAlpha(background, 0.65)
    readonly property color surfaceElev:    Qt.rgba(1, 1, 1, 0.08)
    readonly property color surfaceHover:   Qt.rgba(1, 1, 1, 0.14)
    readonly property color surfacePressed: Qt.rgba(1, 1, 1, 0.20)
    readonly property color border:         Qt.rgba(1, 1, 1, 0.10)
    readonly property color textPrimary:    foreground
    readonly property color textSecondary:  withAlpha(foreground, 0.65)
    readonly property color textTertiary:   withAlpha(foreground, 0.40)
    readonly property color destructive:    "#ff453a"

    readonly property color accentSoft:       withAlpha(primary, 0.18)
    readonly property color accentMuted:      withAlpha(primary, 0.55)
    readonly property color secondarySoft:    withAlpha(secondary, 0.18)
    readonly property color secondaryMuted:   withAlpha(secondary, 0.55)

    readonly property int radiusCard:    18
    readonly property int radiusControl: 12
    readonly property int radiusPill:    16
    readonly property int radiusRound:   999

    readonly property int unit: 4

    readonly property int barHeight:     36
    readonly property int barMarginTop:  8
    readonly property int barMarginSide: 12
    readonly property int barFontSize:   13
    readonly property color barPillBg:   withAlpha(background, 0.55)
    readonly property int segmentGap:    8
    readonly property int barIconSize:   16

    readonly property int durationFast:   140
    readonly property int durationMed:    220
    readonly property int durationSlow:   320

    readonly property string fontFamily: "Fira Sans"
    readonly property string fontMono:   "MesloLGS Nerd Font Mono"
}
