// Spotlight design tokens for Manatee Desktop.
// Colors from Theme.* (pywal palette).

import QtQuick
import "../"

QtObject {
    // ── Surface colors ───────────────────────────────────────────────
    readonly property color surfaceColor:      Theme.withAlpha(Theme.background, 0.88)
    readonly property color panelColor:        Theme.withAlpha(Theme.background, 0.82)
    readonly property color selectedColor:     Theme.withAlpha(Theme.primary, 0.22)
    readonly property color selectedContentColor: Theme.foreground
    readonly property color hoverColor:        Theme.withAlpha(Theme.foreground, 0.08)
    readonly property color shadowColor:       Theme.withAlpha(Theme.color0, 0.40)

    // ── Dimensions ───────────────────────────────────────────────────
    readonly property int canvasWidth: 1100
    readonly property int searchWidth: 760
    readonly property int compactSideReserve: 340
    readonly property int searchHeight: 64
    readonly property int searchHorizontalPadding: 22
    readonly property int searchIconSize: 24
    readonly property int modeButtonCount: 3
    readonly property int modeButtonDiameter: searchHeight
    readonly property int modeButtonGap: 10
    readonly property int resultGap: 12
    readonly property int resultRadius: Theme.radiusCard
    readonly property int resultPadding: 10
    readonly property int resultMaxHeight: 440
    readonly property int resultRowHeight: 64
    readonly property int resultIconSize: 40
    readonly property int effectBleed: 18
    readonly property int wallpaperPanelWidth: 1240
    readonly property int wallpaperGridHeight: 600
    readonly property int wallpaperPanelPadding: 16
    readonly property int wallpaperMaxColumns: 5
    readonly property int wallpaperMinPreviewWidth: 210
    readonly property int wallpaperGridGap: 16
    readonly property real wallpaperPreviewAspectRatio: 16 / 9
    readonly property int wallpaperLabelGap: 8
    readonly property int wallpaperLabelHeight: 28
    readonly property int wallpaperLabelFontSize: 14
    readonly property real wallpaperHoverScale: 1.045
    readonly property int wallpaperHoverDuration: 200
    readonly property int windowHorizontalMargin: 32
    readonly property int windowBottomMargin: 40
    readonly property int emptyHeight: 150

    // ── Animation ────────────────────────────────────────────────────
    readonly property int windowOpenDuration: 210
    readonly property int windowCloseDuration: 175
    readonly property int railDuration: 700
    readonly property int panelDuration: 210
    readonly property real initialScale: 0.96
    readonly property real initialYOffset: -8
    readonly property real shadowBlur: 0.72
    readonly property real shadowVerticalOffset: 7
    readonly property var windowEnterCurve: [0.05, 0.7, 0.1, 1.0]
    readonly property var windowExitCurve:  [0.3, 0.0, 0.8, 0.15]
    readonly property var panelCurve:       [0.2, 0.0, 0.0, 1.0]
    readonly property var effectsCurve:     [0.05, 0.7, 0.1, 1.0]
    readonly property var railCurve:        [0.33, 0, 0.67, 1, 1, 1]

    function wallpaperColumnsForWidth(gridWidth) {
        const w = Math.max(0, Number(gridWidth) || 0);
        const pitch = wallpaperMinPreviewWidth + wallpaperGridGap;
        return Math.max(1, Math.min(wallpaperMaxColumns,
            Math.floor((w + wallpaperGridGap) / pitch)));
    }
}
