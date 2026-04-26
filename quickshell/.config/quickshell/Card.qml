// Rounded surface with shadow. Sizes to fit its children. The internal
// catcher MouseArea swallows any click that doesn't hit an interactive child,
// so a parent click-away handler (Popout's scrim) doesn't fire on the card.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    default property alias contentChildren: content.data
    property alias contentItem: content
    property int padding: 16

    implicitWidth:  content.implicitWidth  + padding * 2
    implicitHeight: content.implicitHeight + padding * 2

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Theme.radiusCard
        border.color: Theme.border
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowVerticalOffset: 16
            shadowOpacity: 0.45
            shadowColor: "#000000"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    }

    Item {
        id: content
        x: root.padding
        y: root.padding
        width:  root.width - root.padding * 2
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height
    }
}
