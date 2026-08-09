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

    height: gridHeader.height + Math.min(grid.contentHeight, 400) + 8
    clip: true

    Component.onCompleted: scanner.scan()

    Process {
        id: scanner
        function scan() {
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

    GridView {
        id: grid
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(contentHeight, 400)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 6000
        maximumFlickVelocity: 3500
        cellWidth: 152
        cellHeight: 132
        cacheBuffer: 400

        model: root.sourceWallpapers

        delegate: Rectangle {
            required property string modelData
            width: 144; height: 124
            radius: 10
            color: Theme.surfaceDeep
            border.width: modelData === SettingsStore.currentWallpaper ? 2 : 1
            border.color: modelData === SettingsStore.currentWallpaper ? Theme.accent : Theme.dividerColor
            clip: true

            Image {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 96
                source: "file://" + modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 288
                sourceSize.height: 192
                smooth: true
            }

            Text {
                anchors.left: parent.left; anchors.leftMargin: 8
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                text: root.basename(modelData)
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideMiddle
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wallpaperSelected(modelData)
            }
        }
    }
}
