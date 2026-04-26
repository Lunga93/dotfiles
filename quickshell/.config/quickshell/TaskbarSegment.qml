// Window list filtered to this output. Click activates, middle-click closes.
// Active window gets the accent indicator.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root
    property string output: ""

    implicitHeight: Theme.barHeight
    implicitWidth:  Math.max(row.implicitWidth + 4, 32)

    // Niri reports appIds without distro suffixes (e.g. "jetbrains-webstorm")
    // but desktop files are usually "jetbrains-webstorm-<uuid>.desktop". Try
    // exact match first, then prefix scan.
    function resolveIcon(appId: string): string {
        if (!appId) return "image-missing";
        const direct = DesktopEntries.byId(appId)
                     || DesktopEntries.byId(appId.toLowerCase());
        if (direct) return Quickshell.iconPath(direct.icon, "image-missing");

        const needle = appId.toLowerCase();
        for (const e of DesktopEntries.applications.values) {
            const id = (e.id || "").toLowerCase();
            if (id.startsWith(needle) || id.includes(needle)) {
                return Quickshell.iconPath(e.icon, "image-missing");
            }
        }
        return Quickshell.iconPath(appId, "image-missing");
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: {
                    const all = ToplevelManager.toplevels.values;
                    if (!root.output) return all;
                    return all.filter(t => t.screens && t.screens.some(s => s && s.name === root.output));
                }
            }

            Item {
                id: tile
                required property var modelData
                Layout.preferredWidth: 34
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    radius: Theme.radiusControl - 2
                    color: mouse.pressed
                        ? Theme.surfacePressed
                        : (mouse.containsMouse
                            ? Theme.surfaceHover
                            : (tile.modelData && tile.modelData.activated ? Theme.surfaceElev : "transparent"))
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Theme.barIconSize + 5
                    height: Theme.barIconSize + 5
                    source: tile.modelData ? root.resolveIcon(tile.modelData.appId) : ""
                    smooth: true
                    asynchronous: true
                }

                Indicator {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: tile.modelData && tile.modelData.activated
                    activeWidth: 18
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: (e) => {
                        if (!tile.modelData) return;
                        if (e.button === Qt.MiddleButton) tile.modelData.close();
                        else tile.modelData.activate();
                    }
                }
            }
        }
    }
}
