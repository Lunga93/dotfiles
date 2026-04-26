// Icon-only button used inside bar pills. Hover + active states.

import QtQuick

Item {
    id: root
    property string icon: ""
    property color tint: Theme.textPrimary
    property color tintActive: Theme.accent
    property bool active: false
    property string tooltip: ""
    property int fontSize: Theme.barIconSize + 2
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int direction)

    implicitHeight: Theme.barHeight
    implicitWidth: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.radiusControl - 2
        color: mouse.pressed
            ? Theme.surfacePressed
            : (mouse.containsMouse ? Theme.surfaceHover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? root.tintActive : root.tint
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
