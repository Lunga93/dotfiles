import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

// Self-contained preview of the bar. Does NOT load Bar.qml; instead, renders a
// mock approximation — workspace dots, a centered window title, clock + power
// — using the live `top_bar.vibrancy` settings. Updates automatically because
// every binding chains through SettingsStore.data, whose `set()` rebuilds the
// object reference and emits `changed()`.
Item {
    id: root

    // ─── Settings bindings (top-level singleton props for live updates) ──
    readonly property string fontFamilyChoice: SettingsStore.topBarFontFamily
    readonly property bool fontInstalled: {
        const fams = Qt.fontFamilies();
        for (let i = 0; i < fams.length; i++) {
            if (fams[i] === fontFamilyChoice ||
                fams[i].toLowerCase() === fontFamilyChoice.toLowerCase()) return true;
        }
        return false;
    }
    readonly property string effectiveFont: fontInstalled ? fontFamilyChoice : Theme.fontFamily

    readonly property int effectiveWeight: {
        switch (SettingsStore.topBarFontWeight) {
            case "light":   return Font.Light;
            case "regular": return Font.Normal;
            case "medium":  return Font.Medium;
            default:        return Font.Normal;
        }
    }

    readonly property real bgOpacity:         SettingsStore.topBarBgOpacity
    readonly property real gradientIntensity: SettingsStore.topBarGradientIntensity
    readonly property real textGlow:          SettingsStore.topBarTextGlow
    readonly property string gradientStyle:   SettingsStore.topBarGradientStyle

    // Max alpha caps per gradient style (mirrors BarGradient.qml).
    function maxAlphaFor(style) {
        switch (style) {
            case "luminance":   return 0.07;
            case "single_hue":  return 0.09;
            case "cabin":       return 0.06;
            default:            return 0.0;
        }
    }
    readonly property real effectiveMaxAlpha: maxAlphaFor(gradientStyle) * gradientIntensity

    clip: true

    // ─── Wallpaper backdrop ─────────────────────────────────────────────
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: SettingsStore.currentWallpaper
            ? "file://" + SettingsStore.currentWallpaper + "?v=" + SettingsStore.wallpaperVersion
            : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    // Soft darkening when no wallpaper is available
    Rectangle {
        anchors.fill: parent
        visible: !SettingsStore.currentWallpaper
        color: "#1a1408"
    }

    // ─── Mock bar surface ──────────────────────────────────────────────
    Item {
        id: bar
        // Make the mock bar a slim strip near the top of the preview, like the
        // real edge-to-edge bar. We center it vertically for visual balance.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 38

        // Tinted surface
        Rectangle {
            id: surface
            anchors.fill: parent
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, root.bgOpacity)
        }

        // Gradient overlay — top-down mask, fades from max alpha at top to 0 at bottom.
        // Composed differently per style; "off" simply renders nothing.
        Item {
            id: gradientOverlay
            anchors.fill: parent
            visible: root.gradientStyle !== "off" && root.gradientIntensity > 0
            opacity: 1.0

            // Luminance: white linear, top-down
            Rectangle {
                anchors.fill: parent
                visible: root.gradientStyle === "luminance"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.effectiveMaxAlpha) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                }
            }

            // Single hue: primary linear, top-down
            Rectangle {
                anchors.fill: parent
                visible: root.gradientStyle === "single_hue"
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b,
                                       root.effectiveMaxAlpha)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0)
                    }
                }
            }

            // Cabin: primary on the left half + secondary on the right half,
            // each fading top-down. Approximated with two layered rectangles
            // masked by a horizontal split.
            Item {
                anchors.fill: parent
                visible: root.gradientStyle === "cabin"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.6
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b,
                                           root.effectiveMaxAlpha)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0)
                        }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * 0.6
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b,
                                           root.effectiveMaxAlpha)
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0)
                        }
                    }
                }
            }
        }

        // ─── Mock content ──────────────────────────────────────────────

        // Helper component: a glowable text. The "glow" is drawn as a stacked
        // duplicate text rendered behind in a near-white halo, with opacity
        // proportional to textGlow. Cheap and decoupled from MultiEffect.
        component GlowText: Item {
            id: gt
            property string text: ""
            property int pixelSize: 13
            property color color: "#f5ede0"
            implicitWidth: foreground.contentWidth
            implicitHeight: foreground.contentHeight

            // halo
            Text {
                anchors.centerIn: parent
                text: gt.text
                font.family: root.effectiveFont
                font.pixelSize: gt.pixelSize
                font.weight: root.effectiveWeight
                color: Qt.rgba(1, 1, 1, 0.55 * root.textGlow)
                scale: 1.06
                visible: root.textGlow > 0
            }
            Text {
                id: foreground
                anchors.centerIn: parent
                text: gt.text
                font.family: root.effectiveFont
                font.pixelSize: gt.pixelSize
                font.weight: root.effectiveWeight
                color: gt.color
            }
        }

        // Left: workspace dots
        Row {
            id: workspaces
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 8; height: 8; radius: 4
                color: "#f5ede0"
                anchors.verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 6; height: 6; radius: 3
                    color: Qt.rgba(0.96, 0.93, 0.88, 0.45)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Center: window title
        GlowText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "zen-browser"
            pixelSize: 13
            color: "#f5ede0"
        }

        // Right: clock + power icon
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            GlowText {
                anchors.verticalCenter: parent.verticalCenter
                text: "10:48"
                pixelSize: 13
                color: "#f5ede0"
            }
            GlowText {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏻"
                pixelSize: 14
                color: "#f5ede0"
            }
        }
    }
}
