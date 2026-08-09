import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

// Reusable log module. Feed it lines (array of strings) or call appendLine()
// to tail a process/file. Auto-scrolls when follow is on, caps at maxLines,
// and colors ERROR/WARN/INFO lines by pattern. Header carries a follow
// toggle and a clear button.
Item {
    id: root

    property string title: "Log"
    property var lines: []
    property int maxLines: 500
    property bool follow: true

    signal cleared()

    implicitHeight: 220

    function classifyLine(text): string {
        if (/error|failed|exception|fatal/i.test(text)) return "error";
        if (/warn|deprecat/i.test(text)) return "warn";
        return "info";
    }

    function appendLine(text: string) {
        const all = root.lines.slice();
        all.push(text);
        if (all.length > root.maxLines) all.splice(0, all.length - root.maxLines);
        root.lines = all;
    }

    function clear() {
        root.lines = [];
        root.cleared();
    }

    onLinesChanged: {
        logModel.clear();
        for (let i = 0; i < root.lines.length; i++) {
            logModel.append({ text: root.lines[i], level: root.classifyLine(root.lines[i]) });
        }
        if (root.follow) Qt.callLater(() => list.positionViewAtEnd());
    }

    ListModel {
        id: logModel
        dynamicRoles: true
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 38
            radius: Theme.radiusControl
            color: Theme.surfaceDeep
            border.color: Theme.border
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                elide: Text.ElideRight
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Follow toggle (compact pill)
                Rectangle {
                    width: followText.width + 26
                    height: 24
                    radius: 12
                    color: followArea.containsMouse ? Theme.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    Text {
                        id: followText
                        anchors.centerIn: parent
                        text: root.follow ? "Follow ON" : "Follow OFF"
                        color: root.follow ? Theme.accent : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: followArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.follow = !root.follow
                    }
                }

                // Clear button (compact pill)
                Rectangle {
                    width: clearText.width + 26
                    height: 24
                    radius: 12
                    color: clearArea.containsMouse ? Theme.surfaceHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clear()
                    }
                }
            }
        }

        // ── Log body ──────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: parent.height - 38
            radius: Theme.radiusControl
            color: Theme.surfaceDeep
            border.color: Theme.border
            border.width: 1

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 1
                model: logModel
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Text {
                    width: list.width - 12
                    x: 10
                    height: 18
                    verticalAlignment: Text.AlignVCenter
                    text: model.text
                    color: model.level === "error" ? Theme.color1
                         : model.level === "warn"  ? Theme.color3
                         : Theme.textSecondary
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }
    }
}
