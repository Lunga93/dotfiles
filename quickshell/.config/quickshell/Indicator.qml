// Reusable active-state indicator. iOS-style pill with soft accent glow.
// Animates width from 0 → on; opacity dims when inactive.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    property bool active: false
    property color color: Theme.accent
    property int activeWidth: 18
    property int barHeight: 3

    implicitHeight: barHeight + 4
    implicitWidth: activeWidth

    Rectangle {
        id: pill
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.barHeight
        width: root.active ? root.activeWidth : 4
        radius: height / 2
        color: root.color
        opacity: root.active ? 1.0 : 0.0

        Behavior on width {
            NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast }
        }

        layer.enabled: root.active
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.8
            shadowVerticalOffset: 0
            shadowOpacity: 0.65
            shadowColor: root.color
        }
    }
}
