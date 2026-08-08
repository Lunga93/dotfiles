// StatusNotifierItem tray. Shows running app indicators.
// Left-click activates. Right-click shows platform menu via display().
// Requires //@ pragma UseQApplication in shell.qml.

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../"

Item {
    id: root
    readonly property var blocked: ["nm-applet", "nm_applet", "networkmanager"]
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
                Layout.preferredWidth: filtered ? 0 : Theme.barHeight - 8
                Layout.fillHeight: true
                visible: filtered ? false : true

                property color tint: (mouse.containsMouse || mouse.pressed)
                    ? Theme.accent : Theme.textPrimary
                Behavior on tint { ColorAnimation { duration: Theme.durationFast } }

                readonly property bool filtered: {
                    const id = modelData.id || "";
                    return id === "nm-applet" || id.includes("nm_applet") || id.includes("networkmanager");
                }

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: Theme.barIconSize
                    height: Theme.barIconSize
                    source: item.modelData ? item.modelData.icon || "" : ""
                    smooth: true
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: item.tint
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (e) => {
                        if (!item.modelData) return;

                        if (e.button === Qt.RightButton) {
                            if (item.modelData.hasMenu) {
                                const pos = root.QsWindow.mapFromItem(item, mouse.x, mouse.y);
                                item.modelData.display(
                                    root.QsWindow.window,
                                    Math.round(pos.x),
                                    Math.round(pos.y + item.height + 4)
                                );
                            } else {
                                item.modelData.secondaryActivate();
                            }
                        } else if (e.button === Qt.MiddleButton) {
                            item.modelData.secondaryActivate();
                        } else {
                            item.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
