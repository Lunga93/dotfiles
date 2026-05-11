import QtQuick
import Quickshell
import Quickshell.Io
import "../../.." // qmldir types

Item {
    id: root

    property string moodFilter: ""
    property var wallpapers: []
    property string applyingPath: ""

    signal wallpaperSelected(string path)

    height: gridHeader.height + gridView.contentHeight + 16

    Process {
        id: scanner
        property bool pending: false

        function scan(): void {
            const libDir = SettingsStore.get("wallpaper", "library_dir") || Quickshell.env("HOME") + "/Pictures/wallpapers";
            command = ["bash", "-c", "find '" + libDir + "' -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \\) 2>/dev/null | sort"];
            root.wallpapers = [];
            running = false;
            running = true;
        }

        running: true
        stdout: SplitParser {
            onRead: (line) => {
                if (line && line.length > 0) {
                    const list = root.wallpapers.slice();
                    list.push(line);
                    root.wallpapers = list;
                }
            }
        }
    }

    readonly property var sourceWallpapers: {
        if (!root.moodFilter) return root.wallpapers;
        return MoodCatalog.wallpapersForMood(root.moodFilter);
    }

    function basename(path: string): string {
        return path.split("/").pop();
    }

    function rescan(): void {
        scanner.scan();
    }

    Column {
        id: gridHeader
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 36

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.moodFilter ? root.moodFilter.charAt(0).toUpperCase() + root.moodFilter.slice(1) + " wallpapers" : "ALL WALLPAPERS"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }

            Text {
                id: countText
                anchors.left: parent.left
                anchors.leftMargin: {
                    const base = root.moodFilter ? root.moodFilter.length * 9 + 130 : 120;
                    return Math.min(base, 250);
                }
                anchors.verticalCenter: parent.verticalCenter
                text: "(" + root.sourceWallpapers.length + ")"
                color: "#5a5249"
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: ["Newest", "Random", "Most used"]
                    delegate: Rectangle {
                        required property string modelData

                        height: 24
                        width: sortText.width + 14
                        radius: 12
                        color: sortArea.containsMouse ? "#2c2519" : "transparent"

                        Text {
                            id: sortText
                            anchors.centerIn: parent
                            text: modelData
                            color: "#a89e8e"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: sortArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { }
                        }
                    }
                }
            }
        }
    }

    GridView {
        id: gridView
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: contentHeight
        cellWidth: 168
        cellHeight: 110
        leftMargin: 12
        rightMargin: 12
        topMargin: 4
        interactive: false

        model: root.sourceWallpapers

        delegate: Item {
            required property string modelData
            required property int index

            width: gridView.cellWidth
            height: gridView.cellHeight

            readonly property bool isCurrent: modelData === SettingsStore.currentWallpaper
            readonly property bool isApplying: modelData === root.applyingPath

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 156
                height: 96
                radius: 10
                color: "#0f0b07"
                border.width: isCurrent ? 2 : 1
                border.color: isCurrent
                    ? Theme.accent
                    : (thumbArea.containsMouse ? Theme.secondary : "#0e0a06")
                clip: true
                Behavior on border.color { ColorAnimation { duration: 160 } }

                opacity: 0
                transform: Translate { id: stageTranslate; y: 12 }
                SequentialAnimation on opacity {
                    running: true
                    PauseAnimation { duration: index * 40 }
                    NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                }
                SequentialAnimation {
                    running: true
                    PauseAnimation { duration: index * 40 }
                    NumberAnimation { target: stageTranslate; property: "y"; to: 0; duration: 200; easing.type: Easing.OutCubic }
                }

                scale: thumbArea.pressed ? 0.94 : (thumbArea.containsMouse ? 1.04 : (isApplying ? 1.06 : 1.0))
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 312
                    sourceSize.height: 192
                    smooth: true
                }

                Rectangle {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 6
                    width: 8; height: 8; radius: 4
                    color: Theme.accent
                    visible: isCurrent
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22
                    color: Qt.rgba(0, 0, 0, 0.6)
                    visible: thumbArea.containsMouse

                    Text {
                        anchors.centerIn: parent
                        text: root.basename(modelData)
                        color: "#f5ede0"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                MouseArea {
                    id: thumbArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.wallpaperSelected(modelData)
                }
            }
        }
    }
}
