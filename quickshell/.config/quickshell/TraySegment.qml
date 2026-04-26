// StatusNotifierItem tray. Empty when there are no items.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root
    visible: SystemTray.items.values.length > 0
    implicitHeight: Theme.barHeight
    implicitWidth:  row.implicitWidth + (visible ? 4 : 0)

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: SystemTray.items

            Item {
                id: item
                required property SystemTrayItem modelData
                Layout.preferredWidth: Theme.barHeight - 8
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: width / 2
                    color: mouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Theme.barIconSize
                    height: Theme.barIconSize
                    source: item.modelData ? item.modelData.icon : ""
                    smooth: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (e) => {
                        if (e.button === Qt.RightButton && item.modelData.hasMenu) {
                            menuAnchor.open();
                        } else {
                            item.modelData.activate();
                        }
                    }
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: item.modelData ? item.modelData.menu : null
                    anchor.window: root.QsWindow.window
                    anchor.rect.x: parent.x
                    anchor.rect.y: parent.y + parent.height
                }
            }
        }
    }
}
