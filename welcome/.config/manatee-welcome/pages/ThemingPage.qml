import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

PageContainer {
    id: root
    headerTitle: "Pick a wallpaper \u2014 pick a palette"
    headerSubtitle: "Every component on the desktop themes itself from your wallpaper. " +
                    "Try one and watch this window change with it."
    stepIndex: 3
    stepCount: 5

    readonly property string wallpaperDir:
        Quickshell.env("HOME") + "/Pictures/wallpapers"

    readonly property string indexPath:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/manatee-welcome/wallpapers.json"

    property ListModel wallpapers: ListModel {}
    property string statusText: "Loading wallpapers\u2026"

    FileView {
        path: root.indexPath
        watchChanges: true
        preload: true
        onLoaded: {
            root.wallpapers.clear();
            try {
                const arr = JSON.parse(text());
                for (let i = 0; i < arr.length; i++) {
                    root.wallpapers.append({ path: String(arr[i]) });
                }
                root.statusText = root.wallpapers.count === 0
                    ? "No images in " + root.wallpaperDir
                    : "";
            } catch (e) {
                root.statusText = "Could not read wallpaper index: " + e;
            }
        }
        onLoadFailed: root.statusText = "No wallpaper index yet \u2014 run manatee-welcome to seed it."
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            visible: root.statusText.length > 0
            text: root.statusText
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: 160
            cellHeight: 110
            model: root.wallpapers
            clip: true
            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radiusControl
                    color: Theme.surfaceElev
                    border.color: hover.containsMouse ? Theme.primary : Theme.border
                    border.width: hover.containsMouse ? 2 : 1
                    clip: true
                    Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: "file://" + model.path
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        sourceSize.width: 320
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["set-wallpaper", model.path]);
                            root.statusText = "Applying " + model.path.split("/").pop() + "\u2026";
                        }
                    }
                }
            }
        }
    }
}
