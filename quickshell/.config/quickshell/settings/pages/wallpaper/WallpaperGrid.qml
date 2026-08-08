import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string moodFilter: ""
    property var wallpaperPaths: []
    property var wallpapers: []
    property string applyingPath: ""

    signal wallpaperSelected(string path)

    readonly property var sourceWallpapers: root.moodFilter !== "" ? root.wallpaperPaths : root.wallpapers

    height: gridFlick.y + Math.min(wallList.height + 16, 400) + 8
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
            width: parent.width; height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.moodFilter ? root.moodFilter.charAt(0).toUpperCase() + root.moodFilter.slice(1) + " wallpapers" : ""
                color: Theme.textSubtitle
                font.family: Theme.fontFamily; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.8
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 160
                anchors.verticalCenter: parent.verticalCenter
                text: root.sourceWallpapers.length > 0
                    ? "(" + root.sourceWallpapers.length + ")"
                    : "EMPTY! mood:" + root.moodFilter + " scanned:" + root.wallpapers.length
                color: root.sourceWallpapers.length > 0 ? "#5a5249" : "#ff4444"
                font.family: Theme.fontFamily; font.pixelSize: 10
            }
        }
    }

    Flickable {
        id: gridFlick
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(wallList.height + 16, 400)
        contentWidth: parent.width
        contentHeight: wallList.height + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: wallList
            anchors.left: parent.left
            anchors.leftMargin: 12
            width: parent.width - 24
            spacing: 8

            Repeater {
                model: root.sourceWallpapers

                delegate: Rectangle {
                    required property string modelData
                    width: parent.width - 24; height: 96
                    radius: 10
                    color: Theme.surfaceDeep
                    border.width: modelData === SettingsStore.currentWallpaper ? 2 : 1
                    border.color: modelData === SettingsStore.currentWallpaper ? Theme.accent : Theme.dividerColor
                    clip: true

                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 8

                        Image {
                            width: 156; height: 88
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 312
                            sourceSize.height: 176
                            smooth: true
                            cache: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.basename(modelData)
                            color: Theme.textHeader
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                            width: parent.width - 176
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
