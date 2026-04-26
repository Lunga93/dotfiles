// Top bar — three floating pills (left/center/right) per screen.

import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true

    margins.top:    Theme.barMarginTop
    margins.left:   Theme.barMarginSide
    margins.right:  Theme.barMarginSide

    implicitHeight: Theme.barHeight
    color: "transparent"

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.barHeight + Theme.barMarginTop

    Item {
        anchors.fill: parent

        BarPill {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            hPadding: 8

            WorkspacesSegment {
                Layout.alignment: Qt.AlignVCenter
                output: bar.screen.name
            }
        }

        BarPill {
            id: centerPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            hPadding: 8
            visible: taskbar.implicitWidth > 32

            TaskbarSegment {
                id: taskbar
                Layout.alignment: Qt.AlignVCenter
                output: bar.screen.name
            }
        }

        BarPill {
            id: rightPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            hPadding: 8

            ClipboardButton    { Layout.alignment: Qt.AlignVCenter }
            TraySegment        { Layout.alignment: Qt.AlignVCenter }
            BluetoothSegment   { Layout.alignment: Qt.AlignVCenter }
            VolumeSegment      { Layout.alignment: Qt.AlignVCenter }
            ClockSegment       { Layout.alignment: Qt.AlignVCenter }
            PowerButton        { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
