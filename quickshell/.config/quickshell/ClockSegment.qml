// "Mon 28 13:42" — clicks toggle the calendar popout directly.
// Text tints secondary on hover.

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

    BarText {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd HH:mm")
        color: mouse.pressed ? Theme.secondaryMuted
             : mouse.containsMouse ? Theme.secondary
             : Theme.textPrimary
        font.weight: Font.DemiBold
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (e) => {
            if (e.button === Qt.RightButton) Globals.toggle(Globals.calendarPopout);
            else Globals.toggle(Globals.calendarPopout);
        }
    }
}
