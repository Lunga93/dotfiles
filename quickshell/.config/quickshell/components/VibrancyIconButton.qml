// Icon-only bar button for the Vibrancy preset. Glyph tints accent on hover.
// Adds a soft glow halo around the glyph, intensity-controlled by
// SettingsStore.data.top_bar.vibrancy.text_glow.

import QtQuick
import QtQuick.Effects
import "../"

Item {
    id: root
    property string icon: ""
    property color tint: Theme.textPrimary
    property color tintActive: Theme.accent
    property bool active: false
    property string tooltip: ""
    property int fontSize: Theme.barIconSize + 2

    property real   glow:       SettingsStore.topBarTextGlow
    property string fontFamily: SettingsStore.topBarFontFamily

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int direction)

    implicitHeight: Theme.barHeight
    implicitWidth: implicitHeight

    Text {
        id: glowLayer
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.tintActive
             : mouse.containsMouse || mouse.pressed ? root.tintActive
             : root.tint
        font.pixelSize: root.fontSize
        font.family: Theme.fontMono
        opacity: root.glow * 0.7
        visible: root.glow > 0
        layer.enabled: root.glow > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 0.4 * root.glow
            blurMax: 16
        }
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.tintActive
             : mouse.containsMouse || mouse.pressed ? root.tintActive
             : root.tint
        font.pixelSize: root.fontSize
        font.family: Theme.fontMono
        renderType: Text.NativeRendering
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (e) => {
            if (e.button === Qt.RightButton) root.rightClicked();
            else if (e.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
        onWheel: (w) => root.scrolled(w.angleDelta.y > 0 ? 1 : -1)
    }
}
