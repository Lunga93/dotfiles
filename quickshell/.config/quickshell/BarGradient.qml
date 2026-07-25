// Windshield-style top-down hue gradient overlay for the Vibrancy bar.
// Sits between the translucent background and the foreground content.
// Reads style + intensity from SettingsStore so it reacts live to slider
// changes and pywal palette swaps (Theme.primary / Theme.secondary).
//
// Implementation: instead of an OpacityMask, each layer is just a Rectangle
// with a vertical Gradient whose first stop carries the hue + max alpha and
// last stop is transparent. For `cabin`, two such layers are anchored to the
// left and right halves and blended with a soft horizontal falloff (each
// layer is full-width but a horizontal opacity ramp is applied via a second
// gradient channel — easier and lighter than QtGraphicalEffects).

import QtQuick

Item {
    id: root
    anchors.fill: parent

    // ---- inputs (reactive to SettingsStore top-level props) ----
    property string style:    SettingsStore.topBarGradientStyle
    property real   intensity: SettingsStore.topBarGradientIntensity

    // ---- helpers ----
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    // Per-style max alpha, multiplied by user intensity (0-1). See spec.
    readonly property real maxLuminance: 0.07
    readonly property real maxSingleHue: 0.09
    readonly property real maxCabin:     0.06

    readonly property bool isOff:       root.style === "off"
    readonly property bool isLuminance: root.style === "luminance"
    readonly property bool isSingleHue: root.style === "single_hue"
    readonly property bool isCabin:     root.style === "cabin" || (!isOff && !isLuminance && !isSingleHue)

    // Top-down "luminance" — pure white fade.
    Rectangle {
        anchors.fill: parent
        visible: root.isLuminance && root.intensity > 0
        opacity: root.isLuminance ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMed } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.tint(Qt.rgba(1, 1, 1, 1), root.maxLuminance * root.intensity) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
        }
    }

    // Top-down single-hue — Theme.primary fade.
    Rectangle {
        anchors.fill: parent
        visible: root.isSingleHue && root.intensity > 0
        opacity: root.isSingleHue ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMed } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.tint(Theme.primary, root.maxSingleHue * root.intensity) }
            GradientStop { position: 1.0; color: root.tint(Theme.primary, 0) }
        }
    }

    // Cabin — primary on the left half, secondary on the right half, both
    // fading top-down. Each layer occupies its half so the two hues meet at
    // the center. A small overlap (4 px) softens the seam visually.
    Item {
        anchors.fill: parent
        visible: root.isCabin && root.intensity > 0
        opacity: root.isCabin ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.durationMed } }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width / 2 + 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.tint(Theme.primary, root.maxCabin * root.intensity) }
                GradientStop { position: 1.0; color: root.tint(Theme.primary, 0) }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: parent.width / 2 + 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.tint(Theme.secondary, root.maxCabin * root.intensity) }
                GradientStop { position: 1.0; color: root.tint(Theme.secondary, 0) }
            }
        }
    }
}
