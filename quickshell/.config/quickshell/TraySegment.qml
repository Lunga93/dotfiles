// StatusNotifierItem tray. Shows running app indicators.
// Left-click activates, right-click opens context menu with
// activate() fallback when no menu is provided.

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

                readonly property bool hasMenu: item.modelData && item.modelData.menu !== null

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: width / 2
                    color: {
                        if (mouse.pressed) return Theme.surfacePressed;
                        if (mouse.containsMouse) return Theme.surfaceHover;
                        return "transparent";
                    }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Theme.barIconSize
                    height: Theme.barIconSize
                    source: item.modelData ? item.modelData.icon || "" : ""
                    smooth: true
                    asynchronous: true
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: (e) => {
                        if (!item.modelData) return;

                        if (e.button === Qt.RightButton) {
                            const menu = item.modelData.menu;
                            if (menu) {
                                const globalPos = item.mapToItem(null, 0, item.height);
                                menuAnchor.anchor.rect = Qt.rect(
                                    globalPos ? globalPos.x : 0,
                                    globalPos ? globalPos.y : 0,
                                    1, 1
                                );
                                menuAnchor.menu = menu;
                                menuAnchor.open();
                            } else {
                                item.modelData.activate();
                            }
                        } else {
                            item.modelData.activate();
                        }
                    }
                }

                QsMenuAnchor {
                    id: menuAnchor
                    anchor.window: root.QsWindow.window
                }
            }
        }
    }
}
