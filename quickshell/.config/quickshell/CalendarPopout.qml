// Floating month-grid calendar.

import QtQuick
import QtQuick.Layouts
import Quickshell

Popout {
    id: popout
    cardWidth: 280
    padding: 16
    rightOffset: Theme.barMarginSide + 130

    SystemClock { id: clock; precision: SystemClock.Minutes }

    property date viewDate: clock.date

    function shiftMonth(delta: int): void {
        const d = new Date(viewDate);
        d.setMonth(d.getMonth() + delta);
        viewDate = d;
    }

    function resetView(): void {
        viewDate = clock.date;
    }

    ColumnLayout {
        width: 248
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            IconButton {
                icon: "󰅁"
                diameter: 28
                onClicked: popout.shiftMonth(-1)
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 28

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(popout.viewDate, "MMMM yyyy")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popout.resetView()
                }
            }

            IconButton {
                icon: "󰅂"
                diameter: 28
                onClicked: popout.shiftMonth(1)
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 0
            rowSpacing: 4

            Repeater {
                model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                Text {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    text: modelData
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Repeater {
                model: 42
                Item {
                    id: cell
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    readonly property var first: new Date(popout.viewDate.getFullYear(), popout.viewDate.getMonth(), 1)
                    readonly property int firstDow: (first.getDay() + 6) % 7
                    readonly property int day: cell.index - firstDow + 1
                    readonly property int monthDays: new Date(popout.viewDate.getFullYear(), popout.viewDate.getMonth() + 1, 0).getDate()
                    readonly property bool inMonth: day >= 1 && day <= monthDays
                    readonly property bool isToday: inMonth
                        && day === clock.date.getDate()
                        && popout.viewDate.getMonth() === clock.date.getMonth()
                        && popout.viewDate.getFullYear() === clock.date.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: cell.isToday
                            ? Theme.accent
                            : (mouse.containsMouse && cell.inMonth ? Theme.surfaceHover : "transparent")
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: cell.inMonth
                        text: cell.day + ""
                        color: cell.isToday
                            ? Theme.background
                            : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: cell.inMonth
                        cursorShape: cell.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }
        }
    }
}
