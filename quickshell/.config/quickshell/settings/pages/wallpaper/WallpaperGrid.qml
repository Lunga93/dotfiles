import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string moodFilter: ""
    property var wallpapers: []
    property string applyingPath: ""

    signal wallpaperSelected(string path)

    readonly property int cellW: 156
    readonly property int cellH: 96
    readonly property int cols: Math.max(1, Math.floor((root.width - 24) / (cellW + 8)))
    readonly property var sourceWallpapers: {
        if (!root.moodFilter) return root.wallpapers;
        return MoodCatalog.wallpapersForMood(root.moodFilter) || [];
    }

    height: root.moodFilter !== "" ? (gridHeader.height + gridFlick.height + 8) : 0
    clip: true

    Process {
        id: scanner
        function scan(): void {
            const libDir = SettingsStore.get("wallpaper", "library_dir") || Quickshell.env("HOME") + "/Pictures/wallpapers";
            command = ["bash", "-c", "find '" + libDir + "' -maxdepth 3 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) 2>/dev/null | sort"];
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

    function basename(path: string): string {
        return path.split("/").pop();
    }

    Column {
        id: gridHeader
        width: parent.width
        height: childrenRect.height

        Item {
            width: parent.width
            height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.moodFilter ? root.moodFilter.charAt(0).toUpperCase() + root.moodFilter.slice(1) + " wallpapers" : ""
                color: "#6b6258"
                font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 160
                anchors.verticalCenter: parent.verticalCenter
                text: root.sourceWallpapers.length > 0 ? "(" + root.sourceWallpapers.length + ")" : ""
                color: "#5a5249"
                font.family: Theme.fontFamily; font.pixelSize: 10
            }
        }
    }

    Flickable {
        id: gridFlick
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 400
        contentWidth: parent.width
        contentHeight: innerColumn.height + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: innerColumn
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            spacing: 8
            width: parent.width - 24

            Repeater {
                model: root.sourceWallpapers

                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: 156; height: 96
                    radius: 10
                    color: "#0f0b07"
                    border.width: modelData === SettingsStore.currentWallpaper ? 2 : 1
                    border.color: modelData === SettingsStore.currentWallpaper ? Theme.accent : "#0e0a06"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 312
                        sourceSize.height: 192
                        smooth: true
                        cache: true
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        height: 20
                        color: Qt.rgba(0, 0, 0, 0.55)
                        Text {
                            anchors.centerIn: parent
                            text: root.basename(modelData)
                            color: "#f5ede0"
                            font.family: Theme.fontFamily; font.pixelSize: 9
                            elide: Text.ElideMiddle
                            width: parent.width - 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.wallpaperSelected(modelData)
                    }
                }
            }
        }
    }
}
