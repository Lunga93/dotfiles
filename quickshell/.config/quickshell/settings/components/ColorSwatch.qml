import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Item {
    id: root
    property color swatchColor: Theme.accent
    property bool selected: false
    // When false the swatch is rendered dim, the cursor stays default and
    // clicks are swallowed. Used by the dynamic-mode picker to display the
    // auto-derived selection without letting the user override it.
    property bool interactive: true
    property int swatchSize: 36
    readonly property int dotSize: Math.round(swatchSize * 0.72)
    signal clicked

    width: swatchSize
    height: swatchSize

    Rectangle {
        id: ring
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: Theme.foreground
        border.width: 2
        opacity: root.selected ? (root.interactive ? 1.0 : 0.65) : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Rectangle {
        id: dot
        anchors.centerIn: parent
        width: root.dotSize
        height: root.dotSize
        radius: width / 2
        color: root.swatchColor
        opacity: root.interactive ? 1.0 : 0.55
        border.color: Qt.rgba(0, 0, 0, 0.3)
        border.width: 1

        scale: root.interactive
            ? (swatchArea.pressed ? 0.85 : (swatchArea.containsMouse ? 1.1 : 1.0))
            : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 3
            width: parent.width * 0.55
            height: parent.height * 0.35
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.25)
        }

        MouseArea {
            id: swatchArea
            anchors.fill: parent
            hoverEnabled: root.interactive
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (root.interactive) root.clicked()
        }
    }
}
