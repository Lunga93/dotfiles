// Top Bar settings page. Tunes the translucent bar via background opacity,
// text glow, and typography. Bindings read from top-level SettingsStore.topBar*
// properties so changes propagate live; writes go through SettingsStore.set.

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

Item {
    id: root

    // ─── Helpers ────────────────────────────────────────────────────────
    readonly property var fontFamilyOptions: ["Inter", "SF Pro", "Geist", "Manrope", "Noto Sans Mono"]
    readonly property var fontWeightKeys: ["light", "regular", "medium"]
    readonly property var fontWeightLabels: ["Light", "Regular", "Medium"]

    readonly property var indexOf: (arr, value) => {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] === value) return i;
        }
        return 0;
    }

    readonly property var fontInstalled: (name) => {
        if (!name) return false;
        const fams = Qt.fontFamilies();
        for (let i = 0; i < fams.length; i++) {
            if (fams[i] === name || fams[i].toLowerCase() === name.toLowerCase()) return true;
        }
        return false;
    }

    readonly property var installHintFor: (name) => {
        switch (name) {
            case "Inter":   return "(install with `pacman -S inter-font`)";
            case "SF Pro":  return "(install via AUR: `yay -S otf-san-francisco`)";
            case "Geist":   return "(install via AUR: `yay -S ttf-geist`)";
            case "Manrope": return "(install with `pacman -S ttf-manrope`)";
            default:        return "(font not installed)";
        }
    }


    // ─── Layout ─────────────────────────────────────────────────────────
    Flickable {
        id: scroller
        anchors.fill: parent
        contentHeight: column.height + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 4500

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        Column {
            id: column
            width: parent.width
            spacing: 0

            // Header
            Item {
                width: parent.width
                height: 72
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "Top Bar"
                        color: Theme.textHeader
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Translucent bar tuning. Changes apply live."
                        color: Theme.textSubtitle
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            // Body
            Column {
                x: 28
                width: parent.width - 56
                spacing: 16
                bottomPadding: 32

                // Live preview
                Rectangle {
                    width: parent.width
                    height: 120
                    radius: Theme.radiusCard
                    color: Theme.surfaceDeep
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    TopBarPreview { anchors.fill: parent }
                }

                // Surface
                SettingsGroup {
                    header: "SURFACE"

                    SettingsRow {
                        title: "Background opacity"
                        description: "Bar tint strength. Lower lets more wallpaper show through."

                        SettingsSlider {
                            width: 240
                            from: 0.10
                            to: 0.60
                            value: SettingsStore.topBarBgOpacity
                            onValueChangedByUser: function(v) {
                                SettingsStore.set("top_bar", "background_opacity", v);
                            }
                        }
                    }

                    Divider {}

                    SettingsRow {
                        title: "Text glow"
                        description: "Soft halo behind bar text and icons."

                        SettingsSlider {
                            width: 240
                            from: 0.0
                            to: 1.0
                            value: SettingsStore.topBarTextGlow
                            onValueChangedByUser: function(v) {
                                SettingsStore.set("top_bar", "text_glow", v);
                            }
                        }
                    }
                }

                // Typography
                SettingsGroup {
                    header: "TYPOGRAPHY"

                    SettingsRow {
                        title: "Font family"
                        description: "Used for all bar text. Falls back silently if not installed."
                        hint: root.fontInstalled(SettingsStore.topBarFontFamily)
                            ? ""
                            : root.installHintFor(SettingsStore.topBarFontFamily)

                        PillSelector {
                            options: root.fontFamilyOptions
                            currentIndex: root.indexOf(root.fontFamilyOptions, SettingsStore.topBarFontFamily)
                            onSelected: function(index) {
                                SettingsStore.set("top_bar", "font_family", root.fontFamilyOptions[index]);
                            }
                        }
                    }

                    Divider {}

                    SettingsRow {
                        title: "Weight"
                        description: "Stroke weight for bar text."

                        PillSelector {
                            options: root.fontWeightLabels
                            currentIndex: root.indexOf(root.fontWeightKeys, SettingsStore.topBarFontWeight)
                            onSelected: function(index) {
                                SettingsStore.set("top_bar", "font_weight", root.fontWeightKeys[index]);
                            }
                        }
                    }
                }
            }
        }
    }

    // Custom thumb-only scrollbar
    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Theme.border
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
