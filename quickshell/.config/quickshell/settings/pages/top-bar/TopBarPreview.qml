import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

// Self-contained preview of the bar. Does NOT load Bar.qml; instead, renders a
// mock approximation — workspace dots, a centered window title, clock + power
// — using the live top_bar settings. Updates automatically because the
// SettingsStore.topBar* properties re-evaluate when the settings file changes
// (they depend on SettingsStore._revision, bumped by load/set).
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

    readonly property real bgOpacity: SettingsStore.topBarBgOpacity
    readonly property real textGlow:  SettingsStore.topBarTextGlow

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
        color: Theme.surfaceDeep
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

        // ─── Mock content ──────────────────────────────────────────────

        // Helper component: a glowable text. The "glow" is drawn as a stacked
        // duplicate text rendered behind in a near-white halo, with opacity
        // proportional to textGlow. Cheap and decoupled from MultiEffect.
        component GlowText: Item {
            id: gt
            property string text: ""
            property int pixelSize: 13
            property color color: Theme.textHeader
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
                color: Theme.textHeader
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
            color: Theme.textHeader
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
                color: Theme.textHeader
            }
            GlowText {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏻"
                pixelSize: 14
                color: Theme.textHeader
            }
        }
    }
}
