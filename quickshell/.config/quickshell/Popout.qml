// Base popout: fullscreen scrim that captures click-away to dismiss, hosting
// a Card anchored to the top-right (under the bar). Concrete popouts add
// content as default children; Card swallows in-card clicks so they don't
// reach the scrim.

import QtQuick
import Quickshell

PanelWindow {
    id: popout
    default property alias contentChildren: card.contentChildren
    property int padding: 16
    property int cardWidth: 300
    property int rightOffset: Theme.barMarginSide
    property int topOffset:   Theme.barMarginTop + Theme.barHeight + 6

    visible: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true

    MouseArea {
        anchors.fill: parent
        onClicked: popout.visible = false
    }

    Card {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin:   popout.topOffset
        anchors.rightMargin: popout.rightOffset
        padding: popout.padding
        implicitWidth: popout.cardWidth

        opacity: popout.visible ? 1.0 : 0.0
        transform: Scale {
            origin.x: card.width
            origin.y: 0
            xScale: popout.visible ? 1.0 : 0.96
            yScale: popout.visible ? 1.0 : 0.96
            Behavior on xScale { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
    }
}
