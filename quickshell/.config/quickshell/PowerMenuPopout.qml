// Power menu popout — Lock / Logout / Suspend / Reboot / Shutdown.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Popout {
    id: popout
    cardWidth: 200
    padding: 10

    function dispatch(cmd: var): void {
        runner.command = cmd;
        runner.startDetached();
        popout.visible = false;
    }

    Process { id: runner; command: ["true"] }

    ColumnLayout {
        width: 180
        spacing: 2

        Repeater {
            model: [
                { icon: "󰍁", label: "Lock",     cmd: ["loginctl", "lock-session"], destructive: false },
                { icon: "󰗽", label: "Logout",   cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"], destructive: false },
                { icon: "󰒲", label: "Suspend",  cmd: ["systemctl", "suspend"],     destructive: false },
                { icon: "󰜉", label: "Reboot",   cmd: ["systemctl", "reboot"],      destructive: true  },
                { icon: "󰐥", label: "Shutdown", cmd: ["systemctl", "poweroff"],    destructive: true  }
            ]

            delegate: Item {
                id: rowItem
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl - 2
                    color: mouse.pressed
                        ? (rowItem.modelData.destructive ? Theme.destructive : Theme.accentSoft)
                        : (mouse.containsMouse
                            ? (rowItem.modelData.destructive ? Theme.destructive : Theme.accentSoft)
                            : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: rowItem.modelData.icon
                        color: mouse.containsMouse
                            ? (rowItem.modelData.destructive ? Theme.foreground : Theme.accent)
                            : Theme.textPrimary
                        font.pixelSize: 16
                        font.family: Theme.fontMono
                        renderType: Text.NativeRendering
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: rowItem.modelData.label
                        color: mouse.containsMouse
                            ? (rowItem.modelData.destructive ? Theme.foreground : Theme.accent)
                            : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popout.dispatch(rowItem.modelData.cmd)
                }
            }
        }
    }
}
