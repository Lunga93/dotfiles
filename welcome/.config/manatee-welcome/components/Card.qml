import QtQuick
import QtQuick.Effects
import ".."

Item {
    id: root
    default property alias contentChildren: content.data
    property alias contentItem: content
    property int padding: 16
    property int radius: Theme.radiusCard

    implicitWidth:  content.implicitWidth  + padding * 2
    implicitHeight: content.implicitHeight + padding * 2

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: root.radius
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

    Item {
        id: content
        x: root.padding
        y: root.padding
        width:  root.width  - root.padding * 2
        height: root.height - root.padding * 2
        implicitWidth:  childrenRect.width
        implicitHeight: childrenRect.height
    }
}
