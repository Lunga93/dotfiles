// Text with a soft glow halo. Used by the Vibrancy bar for any chrome text
// not already styled by an existing segment. The visible glyph is rendered
// natively for crisp subpixel hinting; a duplicated underlay is blurred via
// MultiEffect to produce the halo. Glow strength + font family are read
// from SettingsStore so live setting changes take effect with no restart.

import QtQuick
import QtQuick.Effects
import "../"

Item {
    id: root

    // Public API — mirrors BarText defaults so this is a near drop-in.
    property string text: ""
    property color color: Theme.textPrimary
    property int pixelSize: Theme.barFontSize
    property int    weight: weightOf(SettingsStore.topBarFontWeight)
    property real   glow:   SettingsStore.topBarTextGlow
    property string family: SettingsStore.topBarFontFamily

    readonly property string effectiveFamily: {
        if (family === "") return Theme.fontFamily;
        const fams = Qt.fontFamilies();
        for (let i = 0; i < fams.length; i++) {
            if (fams[i] === family || fams[i].toLowerCase() === family.toLowerCase()) return family;
        }
        return Theme.fontFamily;
    }

    implicitWidth:  visibleText.implicitWidth
    implicitHeight: visibleText.implicitHeight

    readonly property var weightOf: (s) => {
        switch (s) {
            case "regular": return Font.Normal;
            case "medium":  return Font.Medium;
            case "light":
            default:        return Font.Normal;
        }
    }

    // Glow underlay — duplicated text, blurred via MultiEffect. Disabled
    // entirely when glow is 0 so we don't pay the offscreen layer cost.
    // White halo regardless of text color (matches TopBarPreview).
    Text {
        id: glowLayer
        anchors.fill: parent
        text: root.text
        color: Qt.rgba(1, 1, 1, 1)
        font.family: root.effectiveFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        verticalAlignment: Text.AlignVCenter
        opacity: root.glow * 0.7
        visible: root.glow > 0
        layer.enabled: root.glow > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.4 * root.glow
            blurMax: 16
        }
    }

    // Visible glyph — native-rendered for sharpness.
    Text {
        id: visibleText
        text: root.text
        color: root.color
        font.family: root.effectiveFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
