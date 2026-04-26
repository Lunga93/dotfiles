// Niri workspaces filtered to this output. Click to switch.
// Active = full-opacity number with accent underline anchored to bar bottom.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string output: ""
    property var workspaces: []

    readonly property var visible_ws: workspaces
        .filter(w => w.output === root.output)
        .sort((a, b) => a.idx - b.idx)

    implicitHeight: Theme.barHeight
    implicitWidth:  row.implicitWidth + 4

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const evt = JSON.parse(line);
                    if (evt.WorkspacesChanged) {
                        root.workspaces = evt.WorkspacesChanged.workspaces;
                    } else if (evt.WorkspaceActivated) {
                        const id = evt.WorkspaceActivated.id;
                        const target = root.workspaces.find(x => x.id === id);
                        if (target) {
                            root.workspaces = root.workspaces.map(w =>
                                w.output === target.output
                                    ? Object.assign({}, w, { is_active: w.id === id })
                                    : w);
                        }
                    }
                } catch (e) {}
            }
        }
        onRunningChanged: if (!running) running = true
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: ScriptModel { values: root.visible_ws }

            Item {
                id: ws
                required property var modelData
                Layout.preferredWidth: 28
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5
                    radius: Theme.radiusControl - 2
                    color: mouse.pressed
                        ? Theme.surfacePressed
                        : (mouse.containsMouse ? Theme.surfaceHover : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                Text {
                    anchors.centerIn: parent
                    text: ws.modelData.idx + ""
                    color: ws.modelData.is_active ? Theme.textPrimary : Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.barFontSize
                    font.weight: ws.modelData.is_active ? Font.DemiBold : Font.Medium
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                }

                Indicator {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: ws.modelData.is_active
                    activeWidth: 14
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: switchProc.startDetached()
                    Process {
                        id: switchProc
                        command: ["niri", "msg", "action", "focus-workspace", ws.modelData.id + ""]
                    }
                }
            }
        }
    }
}
