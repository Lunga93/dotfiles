// Top Bar settings page. Tunes the single translucent edge-to-edge bar via
// gradient style + intensity, background opacity, text glow, and typography.
// Bindings read from top-level SettingsStore.topBar* properties so changes
// propagate live; writes go through SettingsStore.set("top_bar", k, v).

import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

Item {
    id: root

    // ─── Helpers ────────────────────────────────────────────────────────
    readonly property var gradientStyleKeys: ["off", "luminance", "single_hue", "cabin"]
    readonly property var gradientStyleLabels: ["Off", "Luminance", "Single hue", "Cabin"]

    readonly property var fontFamilyOptions: ["Inter", "SF Pro", "Geist", "Manrope", "Noto Sans Mono"]
    readonly property var fontWeightKeys: ["light", "regular", "medium"]
    readonly property var fontWeightLabels: ["Light", "Regular", "Medium"]

    function indexOf(arr, value) {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] === value) return i;
        }
        return 0;
    }

    function fontInstalled(name) {
        if (!name) return false;
        const fams = Qt.fontFamilies();
        for (let i = 0; i < fams.length; i++) {
            if (fams[i] === name || fams[i].toLowerCase() === name.toLowerCase()) return true;
        }
        return false;
    }

    function installHintFor(name) {
        switch (name) {
            case "Inter":   return "(install with `pacman -S inter-font`)";
            case "SF Pro":  return "(install via AUR: `yay -S otf-san-francisco`)";
            case "Geist":   return "(install via AUR: `yay -S ttf-geist`)";
            case "Manrope": return "(install with `pacman -S ttf-manrope`)";
            default:        return "(font not installed)";
        }
    }

    // ─── Inline group container ─────────────────────────────────────────
    component GroupShell: Column {
        id: gs
        property string header: ""
        default property alias content: inner.data

        width: parent.width

        Text {
            text: gs.header
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            font.letterSpacing: 0.6
            textFormat: Text.PlainText
            leftPadding: 16
            rightPadding: 16
            topPadding: 12
            bottomPadding: 8
            visible: gs.header !== ""
        }

        Rectangle {
            width: parent.width
            height: inner.height
            radius: Theme.radiusCard
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1
            clip: true

            Column {
                id: inner
                width: parent.width
            }
        }
    }

    component Divider: Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.04)
    }

    // ─── Inline visual Slider ───────────────────────────────────────────
    component VSlider: Item {
        id: slider
        property real from: 0.0
        property real to: 1.0
        property real value: 0.0
        signal valueChangedByUser(real value)

        implicitHeight: 24

        readonly property real fraction: (slider.to - slider.from) > 0
            ? Math.max(0, Math.min(1, (slider.value - slider.from) / (slider.to - slider.from)))
            : 0

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: pctLabel.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.surfaceElev

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * slider.fraction
                radius: 2
                color: Theme.primary
                Behavior on width { NumberAnimation { duration: Theme.durationFast } }
            }

            Rectangle {
                width: 14; height: 14; radius: 7
                color: "#f5ede0"
                border.color: Qt.rgba(0, 0, 0, 0.35); border.width: 1
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(parent.width - width,
                    parent.width * slider.fraction - width / 2))
                Behavior on x { NumberAnimation { duration: Theme.durationFast } }

                Rectangle {
                    anchors.fill: parent; anchors.margins: -1
                    radius: parent.radius + 1
                    color: "transparent"
                    border.color: Qt.rgba(0, 0, 0, 0.18); border.width: 1
                    z: -1
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateFromX(mx) {
                    const w = track.width;
                    if (w <= 0) return;
                    const f = Math.max(0, Math.min(1, mx / w));
                    const v = slider.from + f * (slider.to - slider.from);
                    if (v !== slider.value) {
                        slider.value = v;
                        slider.valueChangedByUser(v);
                    }
                }

                onPressed: function(mouse) { updateFromX(mouse.x); }
                onPositionChanged: function(mouse) {
                    if (pressed) updateFromX(mouse.x);
                }
            }
        }

        Text {
            id: pctLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            horizontalAlignment: Text.AlignRight
            text: Math.round(slider.fraction * 100) + "%"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }

    // ─── Inline labelled row ────────────────────────────────────────────
    component LabelRow: Item {
        id: lr
        property string title: ""
        property string description: ""
        property string hint: ""
        default property alias control: controlSlot.data

        width: parent.width
        height: Math.max(56, textCol.height + 24)

        Column {
            id: textCol
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: controlSlot.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: lr.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                text: lr.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                visible: lr.description !== ""
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: lr.hint
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.italic: true
                visible: lr.hint !== ""
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: controlSlot
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
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
                        color: "#f5ede0"
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "Translucent bar tuning. Changes apply live."
                        color: "#8a8175"
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
                    color: "#0f0b07"
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    TopBarPreview { anchors.fill: parent }
                }

                // Gradient
                GroupShell {
                    header: "GRADIENT"

                    LabelRow {
                        title: "Style"
                        description: "Top-down ambient tint, like the band on a car windshield."

                        PillSelector {
                            options: root.gradientStyleLabels
                            currentIndex: root.indexOf(root.gradientStyleKeys, SettingsStore.topBarGradientStyle)
                            onSelected: function(index) {
                                SettingsStore.set("top_bar", "gradient_style", root.gradientStyleKeys[index]);
                            }
                        }
                    }

                    Divider {}

                    LabelRow {
                        title: "Intensity"
                        description: "How strongly the gradient tints the top edge."

                        VSlider {
                            width: 240
                            from: 0.0
                            to: 1.0
                            value: SettingsStore.topBarGradientIntensity
                            onValueChangedByUser: function(v) {
                                SettingsStore.set("top_bar", "gradient_intensity", v);
                            }
                        }
                    }
                }

                // Surface
                GroupShell {
                    header: "SURFACE"

                    LabelRow {
                        title: "Background opacity"
                        description: "Bar tint strength. Lower lets more wallpaper show through."

                        VSlider {
                            width: 240
                            from: 0.10
                            to: 0.60
                            value: SettingsStore.topBarBgOpacity
                            onValueChangedByUser: function(v) {
                                SettingsStore.set("top_bar", "bg_opacity", v);
                            }
                        }
                    }

                    Divider {}

                    LabelRow {
                        title: "Text glow"
                        description: "Soft halo behind bar text and icons."

                        VSlider {
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
                GroupShell {
                    header: "TYPOGRAPHY"

                    LabelRow {
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

                    LabelRow {
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
            color: Qt.rgba(1, 1, 1, 0.15)
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0 ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
