// "Mon 28 13:42" — clicks toggle the calendar popout directly.

import QtQuick
import Quickshell

Item {
    id: root
    implicitHeight: Theme.barHeight
    implicitWidth:  label.implicitWidth + 16

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: Theme.radiusControl - 2
        color: mouse.pressed
            ? Theme.surfacePressed
            : (mouse.containsMouse ? Theme.surfaceHover : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    BarText {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd HH:mm")
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.toggle(Globals.calendarPopout)
    }
}
