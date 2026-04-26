// Custom slider — animates fill on external value changes; drag updates are
// immediate so the knob tracks the cursor without lag.

import QtQuick

Item {
    id: root
    property real value: 0.0
    property real minimum: 0.0
    property real maximum: 1.0
    property bool muted: false
    property bool dragging: false
    signal moved(real value)

    implicitHeight: 28

    readonly property real ratio: maximum > minimum
        ? Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum)))
        : 0

    Rectangle {
        id: trough
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 6
        radius: height / 2
        color: Theme.surfaceElev

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.ratio
            radius: parent.radius
            color: root.muted ? Theme.textTertiary : Theme.accent

            Behavior on width {
                enabled: !root.dragging
                NumberAnimation {
                    duration: Theme.durationMed
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        }
    }

    Rectangle {
        id: knob
        width: 16
        height: 16
        radius: width / 2
        color: Theme.foreground
        border.color: root.muted ? Theme.textTertiary : Theme.accent
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter
        x: trough.x + trough.width * root.ratio - width / 2

        scale: mouse.containsMouse || root.dragging ? 1.15 : 1.0
        Behavior on scale {
            NumberAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad }
        }
        Behavior on x {
            enabled: !root.dragging
            NumberAnimation {
                duration: Theme.durationMed
                easing.type: Easing.OutCubic
            }
        }
        Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function commit(mx) {
            const w = trough.width
            if (w <= 0) return
            const r = Math.max(0, Math.min(1, (mx - trough.x) / w))
            const v = root.minimum + r * (root.maximum - root.minimum)
            root.moved(v)
        }

        onPressed: (event) => { root.dragging = true; commit(event.x) }
        onPositionChanged: (event) => { if (pressed) commit(event.x) }
        onReleased: root.dragging = false
    }
}
