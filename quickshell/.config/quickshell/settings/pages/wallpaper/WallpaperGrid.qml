import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.." // qmldir types

Item {
    id: root

    property string moodFilter: ""
    property var wallpapers: []
    property string applyingPath: ""

    signal wallpaperSelected(string path)

    readonly property int cellW: 168
    readonly property int cellH: 110
    readonly property var sourceWallpapers: {
        if (!root.moodFilter) return root.wallpapers;
        return MoodCatalog.wallpapersForMood(root.moodFilter) || [];
    }
    readonly property int rowCount: Math.max(1, Math.ceil(sourceWallpapers.length / Math.max(1, Math.floor((root.width - 24) / cellW))))

    height: root.moodFilter !== "" ? (gridHeader.height + gridFlick.height + 8) : 0
    clip: true

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

    function basename(path: string): string {
        return path.split("/").pop();
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
                anchors.left: parent.left
                anchors.leftMargin: 160
                anchors.verticalCenter: parent.verticalCenter
                text: "(" + root.sourceWallpapers.length + ")"
                color: "#5a5249"
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }

    Flickable {
        id: gridFlick
        anchors.top: gridHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(root.rowCount * root.cellH + 16, 400)
        contentWidth: parent.width
        contentHeight: flow.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Flow {
            id: flow
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            spacing: 8
            width: parent.width

            Repeater {
                model: root.sourceWallpapers

                delegate: Item {
                    required property string modelData
                    required property int index

                    width: 156
                    height: 96

                    readonly property bool isCurrent: modelData === SettingsStore.currentWallpaper

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: "#0f0b07"
                        border.width: isCurrent ? 2 : 1
                        border.color: isCurrent
                            ? Theme.accent
                            : (thumbArea.containsMouse ? Theme.secondary : "#0e0a06")
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: 160 } }

                        opacity: 0
                        SequentialAnimation on opacity {
                            running: true
                            PauseAnimation { duration: index * 30 }
                            NumberAnimation { to: 1.0; duration: 160; easing.type: Easing.OutCubic }
                        }

                        scale: thumbArea.pressed ? 0.94 : (thumbArea.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
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
    }
}
