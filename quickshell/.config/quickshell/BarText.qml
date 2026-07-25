// Bar typography element. Reads font family, weight, and text glow
// from SettingsStore. Falls back to Theme values when unset.

import QtQuick

Text {
    id: root
    color: Theme.textPrimary
    font.pixelSize: Theme.barFontSize
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    readonly property string effectiveFamily: SettingsStore.topBarFontFamily || Theme.fontFamily
    readonly property int effectiveWeight: {
        switch (SettingsStore.topBarFontWeight) {
            case "light":   return Font.Light;
            case "regular": return Font.Normal;
            case "medium":  return Font.Medium;
            default:        return Font.Normal;
        }
    }
    readonly property real glowStrength: SettingsStore.topBarTextGlow || 0

    font.family: effectiveFamily
    font.weight: effectiveWeight

    Text {
        anchors.centerIn: parent
        text: root.text
        font.family: root.effectiveFamily
        font.pixelSize: root.font.pixelSize
        font.weight: root.effectiveWeight
        color: root.color
        opacity: root.glowStrength * 0.5
        scale: 1.05
        visible: root.glowStrength > 0
    }
}
